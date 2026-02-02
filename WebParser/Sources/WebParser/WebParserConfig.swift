//
//  WebParserConfig.swift
//  WebParser
//
//  Created by Joe Pan on 2026/02/02.
//

import CoreGraphics
import Foundation

/// 定義模擬瀏覽器的行為標識 (User-Agent).
///
/// 不同的 User-Agent 會引發網站回傳不同的 HTML 結構或內容 (例如行動版與桌面版的差異).
public enum WebParserUserAgent {
  /// 模擬 iOS 裝置. 可指定 OS 版本號 (例如 "17.4").
  case iOS(version: String? = nil)
  /// 使用完全自定義的 User-Agent 字串.
  case custom(String)

  /// 取得對應的 User-Agent 字串值.
  public var value: String {
    switch self {
    case let .iOS(version):
      let os = version ?? "17_0"
      return "Mozilla/5.0 (iPhone; CPU iPhone OS \(os.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    case let .custom(val): return val
    }
  }
}

/// WebParser 的核心配置模型.
///
/// ## 概述
/// 此結構體集成了所有影響網頁渲染與資料擷取的參數. 透過調整此配置, 你可以模擬不同的裝置環境並優化解析效能.
///
/// ### 效能優化建議
/// - 將 `blockMedia` 設為 `true` 以防止載入影片或音訊檔, 這能顯著減少流量並提升載入速度.
/// - 針對重度依賴 JavaScript 的單頁應用 (SPA), 建議適度調高 `timeout` 設定.
public struct WebParserConfig {
  /// 目標網址的組成組件.
  public var components: URLComponents

  /// 模擬的瀏覽器類型標識.
  public var userAgent: WebParserUserAgent

  /// 頁面載入完成後執行的 JavaScript 腳本. 預設回傳全頁面的 HTML 原始碼.
  public var executionJS: String

  /// 當解析失敗或網路逾時時的最大重試次數.
  public var maxRetryCount: Int

  /// 兩次重試之間的等待時間.
  public var retryInterval: Duration

  /// 單次網頁加載任務的逾時限制.
  public var timeout: Duration

  /// 是否自動將 App 系統內的 Cookie 同步至網頁環境中.
  public var shouldAutoInjectCookies: Bool

  /// 是否允許使用 Safari 遠端開發者工具進行偵錯.
  public var isInspectable: Bool

  /// 是否阻擋圖片以外的多媒體資源 (如影片, 音訊) 載入.
  public var blockMedia: Bool

  /// 離屏渲染時的虛擬視窗大小. 會影響網頁的排版佈局 (RWD).
  public var windowSize: CGSize

  /// 初始化網頁解析配置.
  /// - Parameters:
  ///   - url: 目標網頁 URL.
  ///   - userAgent: 要模擬的瀏覽器類型. 預設為 iOS.
  ///   - executionJS: 網頁加載後要執行的腳本.
  ///   - maxRetryCount: 失敗時的重試次數. 預設為 3 次.
  ///   - retryInterval: 重試間隔時間. 預設為 2 秒.
  ///   - timeout: 逾時限制. 預設為 30 秒.
  ///   - shouldAutoInjectCookies: 是否同步系統 Cookie. 預設為 true.
  ///   - isInspectable: 是否開啟遠端偵錯. 預設為 true.
  ///   - blockMedia: 是否阻擋媒體資源. 預設為 true.
  ///   - windowSize: 虛擬畫布大小. 預設為 iPhone 典型的 375x812.
  public init(
    url: URL,
    userAgent: WebParserUserAgent = .iOS(),
    executionJS: String = "document.documentElement.outerHTML",
    maxRetryCount: Int = 3,
    retryInterval: Duration = .seconds(2),
    timeout: Duration = .seconds(30),
    shouldAutoInjectCookies: Bool = true,
    isInspectable: Bool = true,
    blockMedia: Bool = true,
    windowSize: CGSize = .init(width: 375, height: 812),
  ) {
    self.components = URLComponents(url: url, resolvingAgainstBaseURL: false) ?? URLComponents()
    self.userAgent = userAgent
    self.executionJS = executionJS
    self.maxRetryCount = maxRetryCount
    self.retryInterval = retryInterval
    self.timeout = timeout
    self.shouldAutoInjectCookies = shouldAutoInjectCookies
    self.isInspectable = isInspectable
    self.blockMedia = blockMedia
    self.windowSize = windowSize
  }
}
