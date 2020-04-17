//
// Copyright (c) 2020 shinren.pan@gmail.com All rights reserved.
//

import Foundation

/// 爬蟲設置
public protocol WebParserConfiguration
{
    /// 要爬取的網頁 URL
    var url: URL { get }

    /// 重試最大次數
    var maxRetryCount: Int { get }

    /// 每次重試的間隔時間
    var retryDelay: TimeInterval { get }

    /// 爬取 timeout
    var timeout: TimeInterval { get }

    /// 爬取瀏覽器
    var browser: Browser { get }

    /// 爬取的 JavaScript
    var javascript: String { get }
}
