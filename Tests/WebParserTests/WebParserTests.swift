//
//  WebParserTests.swift
//  WebParser
//
//  Created by Joe Pan on 2026/02/02.
//

import Foundation
import Testing
import WebKit
@testable import WebParser

@MainActor
struct WebParserTests {
  // MARK: - WebParserJSJSONMapper

  @Test("WebParserJSJSONMapper: 正確將 JSON 陣列解碼為模型")
  func testJSJSONMapperDecodesArray() throws {
    let json = #"""
    [{"id":"12345","title":"測試漫畫","cover":"https://example.com/p.jpg","note":"連載中","lastUpdate":1700000000}]
    """#
    let data = try #require(json.data(using: .utf8))
    let result = try WebParserJSJSONMapper<[MockComic]>().map(result: data)

    #expect(result.count == 1)
    #expect(result.first?.id == "12345")
    #expect(result.first?.title == "測試漫畫")
  }

  @Test("WebParserJSJSONMapper: JSON 格式錯誤時應拋出 DecodingError")
  func testJSJSONMapperThrowsOnInvalidJSON() throws {
    let data = try #require("not valid json".data(using: .utf8))
    #expect(throws: DecodingError.self) {
      try WebParserJSJSONMapper<MockComic>().map(result: data)
    }
  }

  @Test("WebParserJSJSONMapper: 欄位類型不符時應拋出 DecodingError")
  func testJSJSONMapperThrowsOnTypeMismatch() throws {
    // id 應為 String, 但給 Int 會造成解碼失敗
    let json = #"{"id":12345,"title":"測試","cover":"","note":"","lastUpdate":0}"#
    let data = try #require(json.data(using: .utf8))
    #expect(throws: DecodingError.self) {
      try WebParserJSJSONMapper<MockComic>().map(result: data)
    }
  }

  // MARK: - WebParserRegexMapper

  @Test("WebParserRegexMapper: 正確執行自訂擷取邏輯")
  func testRegexMapperExtractsString() throws {
    // 模擬 JS 回傳帶引號的字串 (JSON 格式的字串值)
    let data = try #require(#""Hello, WebParser""#.data(using: .utf8))
    let result = try WebParserRegexMapper<String> { data in
      let raw = String(data: data, encoding: .utf8) ?? ""
      return raw.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }.map(result: data)

    #expect(result == "Hello, WebParser")
  }

  @Test("WebParserRegexMapper: 擷取器拋出錯誤時應向上傳遞")
  func testRegexMapperPropagatesError() {
    let data = Data()
    #expect(throws: URLError.self) {
      try WebParserRegexMapper<String> { _ in
        throw URLError(.cannotDecodeContentData)
      }.map(result: data)
    }
  }

  @Test("WebParserRegexMapper: 支援非 Codable 的任意回傳類型")
  func testRegexMapperSupportsNonCodableType() throws {
    let data = try #require("42".data(using: .utf8))
    let result = try WebParserRegexMapper<Int> { data in
      Int(String(data: data, encoding: .utf8) ?? "0") ?? 0
    }.map(result: data)

    #expect(result == 42)
  }

  // MARK: - WebParserConfig

  @Test("WebParserConfig: 自訂視窗尺寸正確保存")
  func testConfigStoresCustomWindowSize() throws {
    let url = try #require(URL(string: "https://example.com"))
    let config = WebParserConfig(url: url, windowSize: CGSize(width: 1920, height: 1080))

    #expect(config.windowSize.width == 1920)
    #expect(config.windowSize.height == 1080)
  }

  @Test("WebParserConfig: 所有預設值符合規格")
  func testConfigDefaultValues() throws {
    let url = try #require(URL(string: "https://example.com"))
    let config = WebParserConfig(url: url)

    #expect(config.url == url)
    #expect(config.maxRetryCount == 3)
    #expect(config.timeout == .seconds(30))
    #expect(config.retryInterval == .seconds(2))
    #expect(config.blockMedia == true)
    #expect(config.shouldAutoInjectCookies == true)
    #expect(config.executionJS == "document.documentElement.outerHTML")
    // Debug build 下 isInspectable 預設為 true
    #expect(config.isInspectable == true)
  }

  @Test("WebParserConfig: 直接儲存 URL 而非 URLComponents")
  func testConfigStoresURL() throws {
    let url = try #require(URL(string: "https://example.com/path?q=1"))
    let config = WebParserConfig(url: url)

    #expect(config.url == url)
    #expect(config.url.host == "example.com")
    #expect(config.url.path == "/path")
  }

  // MARK: - WebParserUserAgent

  @Test("WebParserUserAgent.iOS: 無版本號時使用預設 17_0")
  func testUserAgentIOSDefault() {
    let ua = WebParserUserAgent.iOS()
    #expect(ua.value.contains("iPhone"))
    #expect(ua.value.contains("17_0"))
  }

  @Test("WebParserUserAgent.iOS: 版本號中的點號應替換為底線")
  func testUserAgentIOSVersionNormalization() {
    let ua = WebParserUserAgent.iOS(version: "17.4")
    #expect(ua.value.contains("17_4"))
    #expect(!ua.value.contains("17.4"))
  }

  @Test("WebParserUserAgent.custom: 完整保留自訂字串不做任何修改")
  func testUserAgentCustomPreservesString() {
    let custom = "Mozilla/5.0 Custom Agent/1.0"
    let ua = WebParserUserAgent.custom(custom)
    #expect(ua.value == custom)
  }

  // MARK: - WebParserSession

  @Test("WebParserSession: nil domain 不執行同步且不拋出錯誤")
  func testSyncCookiesNilDomain() async {
    await WebParserSession.shared.syncCookies(for: nil)
  }

  @Test("WebParserSession: clearAllData 執行後不殘留任何資料")
  func testClearAllData() async {
    await WebParserSession.shared.clearAllData()
    let records = await WebParserSession.shared.dataStore.dataRecords(
      ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
    )
    #expect(records.isEmpty)
  }

  @Test("WebParserSession: 相符網域的 Cookie 同步後可在 WebKit 查詢到")
  func testSyncCookiesMatchingDomain() async throws {
    let cookie = try #require(HTTPCookie(properties: [
      .name: "wp_test_session",
      .value: "abc123",
      .domain: "example.com",
      .path: "/",
    ]))
    HTTPCookieStorage.shared.setCookie(cookie)

    await WebParserSession.shared.syncCookies(for: "example.com")

    let synced = await WebParserSession.shared.dataStore.httpCookieStore.allCookies()
    #expect(synced.contains { $0.name == "wp_test_session" && $0.value == "abc123" })

    // 清理
    HTTPCookieStorage.shared.deleteCookie(cookie)
    await WebParserSession.shared.clearAllData()
  }

  @Test("WebParserSession: 不相符網域的 Cookie 不應同步至 WebKit")
  func testSyncCookiesNonMatchingDomain() async throws {
    let cookie = try #require(HTTPCookie(properties: [
      .name: "wp_other_session",
      .value: "xyz789",
      .domain: "other.com",
      .path: "/",
    ]))
    HTTPCookieStorage.shared.setCookie(cookie)
    await WebParserSession.shared.clearAllData()

    await WebParserSession.shared.syncCookies(for: "example.com")

    let synced = await WebParserSession.shared.dataStore.httpCookieStore.allCookies()
    #expect(!synced.contains { $0.name == "wp_other_session" })

    // 清理
    HTTPCookieStorage.shared.deleteCookie(cookie)
  }

  // MARK: - Integration Test

  @Test("整合測試: 真實網頁解析與 JavaScript 執行", .timeLimit(.minutes(1)))
  func testRealWebParsing() async throws {
    let parser = WebParser()
    let config = try WebParserConfig(
      url: #require(URL(string: "https://www.manhuagui.com/update/")),
      userAgent: .custom(
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Safari/605.1.15",
      ),
      executionJS: integrationTestJS,
      windowSize: .init(width: 1920, height: 1080),
    )

    do {
      let result = try await parser.parse(with: config, mapper: WebParserJSJSONMapper<[MockComic]>())
      #expect(!result.isEmpty)
      #expect(result.first?.title != nil)
      print("整合測試成功, 共解析 \(result.count) 筆漫畫.")
    }
    catch {
      Issue.record("整合測試失敗, 可能為網路問題或目標網站結構變動: \(error)")
    }
  }
}

// MARK: - Mock Models

private struct MockComic: Decodable, Identifiable {
  let id: String
  let title: String
  let cover: String
  let note: String
  let lastUpdate: Double
}

// MARK: - Test Assets

private let integrationTestJS = #"""
(function() {
    var results = [];
    if (typeof $ === 'undefined') return [];

    var list = $('.latest-list > ul > li');
    if (list.length === 0) return [];

    var count = list.length;
    var now = Math.floor(Date.now() / 1000);

    list.each(function() {
        var item = $(this);
        var comic = {};

        var href = item.find('a').attr('href') || "";
        var idMatch = href.match(/\/comic\/(\d+)/);
        comic.id = idMatch ? idMatch[1] : href.replace(/\//g, '');

        comic.title = item.find('a').attr('title') || item.find('dt').text().trim() || "未知漫畫";

        var img = item.find('img');
        comic.cover = img.attr('data-src') || img.attr('src') || "";

        comic.note = item.find('.tt').text().trim();

        var dateStr = item.find('em').text().trim();
        var timestamp = 0;

        if (dateStr.includes('今天')) {
            timestamp = now;
        } else if (dateStr.includes('昨天')) {
            timestamp = now - 86400;
        } else {
            var parsed = Date.parse(dateStr);
            timestamp = isNaN(parsed) ? now : Math.floor(parsed / 1000);
        }

        comic.lastUpdate = timestamp + count;
        results.push(comic);
        count--;
    });

    return results;
})();
"""#
