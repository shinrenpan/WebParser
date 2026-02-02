//
//  ComicListViewModel.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import Observation
import SwiftUI
import WebParser

/// 漫畫更新列表的業務邏輯處理類別.
///
/// 採用 iOS 17+ 的 `@Observable` 宏, 負責驅動 UI 更新並處理與 `WebParser` 的互動.
@Observable
@MainActor
class ComicListViewModel: WebParserProgressDelegate {
  /// 抓取到的漫畫更新清單.
  var comics: [ComicUpdate] = []
  /// 是否正在載入中.
  var isLoaderShowing = false
  /// 當前的加載進度 (0.0 - 1.0).
  var progress: Double = 0
  /// 錯誤訊息, 若為 nil 則表示目前無錯誤.
  var errorMessage: String?

  /// 內部的解析器實例.
  private let parser: WebParser = .init()

  /// 初始化 ViewModel 並設置代理連線.
  init() {
    parser.delegate = self
  }

  /// 發起非同步請求以獲取漫畫更新資料.
  func fetchComics() async {
    isLoaderShowing = true
    errorMessage = nil

    // 設定針對漫畫網站優化的解析配置
    let config = WebParserConfig(
      url: URL(string: "https://www.manhuagui.com/update/")!,
      userAgent: .custom("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Safari/605.1.15"),
      executionJS: comicJS,
      windowSize: .init(width: 1920, height: 1080),
    )

    do {
      // 執行解析並使用 JSJSONMapper 自動轉型為模型陣列
      let result = try await parser.parse(
        with: config,
        mapper: WebParserJSJSONMapper<[ComicUpdate]>(),
      )
      self.comics = result
      self.isLoaderShowing = false
    }
    catch {
      self.errorMessage = error.localizedDescription
      self.isLoaderShowing = false
    }
  }

  // MARK: - WebParserProgressDelegate

  /// 響應解析器的狀態更新.
  /// - Parameters:
  ///   - parser: 解析器實例.
  ///   - state: 當前的 ``WebParserState`` 狀態.
  func webParser(_ parser: WebParser, didUpdateState state: WebParserState) {
    // 透過狀態機統一處理進度與 log
    switch state {
    case let .loading(currentProgress):
      self.progress = currentProgress
    case let .failed(error):
      print("解析失敗: \(error.localizedDescription)")
    case .completed:
      print("解析任務圓滿完成")
    default:
      break
    }
  }
}

// MARK: - 模型定義

/// 描述漫畫更新資訊的資料模型.
struct ComicUpdate: Codable, Identifiable {
  /// 漫畫唯一標識碼.
  let id: String
  /// 漫畫標題.
  let title: String
  /// 封面圖片網址.
  let cover: String
  /// 更新狀態備註 (如: 載至 100 話).
  let note: String
  /// 最後更新的時間戳記.
  let lastUpdate: Double
}

// MARK: - 爬蟲腳本 (Raw String 模式)

/// 針對目標漫畫網站設計的 JavaScript 擷取腳本.
/// 利用 jQuery 語法提取清單資訊並計算精確的時間戳記.
private let comicJS = #"""
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
