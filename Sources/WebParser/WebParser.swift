//
//  WebParser.swift
//  WebParser
//
//  Created by Joe Pan on 2026/02/02.
//

import Foundation

/// 描述 WebParser 在執行週期中的各個狀態.
public enum WebParserState {
  /// 解析流程已啟動, 此狀態在整個解析週期內只會發出一次.
  case started
  /// 網頁載入中. `progress` 為 0.0 到 1.0 之間的進度值.
  case loading(progress: Double)
  /// 引擎正在執行指定的 JavaScript 腳本.
  case executingJavaScript
  /// 解析流程已順利完成.
  case completed
  /// 發生可重試的網路錯誤. `attempt` 為目前的重試次數, `error` 為錯誤原因.
  case retrying(attempt: Int, error: Error)
  /// 流程失敗. 發生在用盡所有重試次數, 遇到不可恢復的錯誤, 或任務被取消時.
  case failed(Error)
}

/// 用於觀察解析進度與狀態變更的代理協定.
public protocol WebParserProgressDelegate: AnyObject {
  /// 通知代理對象解析狀態已更新.
  /// - Parameters:
  ///   - parser: 發出通知的 ``WebParser`` 實例.
  ///   - state: 當前的執行狀態.
  @MainActor func webParser(_ parser: WebParser, didUpdateState state: WebParserState)
}

/// WebParser 框架的核心入口類別.
///
/// `WebParser` 提供高層級介面來執行網頁解析任務. 內部透過 WebKit 離屏渲染執行 JavaScript,
/// 能處理 SPA 動態渲染或需要 Cookie 登入的複雜網站.
///
/// ### 基礎用法
/// ```swift
/// let parser = WebParser()
/// let config = WebParserConfig(url: url, executionJS: "document.title")
/// let title = try await parser.parse(
///   with: config,
///   mapper: WebParserRegexMapper<String> { data in
///     String(data: data, encoding: .utf8) ?? ""
///   }
/// )
/// ```
///
/// ### 取消任務
/// 此方法完整支援 Swift Structured Concurrency 的取消機制.
/// 對包裝此呼叫的 `Task` 呼叫 `.cancel()`, 解析會立即中斷並拋出 `CancellationError`.
/// ```swift
/// let task = Task { try await parser.parse(with: config, mapper: mapper) }
/// task.cancel() // 立即中斷, 釋放 WKWebView 資源
/// ```
@MainActor
public final class WebParser {
  // MARK: - Public

  /// 接收狀態更新的代理對象.
  public weak var delegate: WebParserProgressDelegate?

  /// 初始化 WebParser 實例.
  /// - Parameter delegate: 可選的代理對象, 用於監聽執行狀態.
  public init(delegate: WebParserProgressDelegate? = nil) {
    self.delegate = delegate
  }

  /// 根據指定的配置與對應器執行網頁解析.
  ///
  /// 此方法協調整個解析生命週期：Cookie 同步, 引擎執行, 自動重試以及資料映射.
  ///
  /// 狀態轉換順序：`.started` → `.loading` → `.executingJavaScript`
  /// → `.completed` 或 → `.retrying` (可重試錯誤) → `.failed` (最終失敗).
  ///
  /// - Parameters:
  ///   - config: 定義目標 URL, JavaScript 腳本與重試策略的 ``WebParserConfig``.
  ///   - mapper: 負責將原始資料轉換為指定模型的 ``WebParserMapper``.
  /// - Returns: 經 Mapper 處理後的結果, 類型為 `M.T`.
  /// - Throws: 解析失敗時拋出 `URLError`, 映射失敗時拋出對應器產生的錯誤,
  ///           任務取消時拋出 `CancellationError`.
  public func parse<M: WebParserMapper>(with config: WebParserConfig, mapper: M) async throws -> M.T {
    if config.shouldAutoInjectCookies {
      // 只同步與目標網域相關的 Cookie, 避免洩漏其他 domain 的敏感資訊
      await WebParserSession.shared.syncCookies(for: config.url.host(percentEncoded: false))
    }

    // .started 在整個解析週期只發出一次, 重試期間不重複發出
    notify(.started)

    var lastError: Error = URLError(.unknown)

    for attempt in 0 ... config.maxRetryCount {
      do {
        // 每次嘗試建立獨立的 Engine 實例, 確保 WKWebView 狀態乾淨
        let engine = WebParserEngine(config: config) { [weak self] state in
          self?.notify(state)
        }

        let rawData = try await engine.fetch()
        let result = try mapper.map(result: rawData)
        notify(.completed)
        return result
      }
      catch is CancellationError {
        // 任務取消不屬於應用層錯誤, 直接重新拋出, 不通知 delegate
        throw CancellationError()
      }
      catch let urlError as URLError where shouldRetry(urlError) {
        // 暫時性網路錯誤: 記錄最後一次失敗, 若已是最後一次嘗試則跳出迴圈
        lastError = urlError
        guard attempt < config.maxRetryCount else {
          break
        }

        notify(.retrying(attempt: attempt + 1, error: urlError))
        try await Task.sleep(for: config.retryInterval)
      }
      catch {
        // 其他不可恢復的錯誤, 通知代理後直接拋出
        notify(.failed(error))
        throw error
      }
    }

    // 可重試錯誤用盡所有次數後到達此處
    notify(.failed(lastError))
    throw lastError
  }

  // MARK: - Private

  private func notify(_ state: WebParserState) {
    delegate?.webParser(self, didUpdateState: state)
  }

  /// 判斷錯誤是否為值得重試的暫時性網路問題.
  /// 邏輯錯誤, 伺服器錯誤或 JS 錯誤均不應重試.
  private func shouldRetry(_ error: URLError) -> Bool {
    [.timedOut, .networkConnectionLost, .notConnectedToInternet, .zeroByteResource]
      .contains(error.code)
  }
}
