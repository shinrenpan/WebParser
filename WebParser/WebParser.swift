//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import WebKit

public final class WebParser<T: Decodable>
{
    public weak var delegate: WebParserDelegate?
    public var parseURL: String?
    public var javaScript: String?

    private var _retryCount = 0
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
            let userInfo = [NSLocalizedDescriptionKey: "錯誤的 URL: \(self.parseURL ?? "無 URL")"]
            let error = NSError(domain: "com.shinrenpan.WebParser", code: -900, userInfo: userInfo)
            return __failWith(error: error)
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
        _timer?.schedule(deadline: .now(), repeating: 1)
        _timer?.resume()
    }

    final func __removeTimer()
    {
        _timer?.cancel()
        _timer = nil
        _retryCount = 0
    }

    final func __evaluateJavaScript()
    {
        guard let javaScript = javaScript else
        {
            let userInfo = [NSLocalizedDescriptionKey: "未設置 JavaScript"]
            let error = NSError(domain: "com.shinrenpan.WebParser", code: -902, userInfo: userInfo)
            return __failWith(error: error)
        }

        if _timer?.isCancelled == true
        {
            return
        }

        _webView.evaluateJavaScript(javaScript)
        { result, error in

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
        guard _retryCount < 30 else
        {
            let userInfo = [NSLocalizedDescriptionKey: "Retry 達最大值: \(_retryCount)"]
            let error = NSError(domain: "com.shinrenpan.WebParser", code: -901, userInfo: userInfo)
            return __failWith(error: error)
        }

        _retryCount += 1
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
