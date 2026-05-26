//
//  WebParserSession.swift
//  WebParser
//
//  Created by Joe Pan on 2026/02/02.
//

import WebKit

/// 負責管理 WebParser 全域 WebKit 環境的單例類別.
///
/// `WebParserSession` 維護一個共用的 `WKWebsiteDataStore`, 確保不同解析任務之間
/// 的 Cookie 與快取能正確共享, 適合需要保持登入狀態的爬蟲場景.
///
/// > Important: 此類別使用 App 的預設 WebKit 資料存儲 (`.default()`), 與系統的 WKWebView 共享.
/// > 若不希望爬蟲操作影響 App 的正常 WebKit 行為 (例如嵌入式網頁瀏覽器),
/// > 請自行繼承或修改此類別以使用獨立的 `WKWebsiteDataStore`.
@MainActor
public final class WebParserSession {
  // MARK: - Shared

  /// 全域共享實例.
  public static let shared: WebParserSession = .init()

  // MARK: - Properties

  /// WebKit 資料存儲核心實例.
  /// 使用 `.default()` 與 App 的 WebKit 環境共享, 讓爬蟲能直接繼承使用者的登入狀態.
  let dataStore: WKWebsiteDataStore = .default()

  // MARK: - Init

  private init() {}

  // MARK: - Public Methods

  /// 將 App 系統 Cookie 同步至 WebKit 環境, 僅同步與指定網域相符的 Cookie.
  ///
  /// 與舊版不同, 此方法只注入與目標網域相關的 Cookie, 避免將其他 domain 的
  /// 敏感資訊 (例如 token, session ID) 洩漏至無關的 WebView 環境.
  ///
  /// - Parameter domain: 目標主機名稱 (例如 `"www.example.com"`).
  ///                     傳入 `nil` 時不執行任何同步.
  public func syncCookies(for domain: String?) async {
    guard let domain, let cookies = HTTPCookieStorage.shared.cookies else {
      return
    }

    // 篩選與目標網域匹配的 Cookie
    // Cookie.domain 可能帶有前綴點號 (如 `.example.com` 代表適用所有子網域)
    let matchedCookies = cookies.filter { isCookieMatch($0, for: domain) }

    for cookie in matchedCookies {
      await dataStore.httpCookieStore.setCookie(cookie)
    }
  }

  /// 清除 WebKit 存儲的所有資料 (Cookie, 快取, LocalStorage 等).
  ///
  /// 適用於需要全新無狀態環境的爬蟲場景, 或測試之間重置 WebKit 狀態.
  public func clearAllData() async {
    let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
    let records = await dataStore.dataRecords(ofTypes: dataTypes)
    await dataStore.removeData(ofTypes: dataTypes, for: records)
  }

  // MARK: - Private Helpers

  /// 判斷一個 Cookie 是否適用於指定的主機網域.
  ///
  /// 處理兩種 Cookie domain 格式：
  /// - `.example.com`: 適用所有子網域 (www.example.com, api.example.com)
  /// - `example.com`: 僅適用於完全匹配的網域
  private func isCookieMatch(_ cookie: HTTPCookie, for host: String) -> Bool {
    // 去掉前綴點號以便統一比對 (.example.com → example.com)
    let cookieDomain = cookie.domain.hasPrefix(".")
      ? String(cookie.domain.dropFirst())
      : cookie.domain

    // 精確匹配 (example.com == example.com)
    // 或子網域匹配 (www.example.com 的結尾符合 .example.com)
    return host == cookieDomain || host.hasSuffix("." + cookieDomain)
  }
}
