//
// Copyright (c) 2020 shinren.pan@gmail.com All rights reserved.
//

import WebKit

/// 爬蟲
public final class WebParser<ResultType: Decodable>
{
    /// 開始爬取
    public var didStart: (() -> Void)?

    /// 已經取消爬取
    public var didCancel: (() -> Void)?

    /// 爬取成功
    public var didSuccess: ((ResultType) -> Void)?

    /// 爬取失敗
    public var didFailure: ((WebParserError) -> Void)?

    /// WebView
    private var _webView: WKWebView?

    /// 重新爬取的 timer
    private var _timer: DispatchSourceTimer?

    /// 目前重新爬取的次數
    private var _retryCount: UInt

    /// 爬取設置
    private let _configure: WebParserConfiguration

    /// _webView delegate
    private lazy var _webViewDelegate: WebViewDelegate = {
        .init(parser: self)
    }()

    public init(configure: WebParserConfiguration)
    {
        _configure = configure
        _retryCount = 0
    }
}

// MARK: - Public functions

public extension WebParser
{
    /// 開始爬取
    func start()
    {
        __removeTimer()
        __removeWebView()
        didStart?()
        __createWebView()
        __createTimer()
    }

    /// 取消爬取
    func cancel()
    {
        __removeTimer()
        __removeWebView()
        didCancel?()
    }
}

// MARK: - Handle error

internal extension WebParser
{
    /// 處理錯誤
    /// - Parameter error: 錯誤
    func handleError(_ error: WebParserError)
    {
        __removeTimer()
        __removeWebView()
        didFailure?(error)
    }

    func handleSuccess(_ result: ResultType)
    {
        __removeTimer()
        __removeWebView()
        didSuccess?(result)
    }
}

// MARK: - Create / Remove webView

private extension WebParser
{
    /// 創建 webView 並 load
    func __createWebView()
    {
        let webConfigure = WKWebViewConfiguration()
        // 共用 Cookie
        webConfigure.processPool = WebParserCookiePool.shared
        webConfigure.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        webConfigure.allowsAirPlayForMediaPlayback = false
        webConfigure.allowsPictureInPictureMediaPlayback = false
        webConfigure.allowsInlineMediaPlayback = false
        _webView = WKWebView(frame: _configure.browser.size, configuration: webConfigure)
        _webView?.customUserAgent = _configure.browser.userAgent
        _webView?.navigationDelegate = _webViewDelegate

        var request = URLRequest(
            url: _configure.url,
            timeoutInterval: _configure.timeout
        )

        // 第一次 load request 注入 Cookie
        let cookies = __makeCookies()
        request.setValue(cookies, forHTTPHeaderField: "Cookie")

        _webView?.load(request)
    }

    /// 移除 webView
    func __removeWebView()
    {
        _webView?.navigationDelegate = nil
        _webView?.stopLoading()
        _webView = nil
    }
}

// MARK: - Create / Remove timer

private extension WebParser
{
    /// 創建 timer 並執行
    func __createTimer()
    {
        __removeTimer()

        _timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)

        _timer?.setEventHandler
        { [weak self] in
            self?.__evaluateJavaScript()
        }

        _timer?.schedule(
            deadline: .now() + _configure.retryDelay,
            repeating: Double(_configure.maxRetryCount)
        )

        _timer?.resume()
    }

    /// 移除 timer
    func __removeTimer()
    {
        _timer?.cancel()
        _timer = nil
        _retryCount = 0
    }
}

// MARK: - 爬取

private extension WebParser
{
    /// 執行爬取的 javascript
    func __evaluateJavaScript()
    {
        if _timer?.isCancelled == true
        {
            return handleError(.timeout)
        }

        guard let webView = _webView else
        {
            return handleError(.noneWebView)
        }

        webView.evaluateJavaScript(_configure.javascript)
        { [weak self] result, error in
            if let _ = error
            {
                self?.__retry()
                return
            }

            guard let result = result else
            {
                self?.__retry()
                return
            }

            do
            {
                let json = try JSONSerialization.data(withJSONObject: result, options: [])
                let decode = try JSONDecoder().decode(ResultType.self, from: json)
                self?.handleSuccess(decode)
            }
            catch
            {
                self?.handleError(.decodeFailure)
            }
        }
    }

    /// 重新爬取
    func __retry()
    {
        if _retryCount > _configure.maxRetryCount
        {
            return handleError(.retryMaximum)
        }

        _retryCount += 1
    }
}

// MARK: - Make coolie

private extension WebParser
{
    /// 產生 cookie
    func __makeCookies() -> String?
    {
        let cookieStorage = HTTPCookieStorage.shared

        guard let cookies = cookieStorage.cookies else
        {
            return nil
        }

        var result = ""

        for cookie in cookies
        {
            result.append("document.cookie=\(cookie.name)=\(cookie.value);path=/")
        }

        return result
    }
}
