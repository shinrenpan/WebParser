//
//  ContentView.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import SwiftUI

/// 應用程式的主導覽視圖.
///
/// 透過 TabView 整合不同的測試場景，展示 WebParser 的多種用途.
struct ContentView: View {
  /// 定義視圖佈局與標籤頁內容.
  var body: some View {
    TabView {
      // 第一頁：基礎標題擷取測試 (驗證單一 DOM 元素擷取)
      TitleTestView()
        .tabItem {
          Label("標題測試", systemImage: "text.magnifyingglass")
        }

      // 第二頁：漫畫更新列表 (驗證複雜陣列資料與 JSON 映射)
      ComicListView()
        .tabItem {
          Label("漫畫更新", systemImage: "books.vertical")
        }
    }
  }
}
