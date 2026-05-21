# WebParser 🚀

![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Build Status](https://github.com/shinrenpan/WebParser/actions/workflows/test.yml/badge.svg)

一個基於 WebKit 離屏渲染的現代 Swift 網頁解析框架. 專為處理需要 JavaScript 執行、智慧輪詢 (Polling) 以及動態 DOM 加載的複雜網頁而設計.

## ✨ 特色

- **Swift 6 原生支持**: 全面採用 `async/await` 架構, 並針對執行緒安全 (Concurrency Safety) 進行優化.
- **動態網頁渲染**: 內建 `WKWebView` 引擎, 支持執行自定義 JavaScript, 輕鬆應對 SPA 或加密數據網站.
- **類型安全映射 (Mapper)**:
  - `WebParserJSJSONMapper`: 直接將 JS 回傳的 JSON 轉換為 Swift `Decodable` 模型.
  - `WebParserRegexMapper`: 透過自訂閉包從原始數據中擷取任意型別的內容, 不限於 `Codable`.
- **智慧進度監控**: 透過 `WebParserProgressDelegate` 即時追蹤網頁載入與解析狀態機變化.
- **效能優化**: 支持阻擋多媒體資源 (Block Media), 顯著提升渲染速度並節省流量.
- **開發友善**: 支持 Swift `#"""` 語法, 讓 JavaScript 腳本維護不再受轉義字元困擾.

## 🗂️ Demo 專案設定

Demo 專案使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 管理, `xcodeproj` 不納入版控.

```bash
brew install xcodegen
cd WebParserDemo && xcodegen generate
```

完成後以 `WebParser.xcworkspace` 開啟.

## 🛠️ 安裝方式

透過 **Swift Package Manager** 加入你的專案:

```swift
dependencies: [
    .package(url: "https://github.com/shinrenpan/WebParser.git", from: "1.0.0")
]
```

## 🚀 快速上手

`WebParser` 透過不同的 `Mapper` 來決定解析邏輯, 你可以根據網頁回傳的數據類型靈活選擇.

### 1. 使用 `WebParserJSJSONMapper` (推薦)

當你的 `executionJS` 回傳的是 JavaScript 對象或陣列時, 這是最高效的方式. 引擎會自動處理序列化, 你只需定義 `Decodable` 模型.

```swift
// 定義模型
struct Comic: Decodable {
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

當你需要從回傳的原始字串中利用自定義邏輯擷取特定內容時使用.

```swift
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
  if case let .loading(progress) = state {
    self.uiProgress = progress
  }
}
```

## 🎨 程式碼風格

- **縮排**: 使用 2 個空格.
- **命名規範**: 縮寫詞全大寫 (如 `URL`, `ID`, `JS`, `JSON`).
- **Swift 6 兼容**: 針對 Swift 6.2 語法優化, 確保 Strict Concurrency 檢查全數通過.
- **尾隨逗號**: 集合型別結尾總是添加逗號, 優化 Git Diff 體驗.

如果你提交 Pull Request, 請確保已執行過 `swiftformat .`.

## 🧪 測試

本專案全面導入 **Swift Testing** 框架, 確保核心邏輯與 WebKit 渲染的穩定性.

```bash
cd WebParser && swift test --parallel
```

---

Released under the MIT License by Joe Pan.
