//
// Copyright (c) 2020 shinren.pan@gmail.com All rights reserved.
//

import WebKit

/// WKWebView delegate
internal final class WebViewDelegate<ResultType: Decodable>: NSObject, WKNavigationDelegate
{
    /// 爬蟲
    internal unowned var parser: WebParser<ResultType>

    internal init(parser: WebParser<ResultType>)
    {
        self.parser = parser
    }

    // MARK: - WKNavigationDelegate

    internal func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    )
    {
        var cookies: [HTTPCookie] = []

        // 將 Cookie 存起來
        if #available(iOS 12, *)
        {
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore

            cookieStore.getAllCookies
            { allCookies in
                cookies = allCookies
            }
        }
        else
        {
            if
                let response = navigationResponse.response as? HTTPURLResponse,
                let header = response.allHeaderFields as? [String: String],
                let url = response.url
            {
                cookies = HTTPCookie.cookies(withResponseHeaderFields: header, for: url)
            }
        }

        HTTPCookieStorage.shared.setCookies(
            cookies,
            for: navigationResponse.response.url,
            mainDocumentURL: nil
        )

        decisionHandler(.allow)
    }

    internal func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error)
    {
        switch error
        {
            case let error as URLError where error.code == .timedOut:
                parser.handleError(.timeout)
            default:
                parser.handleError(.webviewFailure)
        }
    }

    internal func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    )
    {
        switch error
        {
            case let error as URLError where error.code == .timedOut:
                parser.handleError(.timeout)
            default:
                parser.handleError(.webviewFailure)
        }
    }
}
