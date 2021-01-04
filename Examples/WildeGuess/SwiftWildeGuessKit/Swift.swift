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

#if swift(>=5.3)

extension CAAnimation {
  static let fadeId: CAAnimation = {
    let animation = CABasicAnimation(keyPath: "transform")
    animation.fromValue = NSValue(caTransform3D: CATransform3DMakeScale(0.0, 0.0, 0.0))
    animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
    animation.duration = 0.2
    return animation
  }()
}

struct SwiftInteractiveQuoteView : View, ViewIdentifiable, ViewConfigurationRepresentable, Actionable {
  let quote: Quote
  let context: QuoteContext
  @Binding var revealAnswer: Bool

  var body: Component {
    FlexboxComponent(
      view: ViewConfiguration(viewClass: UIView.self) {
        onTap { view, _ in
          view.revealAnswer.toggle()
        }
      },
      alignItems: .stretch) {
      QuoteView(quote: quote, context: context)
        .overlay {
          if revealAnswer {
            SuccessIndicatorView(
              successful:quote.author == "Oscar Wilde",
              successText: "This quote is by Oscar Wilde",
              failureText: "This quote isn't by Oscar Wilde"
            )
            .onInitialMount(.fadeId)
          }
        }
      ComponentView<UIView> {
        (\.backgroundColor, .lightGray)
      }
      .frame(height: 1 / UIScreen.main.scale)
    }
  }

  let id = "Toto"
  let viewConfiguration = ViewConfiguration(viewClass: UIView.self)
}

fileprivate struct SuccessIndicatorView : View {
  let successful: Bool
  let successText: String
  let failureText: String

  var body: Component {
    WrapperComponentView {
      (\.backgroundColor, .clear)
      (\.isUserInteractionEnabled, false)
    } component: {
      FlexboxComponent(alignItems: .center) {
        LabelComponent(
          text: successful ? "Yes" : "No",
          font: UIFont(name: "Cochin-Bold", size: 45),
          color: .white,
          alignment: .center) {
            (\.backgroundColor, .clear)
        }
        LabelComponent(
          text: successful ? successText : failureText,
          font: UIFont(name: "Cochin", size: 20),
          color: .white,
          alignment: .center) {
            (\.backgroundColor, .clear)
        }
      }
    }
    .padding(top: 40, left: 20, bottom: 40, right: 20)
    .background {
      let color = successful ?
        UIColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 0.9)
        : UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 0.9)
      ComponentView<UIView> {
        (\.backgroundColor, color)
        (\.cornerRadius, 10)
      }
    }
    .center(centeringOptions: .Y, sizingOptions: .minimumY)
    .padding(left: 20, right: 20)
  }
}

struct Something : Hashable {}

struct SwiftInteractiveWrapperQuoteView : View, ViewIdentifiable {
  let quote: Quote
  let context: QuoteContext

  @State var revealAnswer = false

  var body: Component {
    SwiftInteractiveQuoteView(
      quote: quote,
      context: context,
      revealAnswer: $revealAnswer
    )
  }

  var id: Something {
    Something()
  }
}

fileprivate struct LabelView: View {
  let text: String
  let font: UIFont?
  let color: UIColor?

  init(text: String, font: UIFont? = nil, color: UIColor? = nil) {
    self.text = text
    self.font = font
    self.color = color
  }

  var body: Component {
    LabelComponent(
      text: text,
      font: font,
      color: color) {
        (\.backgroundColor, .clear)
        (\.isUserInteractionEnabled, false)
    }
  }
}

fileprivate struct QuoteView : View {
  let quote: Quote
  let context: QuoteContext

  var body: Component {
    switch quote.style {
    case .frosted:
      FrostedQuoteView(text: quote.text, context: context)
    case .monochrome:
      MonochromeQuoteView(text: quote.text, context: context)
    case .sombre:
      SombreQuoteView(text: quote.text, context: context)
    case .warm:
      WarmQuoteView(
        text: quote.text,
        context: context
      )
      .onWillMount {
        print("Will Mount")
      }
      .onWillMount {
        print("Will Mount 2")
      }
      .onWillMount {
        print("Will Mount 3")
      }
    }
  }
}

fileprivate struct SombreQuoteView : View {
  let text: String
  let context: QuoteContext

  var body: Component {
    let line = ComponentView<UIView> {
      (\.backgroundColor, .white)
    }
    .frame(width: 50, height: 5)

    QuoteWithBackgroundView(
      image: context.image(named: "MarketStreet")) {
      FlexboxComponent(
        spacing: 50,
        alignItems: .start) {
        line
        LabelView(
          text: text.uppercased(),
          font: UIFont(name: "Avenir-Black", size: 25),
          color: .white
        )
        line
      }
      .padding(top: 40, left: 30, bottom: 40, right: 30)
    }
  }
}

fileprivate struct QuoteWithBackgroundView : View {
  let image: UIImage
  let component: () -> Component

  init(image: UIImage, @ComponentBuilder component: @escaping () -> Component) {
    self.image = image
    self.component = component
  }

  var body: Component {
    component()
      .background {
        ComponentView<UIImageView> {
          (\.image, image)
          (\.contentMode, .scaleAspectFill)
          (\.clipsToBounds, true)
        }
      }
  }
}

fileprivate struct FrostedQuoteView : View  {
  let text: String
  let context: QuoteContext

  var body: Component {
    QuoteWithBackgroundView(image: context.image(named: "LosAngeles")) {
      FlexboxComponent(alignItems: .start) {
        FlexboxComponent.Child(alignSelf: .center) {
          LabelView(
            text: text,
            font: UIFont(name: "Baskerville", size: 30)
          )
        }
        FlexboxComponent.Child(alignSelf: .end) {
          LabelView(
            text: "\u{201D}",
            font: UIFont(name: "Baskerville", size: 140),
            color: UIColor.white.withAlphaComponent(0.5)
          )
          .padding(right: 5)
        }
      }
      .padding(top: 70, left: 20, bottom: 25, right: 20)
    }
  }
}

fileprivate struct MonochromeQuoteView : View  {
  let text: String
  let context: QuoteContext

  var body: Component {
    QuoteWithBackgroundView(image: context.image(named: "Drops")) {
      FlexboxComponent(
        direction: .row,
        alignItems: .start) {
        FlexboxComponent.Child(spacingBefore: 10) {
          ComponentView<UIView> {
            (\.backgroundColor, .darkGray)
          }
          .frame(width: 30, height: 40)
        }
        FlexboxComponent.Child(flexShrink: 1, flexBasis: .percent(1.0)) {
          LabelView(
            text: text,
            font: UIFont(name: "HoeflerText-Italic", size: 25),
            color: .darkGray
          )
          .padding(top: 50, left: 20, bottom: 50, right: 20)
        }
      }
      .background {
        ComponentView<UIView> {
          (\.backgroundColor, UIColor.white.withAlphaComponent(0.7))
        }
      }
      .padding(top: 40, bottom: 40)
    }
  }
}

fileprivate struct WarmQuoteView : View {
  let text: String
  let context: QuoteContext

  var body: Component {
    QuoteWithBackgroundView(image: context.image(named: "Powell")) {
      LabelView(
        text: text,
        font: UIFont(name: "AmericanTypewriter", size: 26)
      )
      .padding(top: .infinity, left: 30, bottom: .infinity, right: 30)
      .ratio(1.3)
    }
  }
}

#endif
