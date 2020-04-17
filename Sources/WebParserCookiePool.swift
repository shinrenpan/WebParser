//
// Copyright (c) 2020 shinren.pan@gmail.com All rights reserved.
//

import Foundation
import WebKit

/// WebParser 共用的 Cookie pool
internal final class WebParserCookiePool
{
    /// Shared
    internal static let shared = WKProcessPool()
}
