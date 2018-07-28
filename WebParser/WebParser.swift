//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import Foundation
import WebKit

/// 利用 JavaScript 爬取網頁的爬蟲.
public final class WebParser<T: Decodable>: NSObject, WKNavigationDelegate
{
    /// Typealias for 爬取完的 Callback.
    public typealias Callback = (WebParser.Result) -> Void

    /// 爬取完的 Callback.
    public var callback: Callback?

    /// 要執行的 JavaScript.
    public var javaScript: String?

    /// 要爬取的網站 URL.
    public var parseURL: String?

    /// 是否取消爬取.
    private var __cancel: Bool = false

    /// 爬取的 Delay 時間.
    private var __delayTime: Double = 0.0

    /// WebView.
    private var __webView: WKWebView

    // MARK: - Init

    /// 初始化.
    ///
    /// - Parameters:
    ///   - userAgent: 要客製化的 User Agent.
    public init(_ userAgent: String? = nil)
    {
        let configure: WKWebViewConfiguration = WKWebViewConfiguration()
        configure.allowsAirPlayForMediaPlayback = false
        configure.allowsPictureInPictureMediaPlayback = false

        __webView = WKWebView(frame: .zero, configuration: configure)
        __webView.customUserAgent = userAgent
        __webView.isHidden = true

        super.init()

        __webView.navigationDelegate = self
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
        if __cancel
        {
            return
        }

        callback?(.error(error.localizedDescription))
    }

    public func webView(_: WKWebView,
                        didFailProvisionalNavigation _: WKNavigation!,
                        withError error: Error)
    {
        if __cancel
        {
            return
        }

        callback?(.error(error.localizedDescription))
    }

    public func webView(_ webView: WKWebView, didFinish _: WKNavigation!)
    {
        guard
            let javaScript: String = javaScript
        else
        {
            callback?(.error("No setting javascript"))

            return
        }

        let selector: Selector = #selector(__evaluateJavaScript(_:))
        __cancelSelector(selector)
        perform(selector, with: javaScript, afterDelay: __delayTime)
    }

    // MARK: - @objc Private

    // 為什麼不用 Extension 隔開,
    // 因為 NSObject 泛型時, @objcMembers(@ojbc) function, 無法使用 Extension 實作

    @objc private func __evaluateJavaScript(_ javaScript: String)
    {
        __webView.evaluateJavaScript(javaScript)
        { (result: Any?, error: Error?) in

            if let error_: Error = error
            {
                self.callback?(.error(error_.localizedDescription))
                return
            }

            guard
                let result_: Any = result
            else
            {
                self.callback?(.error("Can't parser \(self.parseURL ?? "無網址")"))
                return
            }

            do
            {
                let json: Data = try JSONSerialization.data(withJSONObject: result_, options: [])
                let model: T = try JSONDecoder().decode(T.self, from: json)

                self.callback?(.success(model))
            }
            catch let e
            {
                self.callback?(.error(e.localizedDescription))
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
        if __cancel
        {
            return
        }

        __cancelSelector(#selector(__evaluateJavaScript(_:)))
        __cancel = true

        __webView.stopLoading()
    }
}

public extension WebParser
{
    /// 開始爬取.
    ///
    /// - Parameters:
    ///   - delay: 爬取的 Delay 時間., **Default is 0.0**.
    ///   - timeout: Timeout 時間, **Default is 30.0**.
    final func parse(delay: Double = 0.0, timeout: TimeInterval = 30.0)
    {
        __cancelSelector(#selector(__evaluateJavaScript(_:)))

        guard
            let _: String = javaScript
        else
        {
            callback?(.error("No setting javascript"))
            return
        }

        guard
            let urlString: String = parseURL,
            urlString.hasPrefix("http"),
            let url: URL = URL(string: urlString)
        else
        {
            callback?(.error("Bad URL: \(parseURL ?? "沒有網址")"))
            return
        }

        __delayTime = delay

        let request: URLRequest = URLRequest(url: url,
                                             cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                             timeoutInterval: timeout)

        __webView.load(request)
    }
}

public extension WebParser
{
    enum Result
    {
        case success(T)
        case error(String)
    }
}

private extension WebParser
{
    func __cancelSelector(_ selector: Selector)
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: selector,
                                               object: nil)
    }
}
