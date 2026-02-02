//
//  TitleTestView.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import SwiftUI
import WebParser

/// 用於測試基礎網頁標題抓取的視圖.
///
/// 此視圖展示了如何使用 `WebParserRegexMapper` 處理非 JSON 結構的簡單字串回傳.
struct TitleTestView: View {
  /// 使用者輸入的網址字串.
  @State private var urlString = "https://www.apple.com/tw/"
  /// 顯示抓取到的結果或錯誤訊息.
  @State private var scrapedResult = ""
  /// 控制載入動畫的顯示狀態.
  @State private var isLoaderShowing = false

  var body: some View {
    NavigationStack {
      Form {
        Section("輸入網址") {
          TextField("https://...", text: $urlString)
            .keyboardType(.URL)
            .autocorrectionDisabled()
        }

        Section("操作") {
          Button(action: executeScraping) {
            if isLoaderShowing {
              ProgressView().center()
            }
            else {
              Text("開始抓取網頁標題")
                .frame(maxWidth: .infinity)
            }
          }
          .disabled(isLoaderShowing)
        }

        Section("抓取結果") {
          Text(scrapedResult.isEmpty ? "尚未有資料" : scrapedResult)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(scrapedResult.contains("錯誤") ? .red : .primary)
        }
      }
      .navigationTitle("WebParser 實測")
    }
  }

  /// 執行網頁抓取的實戰邏輯.
  @MainActor
  func executeScraping() {
    guard let url = URL(string: urlString) else {
      scrapedResult = "錯誤：無效的網址"
      return
    }

    isLoaderShowing = true
    scrapedResult = "連線中..."

    // 1. 初始化 Parser 實例
    let parser = WebParser()

    // 2. 設定 Config (透過 JS 取得頁面標題)
    let config = WebParserConfig(
      url: url,
      executionJS: "document.title",
    )

    // 3. 啟動非同步抓取任務
    Task {
      do {
        // 使用 WebParserRegexMapper 處理 Data 到 String 的轉換
        let title = try await parser.parse(
          with: config,
          mapper: WebParserRegexMapper<String> { data in
            // 將 Data 轉為 String，若編碼失敗則拋出錯誤
            guard let string = String(data: data, encoding: .utf8) else {
              throw URLError(.cannotDecodeContentData)
            }

            // 處理 JavaScript 回傳時可能夾帶的 JSON 引號
            return string.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
          },
        )
        scrapedResult = "網頁標題：\n\(title)"
      }
      catch {
        scrapedResult = "執行失敗：\n\(error.localizedDescription)"
      }
      isLoaderShowing = false
    }
  }
}

// MARK: - View Extensions

extension View {
  /// 輔助小工具：將視圖水平置中於容器內.
  func center() -> some View {
    HStack {
      Spacer()
      self
      Spacer()
    }
  }
}
