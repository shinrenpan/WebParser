//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import Foundation

public protocol WebParserDelegate: class
{
    func parserDidStart<T: Decodable>(_ parser: WebParser<T>)
    func parserDidFinish<T: Decodable>(_ parser: WebParser<T>, result: T)
    func parserDidFail<T: Decodable>(_ parser: WebParser<T>, error: Error)
    func parserDidCancel<T: Decodable>(_ parser: WebParser<T>)
}

public extension WebParserDelegate
{
    func parserDidStart<T: Decodable>(_ parser: WebParser<T>) {}
    func parserDidFinish<T: Decodable>(_ parser: WebParser<T>, result: T) {}
    func parserDidFail<T: Decodable>(_ parser: WebParser<T>, error: Error) {}
    func parserDidCancel<T: Decodable>(_ parser: WebParser<T>) {}
}
