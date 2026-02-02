//
//  WebParserSession.swift
//  Test
//
//  Created by Joe Pan on 2026/2/2.
//

import WebKit

/// 負責維護 WebParser 的全局運作環境.
///
/// ## 討論
/// `WebParserSession` 透過單例模式維護了一個全局的 `WKWebsiteDataStore`,
/// 這確保了在不同的解析任務之間, Cookie 與 快取 (Cache) 能夠被正確地管理與共享.
///
/// > Important: 由於 WebKit API 的特性, 所有的 Session 操作必須在 `@MainActor` 執行.
@MainActor
public class WebParserSession {
  /// 全局共享實例.
  public static let shared: WebParserSession = .init()

  /// WebKit 儲存資料的核心實例.
  let dataStore: WKWebsiteDataStore = .default()

  private init() {}

  /// 將 App 層級的 Cookie 同步到 WebKit 進程中.
  ///
  /// 此方法通常在發送請求前呼叫, 確保爬蟲能以使用者的登入身份訪問網頁.
  public func syncSystemCookies() async {
    guard let cookies = HTTPCookieStorage.shared.cookies else {
      return
    }

    for cookie in cookies {
      await dataStore.httpCookieStore.setCookie(cookie)
    }
  }
}
