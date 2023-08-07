//
// Copyright (c) 2023 shinren.pan@gmail.com All rights reserved.
//

import CoreGraphics
import Foundation

/// 網頁爬取瀏覽器代理
public enum UserAgent {
    /// iPhone
    case iPhone
    
    /// iPad
    case iPad
    
    /// macOS Safari
    case safari
    
    /// 客製化
    /// - Parameters:
    ///   - userAgent: 客製化 User agent
    ///   - frame: 客製化視窗大小
    case custom(userAgent: String, frame: CGRect)
}

extension UserAgent {
    /// User agent
    var desc: String {
        switch self {
        case .iPhone:
            return "Mozilla/5.0 (iPhone; CPU iPhone OS 13_0_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"
        case .iPad:
            return "Mozilla/5.0 (iPad; CPU iPhone OS 13_0_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"
        case .safari:
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Safari/605.1.15"
        case let .custom(userAgent, _):
            return userAgent
        }
    }
    
    /// 視窗大小
    var frame: CGRect {
        switch self {
        case .iPhone: // iPhone X
            return .init(x: 0.0, y: 0.0, width: 375.0, height: 812.0)
        case .iPad: // iPad 10
            return .init(x: 0.0, y: 0.0, width: 820, height: 1180)
        case .safari:
            return .init(x: 0.0, y: 0.0, width: 1920.0, height: 1080.0)
        case let .custom(_, frame):
            return frame
        }
    }
}
