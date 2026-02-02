//
//  WebParserMapper.swift
//  WebParser
//
//  Created by Joe Pan on 2026/02/02.
//

import Foundation

/// 定義資料映射邏輯的協定.
///
/// 透過實作此協定，你可以自定義如何將 `WebParserEngine` 擷取到的原始 `Data`
/// 轉換為具備型別安全的 Swift `Codable` 模型.
public protocol WebParserMapper {
  /// 映射目標的模型類型. 必須符合 `Codable` 規範.
  associatedtype T: Codable

  /// 執行從原始資料到模型物件的轉換邏輯.
  /// - Parameter result: 來自引擎執行 JavaScript 後序列化的 `Data`.
  /// - Returns: 轉換後的泛型模型物件 `T`.
  /// - Throws: 拋出解析或解碼過程中的錯誤.
  func map(result: Data) throws -> T
}

/// 專門用於處理 JavaScript 原生對象 (Array/Object) 或 JSON 字串的轉換器.
///
/// 此轉換器適用於當您的 `executionJS` 回傳的是結構化資料時.
/// 引擎會自動將結果序列化為 `Data`，此對應器則負責執行最後的 JSON 解碼.
public struct WebParserJSJSONMapper<T: Codable>: WebParserMapper {
  /// 初始化 JS-JSON 轉換器.
  public init() {}

  /// 執行 JSON 解碼.
  /// - Parameter result: 引擎傳回的序列化資料.
  /// - Returns: 指定的 `Codable` 模型.
  public func map(result: Data) throws -> T {
    // 引擎層級已透過 JSONSerialization 處理好 Data，此處直接使用 JSONDecoder.
    try JSONDecoder().decode(T.self, from: result)
  }
}

/// 提供使用正規表達式 (Regex) 或高度自定義邏輯來處理結果的轉換器.
///
/// 當 `executionJS` 回傳的是純文字 (如全頁面 HTML) 時，
/// 您可以透過此轉換器提供的 `extractor` 閉包進行字串擷取或複雜的邏輯處理.
public struct WebParserRegexMapper<T: Codable>: WebParserMapper {
  /// 封裝自定義解析邏輯的閉包.
  private let extractor: (Data) throws -> T

  /// 初始化 Regex/自定義轉換器.
  /// - Parameter extractor: 接收原始 `Data` 並回傳模型 `T` 的處理邏輯.
  public init(extractor: @escaping (Data) throws -> T) {
    self.extractor = extractor
  }

  /// 呼叫封裝的擷取邏輯執行映射.
  /// - Parameter result: 引擎傳回的原始資料.
  /// - Returns: 擷取並封裝後的模型物件.
  public func map(result: Data) throws -> T {
    try extractor(result)
  }
}
