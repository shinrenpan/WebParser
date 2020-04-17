//
// Copyright (c) 2020 shinren.pan@gmail.com All rights reserved.
//

import UIKit
import Foundation

/// 爬取時的瀏覽器
public enum Browser
{
    /// iPhone
    case iPhone

    /// iPad
    case iPad

    /// macOS Safari
    case Safari

    /// Windows Edge
    case Edge

    /// macOS Chrome
    case Chrome

    /// macOS Firefox
    case Firefox
}

internal extension Browser
{
    /// User Agent
    var userAgent: String
    {
        switch self
        {
            case .iPhone:
                return "Mozilla/5.0 (iPhone; CPU iPhone OS 12_1_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"
            case .iPad:
                return "Mozilla/5.0 (iPad; CPU iPhone OS 12_1_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"
            case .Safari:
                return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Safari/605.1.15"
            case .Edge:
                return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36 Edge/16.16299"
            case .Chrome:
                return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36"
            case .Firefox:
                return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:63.0) Gecko/20100101 Firefox/63.0"
        }
    }
}

internal extension Browser
{
    /// 瀏覽器視窗 size
    var size: CGRect
    {
        switch self
        {
            case .iPhone: // iPhone X
                return .init(x: 0, y: 0, width: 375, height: 812)
            case .iPad: // iPad 9.7"
                return .init(x: 0, y: 0, width: 768, height: 1024)
            case .Safari, .Edge, .Chrome, .Firefox:
                return .init(x: 0, y: 0, width: 1920, height: 1080)
        }
    }
}
