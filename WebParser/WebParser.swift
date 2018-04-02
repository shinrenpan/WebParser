//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import Foundation
import WebKit

/// 利用 JavaScript 爬取網頁的爬蟲.
public final class WebParser<T: Decodable>: NSObject, WKNavigationDelegate
{
    /// Typealias for 爬取完的 Callback.
    public typealias Callback = (T?, Error?) -> Void

    /// 爬取完的 Callback.
    public var callback: Callback?

    /// 要執行的 JavaScript.
    public var javaScript: String?

    /// 要爬取的網站 URL.
    public var parseURL: String?

    /// 是否取消爬取.
    private var _cancel: Bool = false

    /// 要重試的次數.
    private var _retryTimes: Int = 0

    /// 重試的間隔.
    private var _delayTime: Double = 0.0

    /// WebView.
    private var _webView: WKWebView

    // MARK: - LifeCycle

    /// 初始化.
    ///
    /// - Parameters:
    ///   - userAgent: 要客製化的 User Agent.
    ///   - callback: 爬取完的 callback.
    public init(_ userAgent: String? = nil, callback: Callback? = nil)
    {
        self.callback = callback

        let configure: WKWebViewConfiguration = WKWebViewConfiguration()
        configure.allowsAirPlayForMediaPlayback = false
        configure.allowsInlineMediaPlayback = false
        configure.allowsPictureInPictureMediaPlayback = false

        _webView = WKWebView(frame: .zero, configuration: configure)
        _webView.customUserAgent = userAgent

        super.init()

        _webView.navigationDelegate = self
    }

    // MARK: - WKNavigationDelegate

    // 為什麼不用 Extension 隔開,
    // 因為 NSObject 泛型時, @objcMembers(@ojbc) function, 無法使用 Extension 實作
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
        // 過濾廣告?
        if navigationAction.request.url?.host == webView.url?.host
        {
            decisionHandler(.allow)
        }
        else
        {
            decisionHandler(.cancel)
        }
    }

    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationResponse: WKNavigationResponse,
                        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void)
    {
        // 過濾廣告?
        if navigationResponse.response.url?.host == webView.url?.host
        {
            decisionHandler(.allow)
        }
        else
        {
            decisionHandler(.cancel)
        }
    }

    public func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error)
    {
        if _cancel
        {
            return
        }

        callback?(nil, error)
    }

    public func webView(_: WKWebView,
                        didFailProvisionalNavigation _: WKNavigation!,
                        withError error: Error)
    {
        if _cancel
        {
            return
        }

        callback?(nil, error)
    }

    public func webView(_ webView: WKWebView, didFinish _: WKNavigation!)
    {
        guard
            let javaScript: String = javaScript
        else
        {
            return
        }

        __evaluateJavaScript(javaScript)
    }

    // MARK: - @objc Private

    // 為什麼不用 Extension 隔開,
    // 因為 NSObject 泛型時, @objcMembers(@ojbc) function, 無法使用 Extension 實作
    @objc private final func __evaluateJavaScript(_ javaScript: String)
    {
        if _retryTimes < 0
        {
            let error: Error = NSError(domain: "com.shinrenpan.WebParser",
                                       code: -901,
                                       userInfo: [NSLocalizedDescriptionKey: "Retry times maximum"])

            callback?(nil, error)

            return
        }

        _retryTimes -= 1

        let selector: Selector = #selector(__evaluateJavaScript(_:))

        _webView.evaluateJavaScript(javaScript)
        { [weak self] (result: Any?, error: Error?) in

            guard
                let `self`: WebParser = self
            else
            {
                return
            }

            if let error: Error = error
            {
                self.callback?(nil, error)

                return
            }

            if let result: Any = result
            {
                do
                {
                    NSObject.cancelPreviousPerformRequests(withTarget: self,
                                                           selector: selector,
                                                           object: nil)

                    let jsonData: Data = try JSONSerialization.data(withJSONObject: result, options: [])
                    let model: T = try JSONDecoder().decode(T.self, from: jsonData)

                    self.callback?(model, nil)
                }
                catch let error
                {
                    if self._retryTimes == 0
                    {
                        self.callback?(nil, error)

                        return
                    }

                    self.perform(selector, with: nil, afterDelay: self._delayTime)
                }
            }
            else
            {
                if self._retryTimes == 0
                {
                    let error: Error = URLError(.zeroByteResource)

                    self.callback?(nil, error)

                    return
                }

                self.perform(selector, with: nil, afterDelay: self._delayTime)
            }
        }
    }
}

// MARK: - Public

public extension WebParser
{
    /// 取消爬取.
    final func cancel()
    {
        if _cancel
        {
            return
        }

        _cancel = true

        _webView.stopLoading()
    }
}

public extension WebParser
{
    /// 開始爬取.
    ///
    /// - Parameters:
    ///   - times: 重試次數, **Default is 0**.
    ///   - delay: 重試間隔, **Default is 0.0**.
    final func parse(retry times: Int = 0, delay: Double = 0.0)
    {
        if javaScript == nil
        {
            let error: Error = NSError(domain: "com.shinrenPan.WebParser",
                                       code: -900,
                                       userInfo: [NSLocalizedDescriptionKey: "No setting javascript"])

            callback?(nil, error)

            return
        }

        guard
            let urlString: String = parseURL,
            urlString.hasPrefix("http"),
            let url: URL = URL(string: urlString)
        else
        {
            let error: Error = URLError(.badURL)

            callback?(nil, error)

            return
        }

        _retryTimes = times
        _delayTime = delay

        let request: URLRequest = URLRequest(url: url,
                                             cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                             timeoutInterval: 30.0)

        _webView.load(request)
    }
}
