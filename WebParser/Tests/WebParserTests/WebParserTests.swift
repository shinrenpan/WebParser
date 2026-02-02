//
//  WebParserTests.swift
//  WebParser
//
//  Created by Joe Pan on 2026/02/02.
//

import Foundation
import Testing
@testable import WebParser

/// WebParser 框架的單元測試與整合測試集.
///
/// 此測試集利用 Swift Testing 框架驗證從基礎配置到真實網頁解析的完整流程.
@MainActor
struct WebParserTests {
  /// 測試 Mapper：驗證 JSON 資料是否能正確映射至 Swift 模型.
  ///
  /// 此為單元測試，不依賴網路環境.
  @Test("驗證 JSON 映射至 MockComic 模型")
  func testJSONMapping() throws {
    let mapper = WebParserJSJSONMapper<[MockComic]>()
    let json = #"""
    [
        {
            "id": "12345",
            "title": "測試漫畫",
            "cover": "https://example.com/p.jpg",
            "note": "連載中",
            "lastUpdate": 1700000000
        }
    ]
    """#
    let data = json.data(using: .utf8)!

    let result = try mapper.map(result: data)

    // 使用 Swift Testing 的 #expect 語法進行斷言
    #expect(result.count == 1)
    #expect(result.first?.id == "12345")
    #expect(result.first?.title == "測試漫畫")
  }

  /// 測試 Config：驗證配置物件是否正確保存自定義屬性.
  @Test("驗證 Config 的視窗大小設定")
  func testConfigWindowSize() {
    let url = URL(string: "https://google.com")!
    let customSize = CGSize(width: 500, height: 1000)
    let config = WebParserConfig(url: url, windowSize: customSize)

    #expect(config.windowSize.width == 500)
    #expect(config.windowSize.height == 1000)
  }

  /// 整合測試：驗證真實網頁爬取與 JavaScript 執行邏輯.
  ///
  /// > Warning: 此測試需要網路連線且受目標網站狀態影響.
  /// 設定了 1 分鐘的時間限制以防止 CI/CD 流程卡死.
  @Test("真實網頁解析測試", .timeLimit(.minutes(1)))
  func testRealWebsiteParsing() async throws {
    let parser = WebParser()
    let config = WebParserConfig(
      url: URL(string: "https://www.manhuagui.com/update/")!,
      userAgent: .custom("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Safari/605.1.15"),
      executionJS: js,
      windowSize: .init(width: 1920, height: 1080),
    )

    do {
      // 執行非同步解析任務
      let result = try await parser.parse(
        with: config,
        mapper: WebParserJSJSONMapper<[MockComic]>(),
      )

      #expect(!result.isEmpty)
      #expect(result.first?.title != nil)
      print("Successfully parsed \(result.count) comics.")
    }
    catch {
      // 記錄測試失敗原因
      Issue.record("解析應成功，但收到錯誤: \(error)")
    }
  }
}

// MARK: - Mock Models

/// 用於測試的虛擬漫畫模型.
private struct MockComic: Codable, Identifiable {
  let id: String
  let title: String
  let cover: String
  let note: String
  let lastUpdate: Double
}

// MARK: - Test Assets

/// 用於測試的 JavaScript 爬取腳本.
/// 針對特定漫畫網站的 HTML 結構設計，提取 ID, 標題, 封面圖與更新時間.
private let js = #"""
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
