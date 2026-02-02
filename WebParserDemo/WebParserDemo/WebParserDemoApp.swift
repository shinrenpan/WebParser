//
//  WebParserDemoApp.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import SwiftUI

/// WebParserDemo 應用程式的主進入點.
///
/// 此 App 展示了如何將 WebParser 框架整合進 SwiftUI 專案中.
/// 透過觀察者模式與離屏渲染，實現高效且非同步的網頁資料擷取.
@main
struct WebParserDemoApp: App {
  /// 定義應用程式的主要場景.
  var body: some Scene {
    WindowGroup {
      // 啟動主視圖
      ContentView()
    }
  }
}
