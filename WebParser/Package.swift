//
//  Package.swift
//  WebParser
//
//  Created by Joe Pan on 2026/02/02.
//

// swift-tools-version: 6.2
// swift-tools-version 宣告了建置此套件所需的最低 Swift 版本.
// 在 2026 年，建議使用 6.2 以獲得最佳的並發安全性支援.

import PackageDescription

/// WebParser 框架的定義與配置.
///
/// 本套件採用 Swift Package Manager (SPM) 進行管理,
/// 專為 iOS 17+ 平台提供現代化的網頁內容解析功能.
let package = Package(
  name: "WebParser",
  // 指定支援的平台版本. 由於使用了 Swift Testing 與 Duration API, 建議最低要求為 iOS 17.
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    // 對外曝露的 Library，供其他專案引用.
    .library(
      name: "WebParser",
      targets: ["WebParser"],
    ),
  ],
  targets: [
    // WebParser 核心邏輯目標.
    .target(
      name: "WebParser",
    ),
    // WebParser 測試目標, 依賴於核心 Target 並使用 Swift Testing 框架.
    .testTarget(
      name: "WebParserTests",
      dependencies: ["WebParser"],
    ),
  ],
)
