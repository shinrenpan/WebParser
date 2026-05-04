# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 常用指令

```bash
# 執行所有測試（必須先進入 WebParser/ 子目錄）
cd WebParser && swift test --parallel

# 執行單一測試
cd WebParser && swift test --filter "testJSONMapping"

# 提交前格式化程式碼
swiftformat .
```

CI 從 `WebParser/` 子目錄執行 `swift test --parallel`（見 `.github/workflows/test.yml`），本地執行時務必先 `cd WebParser`。

## 架構

專案包含兩個頂層目錄：

- **`WebParser/`** — Swift Package（函式庫本體），所有 Public API 位於此處。
- **`WebParserDemo/`** — Xcode App 專案，示範如何使用函式庫。

### 函式庫內部結構（`WebParser/Sources/WebParser/`）

解析流程由四個組件依序串接：

```
WebParser（入口）
  → WebParserSession（Cookie / 資料存儲單例）
  → WebParserEngine（WKWebView 離屏渲染引擎）
  → WebParserMapper（資料轉換器）
```

**`WebParser`**（`@MainActor class`）— 協調完整生命週期：Cookie 同步 → Engine 執行 → 重試迴圈 → Mapper 映射。呼叫端提供 `WebParserConfig` 與任意 `WebParserMapper`，回傳類型為泛型 `M.T`。

**`WebParserEngine`**（`@MainActor class`）— 將 `WKWebView` 包裝在 `CheckedContinuation<Data, Error>` 中。頁面載入完成後進入輪詢迴圈，持續呼叫 `evaluateJavaScript` 直到結果非空或逾時。結果透過 `JSONSerialization` 序列化為 `Data` 再回傳，這是維持 `Sendable` 合規的關鍵橋接點。

**`WebParserMapper`**（protocol）— 負責 `Data → T` 的轉換，內建兩個實作：
- `WebParserJSJSONMapper<T: Decodable>` — 使用 `JSONDecoder` 解碼。適用於 `executionJS` 回傳 JS 物件或陣列的情境。
- `WebParserRegexMapper<T>` — 將轉換邏輯委派給呼叫端提供的 `(Data) throws -> T` 閉包，回傳型別不限 `Codable`。適用於 `executionJS` 回傳純文字（如 `document.title` 或完整 HTML）的情境。

**`WebParserSession`**（`@MainActor` 單例）— 持有共用的 `WKWebsiteDataStore`，確保 Cookie 與快取在不同解析任務之間正確共享。

**`WebParserState`**（enum）— 狀態機，透過 `WebParserProgressDelegate` 發送：`started → loading(progress:) → executingJavaScript → completed | retrying | failed`。

### Demo App 結構（`WebParserDemo/WebParserDemo/`）

Demo 採用 UIKit SceneDelegate 架構，目錄分為三組：

- **`App/`** — `AppDelegate`（`@main`）、`SceneDelegate`（建立 `UITabBarController` + 兩個 `UINavigationController`）、`ViewModel` protocol 定義。
- **`TitleTest/`** — 輸入 URL 抓取網頁標題的功能，使用 `WebParserRegexMapper`。
- **`ComicList/`** — 解析漫畫更新列表的功能，使用 `WebParserJSJSONMapper` 搭配 `WebParserProgressDelegate` 顯示載入進度。

每個 Feature 遵循 `HostController → ViewModel → View` 三層架構，ViewModel 使用 `@Observable`。

### 關鍵設計決策

- 所有 WebKit 操作均標記 `@MainActor`，因為 `WKWebView` 必須在主執行緒操作。
- Engine 回傳 `Data`（而非 `Any`），以滿足跨並發邊界的 `Sendable` 規範。
- JavaScript 腳本應使用 Swift Raw String（`#"""..."""#`），避免跳脫字元問題。
- `blockMedia = true`（預設值）透過 `mediaTypesRequiringUserActionForPlayback` 阻擋影片與音訊載入，建議維持開啟以提升效能。

## 程式碼風格

- **格式化工具**：每次提交前執行 `swiftformat .`，配置檔為根目錄 `.swiftformat`。
- **縮排**：2 個空格。
- **縮寫詞**：全大寫，例如 `URL`, `ID`, `JS`, `JSON`, `UUID`。
- **尾隨逗號**：集合型別結尾總是加逗號。
- **MARK 區塊**：使用 `MARK: -` 分隔程式碼區塊，成員依可見性排序。
- **DocC 文件**：所有 Public API 必須附帶中文 DocC 註釋，標點符號使用英文半形（逗號 `,`、句點 `.`）。
- **測試框架**：使用 Swift Testing（`@Test`、`#expect`），不使用 XCTest。
- **Swift 版本**：6.2，啟用 Strict Concurrency 檢查。

## Skill Directory Map

> 所有路徑基於 `~/.claude/skills/`
> 載入目錄即載入其下所有檔案（SKILL.md + references/）

### 所有任務必須載入
- `swift-concurrency/`