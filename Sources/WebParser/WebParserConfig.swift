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
/// 不同的 User-Agent 會讓網站回傳不同版面的 HTML 內容 (例如行動版與桌面版的差異).
public enum WebParserUserAgent {
  /// 模擬 iOS 裝置. 可選擇性指定 OS 版本 (例如 `"17.4"`), 留空使用預設值 `17_0`.
  case iOS(version: String? = nil)
  /// 完全自訂的 User-Agent 字串.
  case custom(String)

  /// 對應的 User-Agent 字串值.
  public var value: String {
    switch self {
    case let .iOS(version):
      // 將版本號中的點號換為底線以符合 UA 字串規範 (例如 17.4 → 17_4)
      let normalizedVersion = (version ?? "17_0").replacingOccurrences(of: ".", with: "_")
      return
        "Mozilla/5.0 (iPhone; CPU iPhone OS \(normalizedVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    case let .custom(value):
      return value
    }
  }
}

/// WebParser 的核心配置模型.
///
/// ## 概述
/// 集成所有影響網頁渲染與資料擷取的參數. 透過調整配置, 可模擬不同裝置環境並優化解析效能.
///
/// ### 效能建議
/// - `blockMedia` 預設為 `true`, 可阻擋影片與音訊載入, 顯著降低資料消耗並加快渲染速度.
/// - 對重度依賴 JavaScript 的 SPA, 可適度調高 `timeout`.
/// - `executionJS` 建議撰寫精確的腳本只回傳所需資料, 避免使用預設的全頁 HTML.
///
/// ### 安全性注意事項
/// - `isInspectable` 在 Debug build 預設為 `true`, Release build 預設為 `false`.
///   正式版 App 不應開啟此選項, 以防止任何人透過 Safari 遠端偵錯存取 WebView 內容.
public struct WebParserConfig {
  // MARK: - Properties

  /// 目標網頁的 URL.
  public var url: URL

  /// 模擬的瀏覽器類型標識. 預設為 iOS.
  public var userAgent: WebParserUserAgent

  /// 頁面載入完成後執行的 JavaScript 腳本.
  ///
  /// 預設回傳完整 HTML 原始碼 (`document.documentElement.outerHTML`).
  /// 推薦使用 Swift 的 `#"""..."""#` Raw String 語法, 避免跳脫字元維護問題.
  public var executionJS: String

  /// 解析失敗時的最大重試次數. 實際執行次數為 `maxRetryCount + 1`. 預設為 3.
  public var maxRetryCount: Int

  /// 兩次重試之間的等待時長. 預設為 2 秒.
  public var retryInterval: Duration

  /// 單次網頁載入的逾時限制. 同時套用於 HTTP 請求逾時與 JavaScript 輪詢總時限. 預設為 30 秒.
  public var timeout: Duration

  /// 是否在解析前自動將系統 Cookie 同步至 WebKit. 預設為 `true`.
  ///
  /// 啟用後, 框架只同步與目標網域相符的 Cookie, 不會影響其他 domain 的資料.
  public var shouldAutoInjectCookies: Bool

  /// 是否開啟 Safari 遠端開發者工具偵錯. Debug build 預設 `true`, Release build 預設 `false`.
  ///
  /// > Warning: 正式版請務必關閉, 否則任何連線到同一網路的 Mac 都能透過 Safari 檢視 WebView 內容.
  public var isInspectable: Bool

  /// 是否阻擋圖片以外的多媒體資源 (影片, 音訊) 載入. 預設為 `true`.
  public var blockMedia: Bool

  /// 離屏渲染的虛擬視窗尺寸, 影響 RWD 版面配置. 預設為 iPhone 標準尺寸 375×812.
  public var windowSize: CGSize

  // MARK: - Init

  /// 初始化網頁解析配置.
  /// - Parameters:
  ///   - url: 目標網頁 URL.
  ///   - userAgent: 模擬的瀏覽器類型. 預設為 iOS.
  ///   - executionJS: 網頁載入後執行的 JavaScript 腳本. 預設回傳完整 HTML.
  ///   - maxRetryCount: 最大重試次數. 預設為 3.
  ///   - retryInterval: 重試間隔. 預設為 2 秒.
  ///   - timeout: 逾時限制. 預設為 30 秒.
  ///   - shouldAutoInjectCookies: 是否同步系統 Cookie. 預設為 `true`.
  ///   - isInspectable: 是否開啟遠端偵錯. Debug 預設 `true`, Release 預設 `false`.
  ///   - blockMedia: 是否阻擋媒體資源. 預設為 `true`.
  ///   - windowSize: 虛擬視窗尺寸. 預設為 375×812.
  public init(
    url: URL,
    userAgent: WebParserUserAgent = .iOS(),
    executionJS: String = "document.documentElement.outerHTML",
    maxRetryCount: Int = 3,
    retryInterval: Duration = .seconds(2),
    timeout: Duration = .seconds(30),
    shouldAutoInjectCookies: Bool = true,
    isInspectable: Bool = {
      #if DEBUG
        return true
      #else
        return false
      #endif
    }(),
    blockMedia: Bool = true,
    windowSize: CGSize = .init(width: 375, height: 812),
  ) {
    self.url = url
    self.userAgent = userAgent
    self.executionJS = executionJS
    self.maxRetryCount = max(0, maxRetryCount)
    self.retryInterval = retryInterval
    self.timeout = timeout
    self.shouldAutoInjectCookies = shouldAutoInjectCookies
    self.isInspectable = isInspectable
    self.blockMedia = blockMedia
    self.windowSize = windowSize
  }
}
