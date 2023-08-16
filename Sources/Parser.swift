//
// Copyright (c) 2023 shinren.pan@gmail.com All rights reserved.
//

import WebKit

/// 網頁爬蟲
public final class Parser {
    /// 爬蟲設置
    public var configuration: Configuration
    
    /// WebView
    private var webView: WKWebView?
    
    /// 初始化
    /// - Parameter configuration: 爬蟲設置
    public init(configuration: Configuration) {
        self.configuration = configuration
    }
}

// MARK: - Public Functions

public extension Parser {
    /// 爬取資料
    /// - Parameter resultType: 爬取的類型
    /// - Returns: 回傳爬取資料
    func parse() async throws -> Any {
        guard let request = makeRequest() else {
            throw ParserError.invalidURI
        }
        
        await createWebView(request: request)
        
        let seconds = UInt64(configuration.retryInterval * 1_000_000_000)
        var result: Any?
        
        for _ in 1 ... configuration.retryCount {
            try await Task.sleep(nanoseconds: seconds)
            
            if let data = await webViewEvaluateJavaScript() {
                result = data
                break
            }
        }
        
        await removeWebView()
        
        if let result {
            return result
        }
        else {
            throw ParserError.timeout
        }
    }
}

// MARK: - Private Functions

private extension Parser {
    @MainActor func createWebView(request: URLRequest) {
        removeWebView()
        
        let webConfigure = WKWebViewConfiguration()
        webConfigure.mediaTypesRequiringUserActionForPlayback = []
        webConfigure.processPool = CookiePool.shared
        webConfigure.allowsAirPlayForMediaPlayback = false
        webConfigure.allowsPictureInPictureMediaPlayback = false
        webConfigure.allowsInlineMediaPlayback = false
        
        let frame = configuration.userAgent.frame
        
        webView = .init(frame: frame, configuration: webConfigure)
        webView?.customUserAgent = configuration.userAgent.desc
        
        injectCookies()
        webView?.load(request)
    }
    
    @MainActor func removeWebView() {
        webView?.stopLoading()
        webView = nil
    }
    
    func injectCookies() {
        guard let cookies = HTTPCookieStorage.shared.cookies else {
            return
        }
        
        if cookies.isEmpty {
            return
        }
        
        guard let cookieStore = webView?.configuration.websiteDataStore.httpCookieStore else {
            return
        }
        
        for cookie in cookies {
            cookieStore.setCookie(cookie, completionHandler: nil)
        }
    }
    
    func makeRequest() -> URLRequest? {
        guard let url = URL(string: configuration.uri) else {
            return nil
        }
        
        let timeoutInterval = TimeInterval(configuration.retryInterval * configuration.retryCount)
        
        return URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeoutInterval)
    }
    
    // webView?.evaluateJavaScript 需要在 main thread
    @MainActor func webViewEvaluateJavaScript() async -> Any? {
        try? await webView?.evaluateJavaScript(configuration.javascript)
    }
}
