//
// Copyright (c) 2020 shinren.pan@gmail.com All rights reserved.
//

import Foundation

/// WebParser 的錯誤
public enum WebParserError: Error
{
    /// Retry 次數達到上限
    case retryMaximum

    /// 初始化 WebView 失敗
    case noneWebView

    /// WebView 發生錯誤
    case webviewFailure

    /// Decode 失敗
    case decodeFailure

    /// WebView timeout
    case timeout
}

extension WebParserError: LocalizedError
{
    /// 錯誤描述
    public var errorDescription: String?
    {
        switch self
        {
            case .retryMaximum:
                return "Retry 次數達到上限"
            case .noneWebView:
                return "初始化 WebView 失敗"
            case .webviewFailure:
                return "WebView 發生錯誤"
            case .decodeFailure:
                return "Decode 失敗"
            case .timeout:
                return "WebView timeout"
        }
    }
}
