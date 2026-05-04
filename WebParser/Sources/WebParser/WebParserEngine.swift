//
//  WebParserEngine.swift
//  WebParser
//
//  Created by Joe Pan on 2026/02/02.
//

import WebKit

/// 負責處理 WKWebView 離屏渲染與 JavaScript 輪詢的底層引擎.
///
/// 此類別由 ``WebParser`` 內部建立與管理, 不對外公開.
/// 每次解析任務建立一個獨立的實例, 確保 WKWebView 狀態乾淨, 不受前次解析影響.
@MainActor
final class WebParserEngine: NSObject {
  // MARK: - Properties

  /// 解析配置, 由 WebParser 在建立時直接注入, 取代原本透過 parser 間接存取的設計
  private let config: WebParserConfig

  /// 狀態變更回呼, 由 WebParser 傳入並轉發給 delegate, 解除 Engine 對 WebParser 的直接依賴
  private let onStateChange: (WebParserState) -> Void

  /// 離屏渲染的 WKWebView 實例
  private var webView: WKWebView?

  /// 銜接 WKNavigationDelegate 回呼與 Swift Concurrency 的續體
  /// 存取前必須確認非 nil, resume 後立即設為 nil 以防止 double resume
  private var continuation: CheckedContinuation<Data, Error>?

  /// 輪詢任務的引用, 保存此引用才能在 cleanup 時強制取消, 避免逾時前持續佔用資源
  private var pollingTask: Task<Void, Never>?

  /// 監聽 WKWebView 載入進度的 KVO 觀察者
  private var observation: NSKeyValueObservation?

  // MARK: - Init

  init(config: WebParserConfig, onStateChange: @escaping (WebParserState) -> Void) {
    self.config = config
    self.onStateChange = onStateChange
  }

  // MARK: - Fetch

  /// 執行網頁擷取並回傳 JavaScript 執行後序列化的原始資料.
  /// - Returns: JavaScript 結果序列化後的 `Data`.
  /// - Throws: 網頁載入失敗拋出 `URLError` 或 `WKError`, 任務取消拋出 `CancellationError`.
  func fetch() async throws -> Data {
    let wv = buildWebView()
    self.webView = wv

    let timeoutInterval = TimeInterval(config.timeout.components.seconds)
    wv.load(URLRequest(url: config.url, timeoutInterval: timeoutInterval))

    // withTaskCancellationHandler 確保外部 Task.cancel() 能立即中斷等待中的 continuation,
    // 而不是等到輪詢逾時才結束, 避免不必要的 WKWebView 資源佔用
    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { self.continuation = $0 }
    } onCancel: {
      // onCancel 可能在非 MainActor 的執行緒觸發, 切回 MainActor 確保安全存取屬性
      Task { @MainActor [weak self] in
        self?.resumeWith(.failure(CancellationError()))
      }
    }
  }

  // MARK: - Private Setup

  /// 根據 config 建立並配置 WKWebView, 套用所有效能與安全性設定
  private func buildWebView() -> WKWebView {
    let webConfig = WKWebViewConfiguration()
    webConfig.websiteDataStore = WebParserSession.shared.dataStore

    if config.blockMedia {
      // 強制所有媒體類型需使用者手動觸發才播放, 等效於阻擋自動載入媒體
      webConfig.mediaTypesRequiringUserActionForPlayback = .all
    }

    let wv = WKWebView(
      frame: CGRect(origin: .zero, size: config.windowSize),
      configuration: webConfig,
    )
    wv.navigationDelegate = self
    wv.customUserAgent = config.userAgent.value

    if #available(iOS 16.4, *) {
      wv.isInspectable = config.isInspectable
    }

    // 透過 KVO 監聽載入進度, 轉換為 .loading 狀態通知代理
    // WKWebView 的 estimatedProgress KVO 保證在 MainActor 上觸發, 使用 assumeIsolated 直接呼叫
    observation = wv.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
      guard let progress = change.newValue else {
        return
      }

      MainActor.assumeIsolated {
        self?.onStateChange(.loading(progress: progress))
      }
    }

    return wv
  }

  // MARK: - Continuation Helpers

  /// 線程安全的 Continuation 恢復輔助方法.
  /// 呼叫後立即將 continuation 設為 nil, 防止後續重複 resume 造成 crash.
  private func resumeWith(_ result: Result<Data, Error>) {
    guard let continuation else {
      return
    }

    // 先清空再 resume, 確保即使有競爭條件也只會執行一次
    self.continuation = nil
    cleanup()

    switch result {
    case let .success(data): continuation.resume(returning: data)
    case let .failure(error): continuation.resume(throwing: error)
    }
  }

  // MARK: - Cleanup

  /// 釋放所有資源, 包含強制取消輪詢任務, 防止逾時前持續佔用記憶體
  private func cleanup() {
    pollingTask?.cancel()
    pollingTask = nil
    observation?.invalidate()
    observation = nil
    webView?.navigationDelegate = nil
    webView = nil
  }
}

