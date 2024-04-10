//
//  Parser.swift
//
//  Created by Shinren Pan on 2018/3/4.
//

import WebKit

/// 網頁爬蟲
public final class Parser {
    /// 爬取網頁專用的 WebView.
    private var webView: WKWebView?
    
    /// 是否支援 debug.
    ///
    /// 如果為 true 就可以在 Safari 裡使用開發者工具 debug, 但是每次爬取完不會移除 webView,
    ///
    /// 反之為 false 時, 無法在 Safari 使用工具 debug, 每次爬取完將移除 webView.
    ///
    /// default 為 false.
    var debug = false
    
    /// 爬取網頁的設置.
    var parserConfiguration: ParserConfiguration
    
    
    /// 初始化 Parser
    /// - Parameter parserConfiguration: 爬取網頁的設置.
    public init(parserConfiguration: ParserConfiguration) {
        self.parserConfiguration = parserConfiguration
    }
}

// MARK: - Public

public extension Parser {
    /// 開始爬取網頁.
    /// - Returns: 返回透過 javascript 爬取的資料.
    func start() async throws -> Any {
        await createWebView()
        
        let seconds = UInt64(self.parserConfiguration.retryDuration * 1_000_000_000)
        var result: Any?
        
        for _ in 1 ... self.parserConfiguration.retryCount {
            if let data = await webViewEvaluateJavaScript() {
                result = data
                break
            }
            
            try await Task.sleep(nanoseconds: seconds)
        }
        
        if debug == false {
            await removeWebView()
        }
        
        if let result {
            return result
        }
        else {
            throw ParserError.timeout
        }
    }
}

// MARK: - Private

private extension Parser {
    /// 創建 webView.
    @MainActor func createWebView() {
        removeWebView()
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webConfiguration.processPool = CookiePool.shared
        webConfiguration.allowsAirPlayForMediaPlayback = false
        webConfiguration.allowsPictureInPictureMediaPlayback = false
        webConfiguration.allowsInlineMediaPlayback = false
        
        let frame = CGRect(origin: .zero, size: parserConfiguration.windowSize)
        self.webView = .init(frame: frame, configuration: webConfiguration)
        
        if #available(iOS 16.4, *) {
            self.webView?.isInspectable = debug
        }
        
        if let customUserAgent = parserConfiguration.customUserAgent {
            self.webView?.customUserAgent = customUserAgent
        }
        
        injectCookies()
        
        self.webView?.load(parserConfiguration.request)
    }
    
    /// 移除 webView.
    @MainActor func removeWebView() {
        webView?.stopLoading()
        webView = nil
    }
    
    /// webView 執行 javascript
    /// - Returns: 返回執行 javascript 後得到的值.
    @MainActor func webViewEvaluateJavaScript() async -> Any? {
        try? await webView?.evaluateJavaScript(parserConfiguration.javascript)
    }
    
    /// 注入 cookie
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
}
