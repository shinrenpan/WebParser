//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import UIKit

public final class WebParser<T: Decodable>: NSObject, UIWebViewDelegate
{
    public var didStart: (() -> Void)?
    public var didSuccess: ((T) -> Void)?
    public var didFail: ((ParseError) -> Void)?
    public var didCancel: (() -> Void)?

    public var customUserAgent: String?
    public var parseURL: String?
    public var javaScript: String?

    public var delayTime: Double = 2
    {
        didSet
        {
            if delayTime < 1
            {
                delayTime = 1
            }
        }
    }

    public var retryCount: UInt = 5
    {
        didSet
        {
            if retryCount < 1
            {
                retryCount = 1
            }
        }
    }

    private var _currentRetryCount = 0
    private var _webView: UIWebView?
    private var _timer: DispatchSourceTimer?

    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error)
    {
        __failWith(error: .webviewFailure)
    }
}

public extension WebParser
{
    enum ParseError: Error, LocalizedError
    {
        case invalidURL, noneJavaScript, retryMaximum, noneWebView, webviewFailure, decodeFailure

        public var errorDescription: String?
        {
            switch self
            {
                case .invalidURL:
                    return "無效的網址"
                case .noneJavaScript:
                    return "未設置 JavaScript"
                case .retryMaximum:
                    return "Retry 達最大值"
                case .noneWebView:
                    return "初始化 WebView 失敗"
                case .webviewFailure:
                    return "WKWebView 失敗"
                case .decodeFailure:
                    return "JSON Decode 失敗"
            }
        }
    }
}

// MARK: - Public

public extension WebParser
{
    final func start()
    {
        __removeTimer()
        __removeWebView()

        guard let parseURL = parseURL else
        {
            return __failWith(error: ParseError.invalidURL)
        }
        
        guard let url = URL(string: parseURL) else
        {
            return __failWith(error: ParseError.invalidURL)
        }

        __createWebView()

        guard let webView = _webView else
        {
            return __failWith(error: ParseError.noneWebView)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = Double(retryCount) * delayTime
        webView.loadRequest(request)
        didStart?()
        __createTimer()
    }

    final func cancel()
    {
        __removeTimer()
        __removeWebView()
        didCancel?()
    }
}

// MARK: - Timer

private extension WebParser
{
    final func __createTimer()
    {
        if let _ = _timer
        {
            __removeTimer()
        }

        _timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)

        _timer?.setEventHandler
        { [weak self] in
            self?.__evaluateJavaScript()
        }

        _timer?.schedule(deadline: .now() + delayTime, repeating: Double(retryCount))
        _timer?.resume()
    }

    final func __removeTimer()
    {
        _timer?.cancel()
        _timer = nil
        _currentRetryCount = 0
    }
}

// MARK: - WebView

private extension WebParser
{
    final func __createWebView()
    {
        if let _ = _webView
        {
            __removeWebView()
        }

        _webView = UIWebView(frame: UIScreen.main.bounds)
        _webView?.allowsInlineMediaPlayback = false
        _webView?.allowsPictureInPictureMediaPlayback = false
        
        if let customUserAgent = customUserAgent
        {
            UserDefaults.standard.register(
                defaults: ["UserAgent": customUserAgent]
            )
        }

        _webView?.delegate = self
    }

    final func __removeWebView()
    {
        _webView?.delegate = nil
        _webView?.stopLoading()
        _webView = nil
    }
}

// MARK: - Parsing

private extension WebParser
{
    final func __evaluateJavaScript()
    {
        guard let javaScript = javaScript else
        {
            return __failWith(error: ParseError.noneJavaScript)
        }

        if _timer?.isCancelled == true
        {
            return
        }

        guard let webView = _webView else
        {
            return __failWith(error: ParseError.noneWebView)
        }

        guard
            let result = webView.stringByEvaluatingJavaScript(from: javaScript),
            result.count > 0
        else
        {
            return __shouldRetry()
        }

        guard
            let data = result.data(using: .utf8),
            data.count > 0
        else
        {
            return __shouldRetry()
        }

        do
        {
            let result = try JSONDecoder().decode(T.self, from: data)
            __successWith(result: result)
        }
        catch
        {
            __failWith(error: .decodeFailure)
        }
    }

    final func __shouldRetry()
    {
        guard _currentRetryCount < retryCount else
        {
            return __failWith(error: ParseError.retryMaximum)
        }

        _currentRetryCount += 1
    }
}

// MARK: - Result

private extension WebParser
{
    final func __failWith(error: ParseError)
    {
        __removeTimer()
        __removeWebView()
        didFail?(error)
    }

    final func __successWith(result: T)
    {
        __removeTimer()
        __removeWebView()
        didSuccess?(result)
    }
}
