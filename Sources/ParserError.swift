//
//  ParserError.swift
//
//  Created by Shinren Pan on 2018/3/4.
//

import Foundation

/// 爬取錯誤的資訊.
///
/// 目前僅有 timeout.
public enum ParserError: Error, LocalizedError {
    /// 爬取 timeout.
    case timeout
    
    /// 錯誤描述.
    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "Time out"
        }
    }
}
