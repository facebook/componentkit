/* This file provided by Facebook is for non-commercial testing and evaluation
 * purposes only.  Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import UIKit
import CKSwift
import CKTextSwift

#if swift(>=5.2)

public struct Quote {
  public enum Style : Int, CaseIterable {
    case frosted
    case monochrome
    case sombre
    case warm

    public init(value: Int) {
      self = Style(rawValue: value % Style.allCases.count)!
    }

    public var name: String {
      switch self {
      case .frosted:
        return "Frosted"
      case .monochrome:
        return "Monochrome"
      case .sombre:
        return "Sombre"
      case .warm:
        return "Warm"
      }
    }
  }

  public init(text: String, author: String, style: Style) {
    self.text = text
    self.author = author
    self.style = style
  }

  public init(text: String, author: String, styleValue: Int) {
    self.text = text
    self.author = author
    self.style = Style(value: styleValue)
  }

  public let text: String
  public let author: String
  public let style: Style
}

class QuoteStore {
  private let quotes: [Quote]
  static let shared = QuoteStore()

  init() {
    self.quotes = QuoteStore.data
      .enumerated()
      .map {
        Quote(text: $0.element["text"]!, author: $0.element["author"]!, style: Quote.Style(value: $0.offset))
      }
  }

  func quote(at index: Int) -> Quote {
    quotes[index]
  }

  private static let data = [
    [
      "text": "I have the simplest tastes. I am always satisfied with the best.",
      "author": "Oscar Wilde"
    ], [
      "text": "A thing is not necessarily true because a man dies for it.",
      "author": "Oscar Wilde"
    ], [
      "text": "A poet can survive everything but a misprint.",
      "author": "Oscar Wilde"
    ], [
      "text": "He is really not so ugly after all, provided, of course, that one shuts one's eyes, and does not look at him.",
      "author": "Oscar Wilde"
    ], [
      "text": "People who count their chickens before they are hatched act very wisely because chickens run about so absurdly that it's impossible to count them accurately.",
      "author": "Oscar Wilde"
    ], [
      "text": "It is better to have a permanent income than to be fascinating.",
      "author": "Oscar Wilde"
    ], [
      "text": "Education is an admirable thing. But it is well to remember from time to time that nothing that is worth knowing can be taught.",
      "author": "Oscar Wilde"
    ], [
      "text": "Art is the only serious thing in the world. And the artist is the only person who is never serious.",
      "author": "Oscar Wilde"
    ], [
      "text": "A man who does not think for himself does not think at all.",
      "author": "Oscar Wilde"
    ], [
      "text": "Prayer must never be answered: if it is, it ceases to be prayer and becomes correspondence.",
      "author": "Oscar Wilde"
    ], [
      "text": "The philosophers have only interpreted the world, in various ways. The point, however, is to change it.",
      "author": "Anonymous"
    ], [
      "text": "To improve is to change, so to be perfect is to have changed often.",
      "author": "Anonymous"
    ], [
      "text": "False words are not only evil in themselves, but they infect the soul with evil.",
      "author": "Anonymous"
    ], [
      "text": "It has been said that love robs those who have it of their wit, and gives it to those who have none.",
      "author": "Anonymous"
    ], [
      "text": "The greatest honor history can bestow is the title of peacemaker.",
      "author": "Anonymous"
    ], [
      "text": "The guest who has escaped from the roof, will think twice before he comes back in by the door.",
      "author": "Anonymous"
    ], [
      "text": "I'll not assert that it was a diversion which prevented a war, but nevertheless, it was a diversion.",
      "author": "Anonymous"
    ], [
      "text": "I gyve unto my wief my second best bed with the furniture.",
      "author": "Anonymous"
    ], [
      "text": "He who knows when he can fight and when he cannot will be victorious.",
      "author": "Anonymous"
    ], [
      "text": "Sticks and stones may break my bones but words will never hurt me.",
      "author": "Anonymous"
    ], [
      "text": "It'll be boring when it's not fun any more.",
      "author": "Anonymous"
    ]
  ]
}

struct QuoteContext {
  private let images: [String: UIImage]

  init() {
    self.images = Dictionary(uniqueKeysWithValues: [
      "LosAngeles",
      "MarketStreet",
      "Drops",
      "Powell"
    ].map {
      ($0, UIImage(named: $0)!)
    })
  }

  func image(named name: String) -> UIImage {
    images[name]!
  }

  static let shared = QuoteContext()
}

#endif
