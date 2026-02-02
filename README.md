# WebParser 🚀

![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Build Status](https://github.com/shinrenpan/WebParser/actions/workflows/test.yml/badge.svg)

一個基於 WebKit 離屏渲染的現代 Swift 網頁解析框架. 專為處理需要 JavaScript 執行、智慧輪詢 (Polling) 以及動態 DOM 加載的複雜網頁而設計.

[Changelog](CHANGELOG.md)

## ✨ 特色

- **Swift 6 原生支持**: 全面採用 `async/await` 架構, 並針對執行緒安全 (Concurrency Safety) 進行優化.
- **動態網頁渲染**: 內建 `WKWebView` 引擎, 支持執行自定義 JavaScript, 輕鬆應對 SPA 或加密數據網站.
- **類型安全映射 (Mapper)**:
  - `WebParserJSJSONMapper`: 直接將 JS 回傳的 JSON 轉換為 Swift `Codable` 模型.
  - `WebParserRegexMapper`: 利用自定義邏輯或正規表達式從原始數據中擷取內容.
- **智慧進度監控**: 透過 `WebParserProgressDelegate` 即時追蹤網頁載入與解析狀態機變化.
- **效能優化**: 支持阻擋多媒體資源 (Block Media), 顯著提升渲染速度並節省流量.
- **開發友善**: 支持 Swift `#"""` 語法, 讓 JavaScript 腳本維護不再受轉義字元困擾.



## 🎨 代碼風格 (Code Style)

本專案由 **Joe Pan** 發起並維護, 強制執行嚴格的格式化規範:

- **縮排**: 使用 2 個空格.
- **命名規範**: 縮寫詞全大寫 (如 `URL`, `ID`).
- **Swift 6 兼容**: 針對 Swift 6.2 語法優化, 確保 Strict Concurrency 檢查全數通過.
- **尾隨逗號**: 集合型別結尾總是添加逗號, 優化 Git Diff 體驗.

如果你提交 Pull Request, 請確保已執行過 `swiftformat .`.

## 🛠️ 安裝方式

透過 **Swift Package Manager** 加入你的專案:

```swift
dependencies: [
    .package(url: "https://github.com/shinrenpan/WebParser.git", from: "1.0.0")
]
```

## 🚀 快速上手

`WebParser` 透過不同的 `Mapper` 來決定解析邏輯, 你可以根據網頁回傳的數據類型靈活選擇。

### 1. 使用 `WebParserJSJSONMapper` (推薦)
當你的 `executionJS` 回傳的是 JavaScript 對象或陣列時, 這是最高效的方式。引擎會自動處理序列化, 你只需定義 `Codable` 模型。

```swift
// 定義模型
struct Comic: Codable {
  let title: String
  let updateDate: String
}

// 執行解析
let results = try await parser.parse(
  with: config,
  mapper: WebParserJSJSONMapper<[Comic]>()
)
print("抓取到 \(results.count) 本漫畫")
```

### 2. 使用 `WebParserRegexMapper`
當你只需要從網頁原始碼 (HTML) 中利用正規表達式或字串處理來擷取特定文字時使用。

```swift
// 假設 executionJS 回傳的是整個網頁的 document.title 或特定 HTML 區塊
let config = WebParserConfig(
  url: url,
  executionJS: "document.title"
)

let webTitle = try await parser.parse(
  with: config,
  mapper: WebParserRegexMapper<String> { data in
    let rawString = String(data: data, encoding: .utf8) ?? ""
    // 移除 JavaScript 回傳字串時可能帶有的引號
    return rawString.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
  }
)
print("網頁標題是: \(webTitle)")
```

## 🧩 進階用法

### 監聽解析狀態
讓你的 ViewModel 遵守 `WebParserProgressDelegate`:
```swift
func webParser(_ parser: WebParser, didUpdateState state: WebParserState) {
    if case .loading(let progress) = state {
        self.uiProgress = progress // 更新 SwiftUI 進度條
    }
}
```

## 🧪 測試

本專案全面導入 **Swift Testing** 框架, 確保核心邏輯與 WebKit 渲染的穩定性.

```bash
# 在終端機執行測試
swift test
```

## 🤖 協作致謝 (Co-creation)

本專案由 **Joe Pan (開發者)** 與 **Gemini 1.5 Flash (AI)** 深度協作完成.

在開發過程中, 我們共同解決了以下挑戰:
- **執行緒隔離**: 處理 `WKWebView` 在 Swift 6 嚴格檢查下的隔離問題.
- **抽象化設計**: 實作了 `WebParserMapper` 協定, 讓解析邏輯具備極佳的擴充性.

> 本專案利用 **Gemini 1.5 Flash** 的長文本推理與 Swift 6 語法理解能力, 優化了框架的併發安全架構.
> 「這不只是一段程式碼, 更是人類創意與 AI 邏輯交織的成果.」

---
Released under the MIT License by Joe Pan.
