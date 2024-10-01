//
//  Parser.swift
//
//  Created by Shinren Pan on 2018/3/4.
//

import WebKit

/// 網頁爬蟲
@MainActor
public final class Parser {
    /// 爬取網頁專用的 WebView.
    private var webView: WKWebView?
    
    /// 爬取網頁的設置.
    public var parserConfiguration: ParserConfiguration
    
    /// 初始化 Parser
    /// - Parameter parserConfiguration: 爬取網頁的設置.
    public init(parserConfiguration: ParserConfiguration) {
        self.parserConfiguration = parserConfiguration
    }
}

// MARK: - Public

public extension Parser {
    func result<T>(_ type: T.Type) async throws -> T where T: Decodable {
        let any = try await result()
        let data = try JSONSerialization.data(withJSONObject: any)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// 返回爬取資料.
    /// - Returns: 返回透過 javascript 爬取的資料.
    @available(*, deprecated, message: "Use result<T>")
    func result() async throws -> Any {
        createWebView()
        
        let seconds = UInt64(self.parserConfiguration.retryDuration * 1_000_000_000)
        var result: Any?
        
        for _ in 1 ... self.parserConfiguration.retryCount {
            if let data = await webViewEvaluateJavaScript() {
                result = data
                break
            }
            
            try await Task.sleep(nanoseconds: seconds)
        }
        
        if parserConfiguration.debug == false {
            removeWebView()
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
    func createWebView() {
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
            self.webView?.isInspectable = parserConfiguration.debug
        }
        
        if let customUserAgent = parserConfiguration.customUserAgent {
            self.webView?.customUserAgent = customUserAgent
        }
        
        injectCookies()
        
        self.webView?.load(parserConfiguration.request)
    }
    
    /// 移除 webView.
    func removeWebView() {
        webView?.stopLoading()
        webView = nil
    }
    
    /// webView 執行 javascript
    /// - Returns: 返回執行 javascript 後得到的值.
    func webViewEvaluateJavaScript() async -> Any? {
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
