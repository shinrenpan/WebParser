//
//  CookiePool.swift
//
//  Created by Shinren Pan on 2018/3/4.
//

import WebKit

/// WebView 共用 Cookie pool
struct CookiePool {
    @MainActor
    static let shared = WKProcessPool()
}
