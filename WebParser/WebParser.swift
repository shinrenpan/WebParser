//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import WebKit

/// Web 爬蟲
public final class WebParser<T: Decodable>: NSObject, WKNavigationDelegate
{
    /// 開始爬取的 callback
    public var didStart: (() -> Void)?

    /// 爬取成功的 callback
    public var didSuccess: ((T) -> Void)?

    /// 爬取失敗的 callback
    public var didFail: ((WebParserError) -> Void)?

    /// 取消爬取的 callback
    public var didCancel: (() -> Void)?

    /// 爬取設置條件
    public let config: WebParserConfiguration

    /// 目前 Retry 的次數
    private var _currentRetryCount: UInt = 0

    /// WebView
    private var _webView: WKWebView?

    /// Retry 的 Timer
    private var _timer: DispatchSourceTimer?

    /// 要執行的 JavaScript
    private var _JavaScript: String?
    
    /// 初始化
    /// - Parameter config: 爬取條件
    public init(config: WebParserConfiguration)
    {
        self.config = config
    }

    // MARK: - WKNavigationDelegate

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void)
    {
        var _cookies: [HTTPCookie] = []

        // 將 Cookie 存起來
        if #available(iOS 12, *)
        {
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore

            cookieStore.getAllCookies { cookies in
               _cookies = cookies
            }
        }
        else
        {
            if
                let response = navigationResponse.response as? HTTPURLResponse,
                let header = response.allHeaderFields as? [String: String],
                let url = response.url
            {
                _cookies = HTTPCookie.cookies(withResponseHeaderFields: header, for: url)
            }
        }

        HTTPCookieStorage.shared.setCookies(
            _cookies,
            for: navigationResponse.response.url,
            mainDocumentURL: nil
        )

        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error)
    {
        switch error
        {
            case let error as URLError where error.code == .timedOut:
                __failWith(error: .timeOut)
            default:
                __failWith(error: .webviewFailure)
        }
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error)
    {
        switch error
        {
            case let error as URLError where error.code == .timedOut:
                __failWith(error: .timeOut)
            default:
                __failWith(error: .webviewFailure)
        }
    }
}

// MARK: - Public function

public extension WebParser
{
    /// 開始使用 JavaScript 爬取
    /// - Parameter JavaScript: 要執行的爬取 JavaScript
    final func parseUsing(JavaScript: String)
    {
        __removeTimer()
        __removeWebView()

        if __validateUrl(config.urlString) == false
        {
            return __failWith(error: .invalidURL)
        }

        guard let url = URL(string: config.urlString) else
        {
            return __failWith(error: .invalidURL)
        }

        didStart?()
        _JavaScript = JavaScript
        __createWebViewWith(url: url)
        __createTimer()
    }

    /// 取消爬取
    final func cancel()
    {
        __removeTimer()
        __removeWebView()
        didCancel?()
    }
}

// MARK: - Private function

private extension WebParser
{
    /// 創建 WebView
    /// - Parameter url: 要爬取的 URL
    final func __createWebViewWith(url: URL)
    {
        let configure = WKWebViewConfiguration()
        // 共用 Cookie
        configure.processPool = WebParserCookiePool.shared
        configure.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        configure.allowsAirPlayForMediaPlayback = false
        configure.allowsPictureInPictureMediaPlayback = false
        configure.allowsInlineMediaPlayback = false
        _webView = WKWebView(frame: UIScreen.main.bounds, configuration: configure)
        _webView?.customUserAgent = config.customUserAgent
        _webView?.navigationDelegate = self

        var request = URLRequest(
            url: url,
            timeoutInterval: config.timeOut
        )

        // 第一次 load request 注入 Cookie
        let cookies = __cookieString()
        request.setValue(cookies, forHTTPHeaderField: "Cookie")

        _webView?.load(request)
    }

    /// 移除 WebView
    final func __removeWebView()
    {
        _webView?.navigationDelegate = nil
        _webView?.stopLoading()
        _webView = nil
    }

    /// 創建 Timer
    final func __createTimer()
    {
        __removeTimer()

        _timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)

        _timer?.setEventHandler
        { [weak self] in
            self?.__evaluateJavaScript()
        }

        _timer?.schedule(
            deadline: .now() + config.delayTime,
            repeating: Double(config.retryCount)
        )

        _timer?.resume()
    }

    /// 移除 Timer
    final func __removeTimer()
    {
        _timer?.cancel()
        _timer = nil
        _currentRetryCount = 0
    }

    /// 執行 Javascript
    final func __evaluateJavaScript()
    {
        guard let JavaScript = _JavaScript else
        {
            return __failWith(error: .noneJavaScript)
        }

        if _timer?.isCancelled == true
        {
            return __failWith(error: .timeOut)
        }

        guard let webView = _webView else
        {
            return __failWith(error: .noneWebView)
        }

        webView.evaluateJavaScript(JavaScript)
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
                let result = try JSONDecoder().decode(T.self, from: json)
                self?.__successWith(result: result)
            }
            catch
            {
                self?.__failWith(error: .decodeFailure)
            }
        }
    }

    /// 重試
    final func __retry()
    {
        if _currentRetryCount > config.retryCount
        {
            return __failWith(error: .retryMaximum)
        }

        _currentRetryCount += 1
    }

    /// 爬取失敗
    final func __failWith(error: WebParserError)
    {
        __removeTimer()
        __removeWebView()
        didFail?(error)
    }

    /// 爬取成功
    /// - Parameter result: 爬取成功的資料
    final func __successWith(result: T)
    {
        __removeTimer()
        __removeWebView()
        didSuccess?(result)
    }

    /// 檢測是否為正確的 URL String
    /// - Parameter string: url string
    final func __validateUrl(_ string: String) -> Bool
    {
        let regEx = "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
        let urlTest = NSPredicate(format:"SELF MATCHES %@", regEx)
        let result = urlTest.evaluate(with: string)
        return result
    }
    
    /// Cookie 轉成 string
    final func __cookieString() -> String?
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

        return result;
    }
}
