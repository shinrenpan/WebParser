//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import Foundation
import WebKit

/// WebParser 共用的 Cookie pool
final class WebParserCookiePool
{
    /// Shared
    static let shared = WKProcessPool()
}
