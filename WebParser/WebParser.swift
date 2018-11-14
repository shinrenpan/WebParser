//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import WebKit

public final class WebParser<T: Decodable>: NSObject, WKNavigationDelegate
{
    public enum ParserStatus
    {
        case none
        case start
        case success(T)
        case cancel
        case error(String)
    }

    public var parseURL: String?
    public var javaScript: String?
    public var callback: ((ParserStatus) -> Void)?

    private var _retryCount = 5
    private var _webView: WKWebView

    public var customUserAgent: String?
    {
        get
        {
            return _webView.customUserAgent
        }
        set
        {
            _webView.customUserAgent = customUserAgent
        }
    }

    public private(set) var parseStatus: ParserStatus = .none
    {
        didSet
        {
            switch parseStatus
            {
                case .success, .cancel, .error:
                    _webView.stopLoading()
                    fallthrough
                default:
                    callback?(parseStatus)
            }
        }
    }

    // MARK: - Init

    public override init()
    {
        let frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        let configure: WKWebViewConfiguration = WKWebViewConfiguration()
        configure.allowsAirPlayForMediaPlayback = false
        configure.allowsPictureInPictureMediaPlayback = false
        _webView = WKWebView(frame: frame, configuration: configure)
        _webView.isHidden = true
        super.init()
        _webView.navigationDelegate = self
    }

    // MARK: - WKNavigationDelegate

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!)
    {
        __shouldRetry()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
    {
        __cancelRetry()
        __evaluateJavaScript()
    }

    public func webView(_: WKWebView, didFail navigation: WKNavigation!, withError error: Error)
    {
        parseStatus = .error(error.localizedDescription)
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    )
    {
        parseStatus = .error(error.localizedDescription)
    }

    // MARK: - Public

    public final func start()
    {
        guard let parserURL = parseURL else
        {
            return parseStatus = .error("URL is nil")
        }

        guard let url = URL(string: parserURL) else
        {
            return parseStatus = .error("URL is invalid")
        }

        guard let _ = javaScript else
        {
            return parseStatus = .error("Javascript is nil")
        }

        parseStatus = .start
        let request = URLRequest(url: url)
        _webView.load(request)
    }

    public final func restart()
    {
        parseStatus = .none
        _retryCount = 5
        start()
    }

    public final func cancel()
    {
        parseStatus = .cancel
    }

    // MARK: - Private

    @discardableResult
    private final func __shouldRetry() -> Bool
    {
        if _retryCount < 0
        {
            parseStatus = .error("Retry maximum")
            return false
        }

        if case .success = parseStatus
        {
            return false
        }

        if case .cancel = parseStatus
        {
            return false
        }

        __retry()
        return true
    }

    private final func __retry()
    {
        __cancelRetry()
        _retryCount -= 1
        perform(#selector(__evaluateJavaScript), with: nil, afterDelay: 5.0)
    }

    private final func __cancelRetry()
    {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(__evaluateJavaScript),
            object: nil
        )
    }

    @objc
    private final func __evaluateJavaScript()
    {
        guard let javaScript = javaScript else
        {
            return parseStatus = .error("Javascript is nil")
        }

        _webView.evaluateJavaScript(javaScript)
        { result, error in
            if let _ = error
            {
                self.__shouldRetry()
                return
            }

            guard let result = result else
            {
                self.__shouldRetry()
                return
            }

            do
            {
                let json: Data = try JSONSerialization.data(withJSONObject: result, options: [])
                let result = try JSONDecoder().decode(T.self, from: json)
                self.parseStatus = .success(result)
            }
            catch
            {
                self.__shouldRetry()
            }
        }
    }
}
