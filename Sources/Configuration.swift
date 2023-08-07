//
// Copyright (c) 2023 shinren.pan@gmail.com All rights reserved.
//

import Foundation

public struct Configuration {
    /// 爬取的 URI
    public let uri: String
    
    /// Retry 間隔秒數
    public let retryInterval: UInt
    
    /// Retry 次數
    public let retryCount: UInt
    
    /// 瀏覽器代理
    public let userAgent: UserAgent
    
    /// 爬取的 Javascript 語法
    public let javascript: String
    
    
    /// 初始化
    /// - Parameters:
    ///   - uri: 爬取的 URI
    ///   - retryInterval: Retry 間隔, `default = 1`
    ///   - retryCount: Retry 次數, `default = 15`
    ///   - userAgent: 瀏覽器代理
    ///   - javascript: 爬取的 Javascript 語法
    public init(
        uri: String,
        retryInterval: UInt = 1,
        retryCount: UInt = 15,
        userAgent: UserAgent = .iPhone,
        javascript: String
    ) {
        self.uri = uri
        self.retryInterval = retryInterval
        self.retryCount = retryCount
        self.userAgent = userAgent
        self.javascript = javascript
    }
}
