//
//  WebParserEngine.swift
//  WebParser
//
//  Created by Joe Pan on 2026/02/02.
//

import WebKit

/// 負責處理 WKWebView 離屏渲染與 JavaScript 執行的底層引擎.
///
/// 此類別透過將 WebView 封裝在非同步任務中，實現了對動態網頁內容的擷取.
/// 它不直接向外曝露，而是由 ``WebParser`` 內部調用.
@MainActor
class WebParserEngine: NSObject, WKNavigationDelegate {
  /// 用於渲染網頁的離屏 WebView 實例.
  private var webView: WKWebView?

  /// 用於銜接 Swift Concurrency 與 Delegate 回呼的續體.
  /// 傳遞 Data 型別以確保執行緒安全並符合 Sendable 規範.
  private var continuation: CheckedContinuation<Data, Error>?

  /// 用於回傳解析進度的代理對象.
  private weak var delegate: WebParserProgressDelegate?

  /// 發起請求的解析器實例.
  private let parser: WebParser

  /// 用於監控 WKWebView 載入進度的 KVO 觀察對象.
  private var observation: NSKeyValueObservation?

  /// 初始化解析引擎.
  /// - Parameters:
  ///   - delegate: 進度追蹤代理.
  ///   - parser: 所屬的 WebParser 實例.
  init(delegate: WebParserProgressDelegate?, parser: WebParser) {
    self.delegate = delegate
    self.parser = parser
  }

  /// 執行網頁擷取任務.
  /// - Parameter config: 解析所需的各項配置參數.
  /// - Returns: JavaScript 執行後的原始資料 (Data).
  /// - Throws: `URLError` 或網頁加載過程中的相關錯誤.
  func fetch(_ config: WebParserConfig) async throws -> Data {
    guard let url = config.components.url else {
      throw URLError(.badURL)
    }

    let webConfig = WKWebViewConfiguration()
    webConfig.websiteDataStore = WebParserSession.shared.dataStore

    // 若設定阻擋媒體，則強制所有媒體類型需使用者觸發才播放，進而達到阻擋效果.
    if config.blockMedia {
      webConfig.mediaTypesRequiringUserActionForPlayback = .all
    }

    let wv = WKWebView(frame: .init(origin: .zero, size: config.windowSize), configuration: webConfig)
    wv.navigationDelegate = self
    wv.customUserAgent = config.userAgent.value

    // 支援 iOS 16.4+ 的 Safari 遠端偵錯功能.
    if #available(iOS 16.4, *) {
      wv.isInspectable = config.isInspectable
    }

    // 透過 KVO 監控載入進度並回傳給代理.
    observation = wv.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
      guard let self, let progress = change.newValue else {
        return
      }

      Task { @MainActor in
        self.delegate?.webParser(self.parser, didUpdateState: .loading(progress: progress))
      }
    }

    self.webView = wv
    let timeoutInterval = TimeInterval(config.timeout.components.seconds)
    wv.load(URLRequest(url: url, timeoutInterval: timeoutInterval))

    // 懸掛當前任務，直到網頁載入完成並回傳結果.
    return try await withCheckedThrowingContinuation { self.continuation = $0 }
  }

  // MARK: - WKNavigationDelegate

  /// 當網頁初步載入完成後觸發，開始進入 JavaScript 輪詢階段.
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    Task { @MainActor in
      guard let config = parser.currentConfig else {
        return
      }

      let startTime = Date()
      let timeoutSeconds = Double(config.timeout.components.seconds)
      let js = config.executionJS

      delegate?.webParser(parser, didUpdateState: .executingJavaScript)

      // 輪詢機制：持續執行 JS 直到取得預期資料或逾時為止.
      while Date().timeIntervalSince(startTime) < timeoutSeconds {
        do {
          // 執行自定義 JavaScript 腳本.
          let rawResult = try await webView.evaluateJavaScript(js)

          // 驗證回傳結果是否存在且有效.
          if let result = rawResult, isResultPresent(result) {
            // 將結果轉換為 Data 以便後續 Mapper 處理.
            let data = try JSONSerialization.data(withJSONObject: result, options: [.fragmentsAllowed])

            self.continuation?.resume(returning: data)
            self.cleanup()
            return
          }
        }
        catch {
          // JS 執行失敗時繼續輪詢，直到逾時.
        }
        try? await Task.sleep(for: .seconds(1))
      }

      // 若達到逾時上限仍未取得資料.
      self.continuation?.resume(throwing: URLError(.timedOut))
      self.cleanup()
    }
  }

  /// 檢查 JavaScript 回傳的結果是否包含實質內容.
  /// - Parameter result: 來自 JavaScript 的任意型別結果.
  /// - Returns: 布林值，代表結果是否有效.
  private func isResultPresent(_ result: Any?) -> Bool {
    if let str = result as? String {
      return !str.isEmpty
    }
    if let arr = result as? [Any] {
      return !arr.isEmpty
    }
    if let dict = result as? [String: Any] {
      return !dict.isEmpty
    }
    return result != nil
  }

  /// 當網頁導向過程中發生錯誤時觸發.
  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    continuation?.resume(throwing: error)
    cleanup()
  }

  /// 釋放資源與清理狀態，防止記憶體洩漏.
  private func cleanup() {
    observation?.invalidate()
    webView?.navigationDelegate = nil
    webView = nil
    continuation = nil
  }
}
