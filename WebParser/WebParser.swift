//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import WebKit

public final class WebParser<T: Decodable>
{
    public weak var delegate: WebParserDelegate?
    public var parseURL: String?
    public var javaScript: String?
    public var delayTime: Double = 2
    {
        didSet
        {
            if delayTime < 1
            {
                delayTime = 1
            }
        }
    }

    public var retryCount: UInt = 5
    {
        didSet
        {
            if retryCount < 1
            {
                retryCount = 1
            }
        }
    }

    private var _currentRetryCount = 0
    private var _webView: WKWebView
    private var _timer: DispatchSourceTimer?

    public init(
        delegate: WebParserDelegate? = nil,
        customUserAgent: String? = nil
    )
    {
        let configure = WKWebViewConfiguration()
        configure.allowsAirPlayForMediaPlayback = false
        configure.allowsPictureInPictureMediaPlayback = false
        configure.allowsInlineMediaPlayback = false
        _webView = WKWebView(frame: .zero, configuration: configure)
        _webView.customUserAgent = customUserAgent
        self.delegate = delegate
    }
}

extension WebParser
{
    enum ParseError: Error, LocalizedError
    {
        case invalidURL, noneJavaScript, retryMaximum

        var errorDescription: String?
        {
            switch self
            {
                case .invalidURL:
                    return "無效的網址"
                case .noneJavaScript:
                    return "未設置 JavaScript"
                case .retryMaximum:
                    return "Retry 達最大值"
            }
        }
    }
}

// MARK: - Public

extension WebParser
{
    public final func start()
    {
        guard
            let parseURL = parseURL,
            let url = URL(string: parseURL)
        else
        {
            return __failWith(error: ParseError.invalidURL)
        }

        let request = URLRequest(url: url)
        _webView.load(request)
        delegate?.parserDidStart(self)
        __createTimer()
    }

    public final func cancel()
    {
        __removeTimer()
        _webView.stopLoading()
        delegate?.parserDidCancel(self)
    }
}

// MARK: - Private

private extension WebParser
{
    final func __createTimer()
    {
        __removeTimer()
        _timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        _timer?.setEventHandler
        { [weak self] in
            guard let self = self else
            {
                return
            }
            self.__evaluateJavaScript()
        }
        _timer?.schedule(deadline: .now() + delayTime, repeating: Double(retryCount))
        _timer?.resume()
    }

    final func __removeTimer()
    {
        _timer?.cancel()
        _timer = nil
        _currentRetryCount = 0
    }

    final func __evaluateJavaScript()
    {
        guard let javaScript = javaScript else
        {
            return __failWith(error: ParseError.noneJavaScript)
        }

        if _timer?.isCancelled == true
        {
            return
        }

        _webView.evaluateJavaScript(javaScript)
        { [weak self] result, error in
            guard let self = self else
            {
                return
            }

            if let _ = error
            {
                return self.__shouldRetry()
            }

            guard let result = result else
            {
                return self.__shouldRetry()
            }

            do
            {
                let json: Data = try JSONSerialization.data(withJSONObject: result, options: [])
                let result = try JSONDecoder().decode(T.self, from: json)
                self.__successWith(result: result)
            }
            catch
            {
                self.__shouldRetry()
            }
        }
    }

    final func __shouldRetry()
    {
        guard _currentRetryCount < retryCount else
        {
            return __failWith(error: ParseError.retryMaximum)
        }

        _currentRetryCount += 1
    }

    final func __failWith(error: Error)
    {
        __removeTimer()
        _webView.stopLoading()
        _webView.load(URLRequest(url: URL(string: "about:blank")!))
        delegate?.parserDidFail(self, error: error)
    }

    final func __successWith(result: T)
    {
        __removeTimer()
        _webView.stopLoading()
        _webView.load(URLRequest(url: URL(string: "about:blank")!))
        delegate?.parserDidFinish(self, result: result)
    }
}
