//
//  WebParser.swift
//  WebParser
//
//  Created by Joe Pan on 2026/02/02.
//

import Foundation

/// 描述 WebParser 在執行週期中的各個狀態.
public enum WebParserState {
  /// 解析流程已啟動.
  case started
  /// 網頁載入中. progress 為 0.0 到 1.0 之間的進度值.
  case loading(progress: Double)
  /// 引擎正在執行指定的 JavaScript 腳本.
  case executingJavaScript
  /// 解析流程已順利完成.
  case completed
  /// 發生可重試的錯誤. 記錄當前嘗試次數與錯誤原因.
  case retrying(attempt: Int, error: Error)
  /// 流程失敗. 通常發生在用盡重試次數或遇到不可恢復的錯誤時.
  case failed(Error)
}

/// 用於觀察解析進度與狀態變更的代理協定.
public protocol WebParserProgressDelegate: AnyObject {
  /// 通知代理對象解析狀態已更新.
  /// - Parameters:
  ///   - parser: 發出通知的 WebParser 實例.
  ///   - state: 當前的執行狀態.
  @MainActor func webParser(_ parser: WebParser, didUpdateState state: WebParserState)
}

/// WebParser 框架的核心入口類別.
///
/// `WebParser` 提供了一個高層級介面來處理網頁爬取任務. 它利用 WebKit 的離屏渲染技術.
/// 解決了傳統爬蟲難以處理動態渲染 (JavaScript) 或單頁應用 (SPA) 的痛點.
///
/// ### 主要特性
/// - **型別安全**: 搭配 ``WebParserMapper`` 確保輸出的資料符合模型定義.
/// - **韌性設計**: 內建自動重試機制. 可處理暫時性的網路波動.
/// - **現代化並發**: 完全相容 Swift 6 的 Concurrency 檢查與 `@MainActor` 隔離.
@MainActor
public class WebParser {
  /// 接收狀態更新的代理對象.
  public weak var delegate: WebParserProgressDelegate?

  /// 當前正在使用的解析配置.
  var currentConfig: WebParserConfig?

  /// 初始化 WebParser 實例.
  /// - Parameter delegate: 可選的代理對象. 用於監聽執行狀態.
  public init(delegate: WebParserProgressDelegate? = nil) {
    self.delegate = delegate
  }

  /// 根據指定的配置與對應器執行網頁解析.
  ///
  /// 此方法協調整個爬取生命週期. 包含 Cookie 同步, 引擎執行, 重試邏輯以及資料映射.
  ///
  /// - Parameters:
  ///   - config: 定義 URL, JavaScript 腳本與重試策略的 ``WebParserConfig`` 對象.
  ///   - mapper: 用於將原始資料轉換為特定類型的 ``WebParserMapper``.
  /// - Returns: 經過映射處理後的結果 (類型為 `M.T`).
  /// - Throws: 若重試後仍失敗則拋出 `URLError`. 或拋出對應器產生的映射錯誤.
  public func parse<M: WebParserMapper>(with config: WebParserConfig, mapper: M) async throws -> M.T {
    self.currentConfig = config

    if config.shouldAutoInjectCookies {
      await WebParserSession.shared.syncSystemCookies()
    }

    for attempt in 0 ... config.maxRetryCount {
      do {
        delegate?.webParser(self, didUpdateState: .started)
        let engine = WebParserEngine(delegate: self.delegate, parser: self)

        // 取得引擎回傳的原始 Data
        let rawResult = try await engine.fetch(config)

        // 執行資料映射
        let mappedResult = try mapper.map(result: rawResult)

        delegate?.webParser(self, didUpdateState: .completed)
        return mappedResult
      }
      catch let error as URLError where shouldRetry(for: error) && attempt < config.maxRetryCount {
        delegate?.webParser(self, didUpdateState: .retrying(attempt: attempt + 1, error: error))
        try await Task.sleep(for: config.retryInterval)
      }
      catch {
        delegate?.webParser(self, didUpdateState: .failed(error))
        throw error
      }
    }
    throw URLError(.unknown)
  }

  /// 根據錯誤代碼判斷是否應該啟動重試機制.
  private func shouldRetry(for error: URLError) -> Bool {
    [.timedOut, .networkConnectionLost, .notConnectedToInternet, .zeroByteResource].contains(error.code)
  }
}
