//
//  ParserConfiguration.swift
//
//  Created by Shinren Pan on 2018/3/4.
//

import Foundation

/// 爬取網頁的設置.
public struct ParserConfiguration {
    /// 要爬取的 URL Request.
    public var request: URLRequest
    
    /// 網頁瀏覽尺寸.
    ///
    /// 有些網頁會對應不同的尺寸, 導向不同的網址, 例如小尺寸就導向 mobile web.
    ///
    /// 為了正確的爬取, 請設置正確的瀏覽尺寸.
    public var windowSize: CGSize
    
    /// 網頁瀏覽的 user agent.
    ///
    /// 有些網頁除了看尺寸大小, 還會看瀏覽器的 user agent, 導向不同網址,
    ///
    /// 為了正確的爬取, 請設置正確的 user agent.
    public var customUserAgent: String?
    
    /// 重試次數.
    ///
    /// 最後 timeout 時間為 retryCount * retryDuration.
    public var retryCount: UInt
    
    /// 重試的間隔秒數.
    ///
    /// 最後 timeout 時間為 retryCount * retryDuration.
    public var retryDuration: UInt
    
    /// 要執行的 javascript.
    public var javascript: String
    
    /// 是否支援 debug.
    ///
    /// 如果為 true 就可以在 Safari 裡使用開發者工具 debug, 但是每次爬取完不會移除 webView,
    ///
    /// 反之為 false 時, 無法在 Safari 使用工具 debug, 每次爬取完將移除 webView.
    ///
    /// default 為 false.
    public var debug = false
    
    /// 初始化爬取設置
    /// - Parameters:
    ///   - request: 要爬取的 URL Request.
    ///   - windowSize: 網頁瀏覽尺寸.
    ///   - customUserAgent: 網頁瀏覽的 user agent.
    ///   - retryCount: 重試次數.
    ///   - retryDuration: 重試的間隔秒數.
    ///   - javascript: 要執行的 javascript.
    public init(request: URLRequest, windowSize: CGSize, customUserAgent: String?, retryCount: UInt, retryDuration: UInt, javascript: String) {
        self.request = request
        self.windowSize = windowSize
        self.customUserAgent = customUserAgent
        self.retryCount = retryCount
        self.retryDuration = retryDuration
        self.javascript = javascript
    }
}
