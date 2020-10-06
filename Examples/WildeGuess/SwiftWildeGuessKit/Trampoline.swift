//
//  Trampoline.swift
//  WildeGuess
//
//  Created by Hugo Cuvillier on 20/09/2020.
//

import Foundation
import CKSwift
import CKTextSwift

#if swift(>=5.3)
@ComponentBuilder public func SwiftQuoteComponent(from quote: Quote) -> Component {
  SwiftInteractiveWrapperQuoteView(quote: quote, context: QuoteContext.shared)
}

@objc public class Trampoline : NSObject {
   @objc public class func component(text: String, author: String, style: Int) -> Component {
    SwiftQuoteComponent(from: Quote(text: text, author: author, style: Quote.Style(value: style)))
   }
}

#else
@objc public class Trampoline : NSObject {
   @objc public class func component(text: String, author: String, style: Int) -> Component {
    fatalError("Swift 5.3 required")
   }
}

#endif
