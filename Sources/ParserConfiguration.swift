//
//  ParserConfiguration.swift
//
//  Created by Shinren Pan on 2018/3/4.
//

import Foundation

/// 爬取網頁的設置.
public struct ParserConfiguration {
    /// 要爬取的 URL Request.
    public let request: URLRequest
    
    /// 網頁瀏覽尺寸.
    ///
    /// 有些網頁會對應不同的尺寸, 導向不同的網址, 例如小尺寸就導向 mobile web.
    ///
    /// 為了正確的爬取, 請設置正確的瀏覽尺寸.
    public let windowSize: CGSize
    
    /// 網頁瀏覽的 user agent.
    ///
    /// 有些網頁除了看尺寸大小, 還會看瀏覽器的 user agent, 導向不同網址,
    ///
    /// 為了正確的爬取, 請設置正確的 user agent.
    public let customUserAgent: String?
    
    /// 重試次數.
    ///
    /// 最後 timeout 時間為 retryCount * retryDuration.
    public let retryCount: UInt
    
    /// 重試的間隔秒數.
    ///
    /// 最後 timeout 時間為 retryCount * retryDuration.
    public let retryDuration: UInt
    
    /// 要執行的 javascript.
    public let javascript: String
    
    
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
