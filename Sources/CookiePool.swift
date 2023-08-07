//
// Copyright (c) 2023 shinren.pan@gmail.com All rights reserved.
//

import WebKit

/// WebView 共用 Cookie pool
struct CookiePool {
    static let shared = WKProcessPool()
}