// MARK: - WKNavigationDelegate

extension WebParserEngine: WKNavigationDelegate {
  /// 網頁主框架載入完成, 啟動 JavaScript 輪詢任務
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    let js = config.executionJS
    let timeout = TimeInterval(config.timeout.components.seconds)
    onStateChange(.executingJavaScript)

    // 保存任務引用以便在 cleanup() 時取消, 防止任務在背景繼續運行至逾時
    pollingTask = Task { @MainActor [weak self] in
      guard let self else {
        return
      }

      await runPollingLoop(webView: webView, js: js, timeout: timeout)
    }
  }

  /// 導航請求在開始載入前失敗 (例如 DNS 錯誤, 無效 URL)
  func webView(
    _ webView: WKWebView,
    didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error,
  ) {
    resumeWith(.failure(error))
  }

  /// 網頁在載入過程中失敗 (例如逾時, 連線中斷)
  func webView(
    _ webView: WKWebView,
    didFail navigation: WKNavigation!,
    withError error: Error,
  ) {
    resumeWith(.failure(error))
  }
}

// MARK: - Polling

extension WebParserEngine {
  /// JavaScript 輪詢迴圈. 持續執行直到取得有效結果, 逾時或被取消.
  private func runPollingLoop(webView: WKWebView, js: String, timeout: TimeInterval) async {
    let startTime = Date()

    while !Task.isCancelled, Date().timeIntervalSince(startTime) < timeout {
      do {
        let rawResult = try await webView.evaluateJavaScript(js)

        if let result = rawResult, isResultPresent(result) {
          do {
            // 將 JS 結果序列化為 Data, 作為 Sendable 安全的跨邊界傳輸格式
            let data = try JSONSerialization.data(withJSONObject: result, options: .fragmentsAllowed)
            resumeWith(.success(data))
          }
          catch {
            // 資料無法序列化, 屬致命錯誤, 重試也無法修復
            resumeWith(.failure(error))
          }
          return
        }
        // 結果為空代表 DOM 尚未就緒 (常見於 SPA 非同步渲染), 繼續輪詢
      }
      catch let wkError as WKError where isFatalJSError(wkError) {
        // JS 語法錯誤或回傳類型不支援, 屬開發者錯誤, 直接失敗以提供明確的錯誤訊息
        resumeWith(.failure(wkError))
        return
      }
      catch {
        // 其他非致命錯誤 (例如 WebView 尚在初始化), 繼續輪詢
      }

      // 每輪間隔 1 秒, 使用可取消的 sleep 確保能立即響應 Task.cancel()
      do {
        try await Task.sleep(for: .seconds(1))
      }
      catch {
        // Task 被取消, 退出輪詢
        break
      }
    }

    // 非取消原因退出代表已逾時
    guard !Task.isCancelled else {
      return
    }

    resumeWith(.failure(URLError(.timedOut)))
  }

  /// 判斷 WKError 是否為無法透過重試修復的 JavaScript 致命錯誤.
  ///
  /// - `javaScriptExceptionOccurred`: JS 執行期間拋出例外 (語法錯誤, 未定義變數等)
  /// - `javaScriptResultTypeIsUnsupported`: JS 回傳了無法序列化為 JSON 的類型 (例如 Function)
  private func isFatalJSError(_ error: WKError) -> Bool {
    error.code == .javaScriptExceptionOccurred || error.code == .javaScriptResultTypeIsUnsupported
  }

  /// 判斷 JavaScript 回傳的結果是否包含實質內容.
  /// 空字串, 空陣列, 空字典均視為「尚未就緒」, 繼續等待.
  private func isResultPresent(_ result: Any) -> Bool {
    switch result {
    case let str as String: !str.isEmpty
    case let arr as [Any]: !arr.isEmpty
    case let dict as [String: Any]: !dict.isEmpty
    default: true
    }
  }
}
