//
//  WebParserMapper.swift
//  WebParser
//
//  Created by Joe Pan on 2026/02/02.
//

import Foundation

/// 定義資料映射邏輯的協定.
///
/// 透過實作此協定, 你可以自訂如何將 ``WebParserEngine`` 回傳的原始 `Data`
/// 轉換為所需的 Swift 模型. 框架提供兩種內建實作：
/// - ``WebParserJSJSONMapper``: 適用於 JS 回傳 JSON 結構的情境.
/// - ``WebParserRegexMapper``: 適用於 JS 回傳純文字需要自訂處理邏輯的情境.
///
/// ### 自訂 Mapper 範例
/// ```swift
/// struct HTMLMapper: WebParserMapper {
///   func map(result: Data) throws -> [String] {
///     // 使用 SwiftSoup 或其他 HTML 解析器
///   }
/// }
/// ```
public protocol WebParserMapper {
  /// 映射結果的目標類型.
  associatedtype T

  /// 將原始 `Data` 轉換為目標模型.
  /// - Parameter result: 來自引擎執行 JavaScript 後序列化的原始資料.
  /// - Returns: 轉換後的模型物件.
  /// - Throws: 解析或解碼過程中發生的錯誤.
  func map(result: Data) throws -> T
}

/// 將 JavaScript 回傳的 JSON 資料直接解碼為 `Decodable` 模型的轉換器.
///
/// 適用於 `executionJS` 回傳 JavaScript Object 或 Array 的情境.
/// 引擎內部已透過 `JSONSerialization` 將 JS 結果序列化為 `Data`,
/// 此 Mapper 再負責最終的 `JSONDecoder` 解碼.
///
/// ### 使用範例
/// ```swift
/// struct Comic: Decodable { let title: String }
/// let results = try await parser.parse(
///   with: config,
///   mapper: WebParserJSJSONMapper<[Comic]>()
/// )
/// ```
public struct WebParserJSJSONMapper<T: Decodable>: WebParserMapper {
  /// 初始化 JS-JSON 轉換器.
  public init() {}

  /// 使用 `JSONDecoder` 將資料解碼為指定的 `Decodable` 模型.
  public func map(result: Data) throws -> T {
    try JSONDecoder().decode(T.self, from: result)
  }
}

/// 透過自訂閉包處理原始資料的通用轉換器.
///
/// 適用於 `executionJS` 回傳純文字 (例如完整 HTML 或 `document.title`) 的情境.
/// 你可以在 `extractor` 閉包中使用正規表達式, 字串處理或任意邏輯來擷取所需內容.
/// 回傳類型不限制為 `Codable`, 可以是任意 Swift 類型.
///
/// ### 使用範例
/// ```swift
/// let mapper = WebParserRegexMapper<String> { data in
///   let raw = String(data: data, encoding: .utf8) ?? ""
///   // 移除 JS 回傳字串時可能夾帶的 JSON 引號
///   return raw.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
/// }
/// ```
public struct WebParserRegexMapper<T>: WebParserMapper {
  /// 封裝自訂解析邏輯的閉包.
  private let extractor: (Data) throws -> T

  /// 初始化自訂轉換器.
  /// - Parameter extractor: 接收原始 `Data` 並回傳模型 `T` 的解析邏輯.
  public init(extractor: @escaping (Data) throws -> T) {
    self.extractor = extractor
  }

  /// 呼叫 `extractor` 閉包執行自訂映射.
  public func map(result: Data) throws -> T {
    try extractor(result)
  }
}
