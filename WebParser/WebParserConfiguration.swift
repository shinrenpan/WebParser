//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import Foundation

/// WebParser 的設置
public struct WebParserConfiguration
{
    /// 每個 Retry 的間隔
    public let delayTime: TimeInterval

    /// Retry 的次數
    public let retryCount: UInt

    /// 爬取的 timeout 時間, 為 delayTime * delayTime
    public let timeOut: TimeInterval

    /// 自定義 User-Agent
    public let customUserAgent: String?

    /// 要爬取的 URL String
    public let urlString: String

    /// 初始化
    /// - Parameter delayTime: 每個 Retry 的間隔, Default = 2.0
    /// - Parameter retryCount: Retry 的次數, Default = 5
    /// - Parameter customUserAgent: 自定義 User-Agent, Default = nil
    /// - Parameter urlString: 要爬取的 URL String
    public init(
        delayTime: TimeInterval = 2.0,
        retryCount: UInt = 5,
        customUserAgent: String? = nil,
        urlString: String
    )
    {
        self.delayTime = delayTime
        self.retryCount = retryCount
        self.timeOut = delayTime * Double(retryCount)
        self.customUserAgent = customUserAgent
        self.urlString = urlString
    }
}



