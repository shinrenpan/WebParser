//
// Copyright (c) 2023 shinren.pan@gmail.com All rights reserved.
//

import Foundation

/// 爬取錯誤類型
public enum ParserError: Error {
    /// 錯誤的 URL
    case invalidURI
    
    /// Time out
    case timeout
}

extension ParserError: LocalizedError {
    /// 錯誤描述
    public var errorDescription: String? {
        switch self {
        case .invalidURI:
            return "無效的 URI"
        case .timeout:
            return "Time out"
        }
    }
}
