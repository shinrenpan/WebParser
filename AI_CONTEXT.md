# 🤖 WebParser Project Context for AI

## 📌 專案定位
- **名稱**: WebParser
- **作者**: Joe Pan
- **目標**: 基於 WebKit 離屏渲染的現代 Swift 網頁解析框架, 專門處理動態 DOM 與 JavaScript 渲染.
- **核心架構**: Swift 6 Concurrency, Async/Await, 狀態機驅動 (State Machine), 模組化 Mapper.

## 🛠️ 技術棧 (2026/02)
- **語言**: Swift 6.2 (啟動 Strict Concurrency 檢查)
- **最低平台**: iOS 17.0+
- **測試框架**: Swift Testing (非舊版 XCTest)
- **UI 框架**: SwiftUI (搭配 Observation 框架)
- **格式規範**: 遵循根目錄 `.swiftformat` (縮排 2 空格, 縮寫全大寫, 結尾 Trailing Commas).



## 🧠 關鍵決策紀錄 (Memory)
1. **Actor Isolation**: `WebParserEngine` 嚴格隔離在 `@MainActor`, 因為 `WKWebView` 必須在主執行緒操作.
2. **Data-Centric Transfer**: 為了符合 `Sendable` 規範, `Engine` 抓取結果後統一序列化為 `Data` 再傳遞給 `Mapper`, 避免 Data Race.
3. **JS Handling**: 使用 `#"""` (Raw Strings) 處理 JavaScript, 保持腳本的可讀性.
4. **State Machine**: 透過 `WebParserState` 枚舉管理生命週期,取代分散的布林值標記.

## 🤝 協作規範
- **DocC 標註**: 所有 Public API 必須附帶中文 DocC 註釋, 標點符號使用英文半形包含逗點, 句點, 以及其他中文全形.
- **命名哲學**: 縮寫詞如 `URL`, `ID`, `JS`, `JSON` 必須保持全大寫.
- **程式碼組織**: 使用 `MARK: -` 進行區塊分割, 內部成員按可見性排序.

## 🚀 待辦事項 (Backlog)
- [x] 基礎架構與 Swift 6 併發優化.
- [x] 中文 DocC 文檔全面覆蓋.
- [ ] 實作並行爬取連接池 (Connection Pool).
- [ ] 增加對代理伺服器 (Proxy) 的支援.

---
*Last Updated: 2026-02-02 by Joe Pan & Gemini 1.5 Flash (AI)*
