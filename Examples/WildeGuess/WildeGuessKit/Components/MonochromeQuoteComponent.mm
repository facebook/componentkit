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

#import "MonochromeQuoteComponent.h"

#import "QuoteWithBackgroundComponent.h"
#import "QuoteContext.h"
#import <ComponentTextKit/CKLabelComponent.h>
#import <ComponentKit/CKInsetComponent.h>
#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKit/CKBackgroundLayoutComponent.h>

@implementation MonochromeQuoteComponent

+ (instancetype)newWithText:(NSString *)text context:(QuoteContext *)context
{
  CKComponent *quoteTextComponent =
  CK::InsetComponentBuilder()
      .insetsTop(50)
      .insetsLeft(20)
      .insetsBottom(50)
      .insetsRight(20)
      .component([CKLabelComponent
    newWithLabelAttributes:{
      .string = text,
      .color = [UIColor darkGrayColor],
      .font = [UIFont fontWithName:@"HoeflerText-Italic" size:25.0]
    }
    viewAttributes:{
      {@selector(setBackgroundColor:), [UIColor clearColor]},
      {@selector(setUserInteractionEnabled:), @NO},
    }
    size:{ }])
      .build();

  CKComponent *quoteTextWithBookmarkComponent =
  [CKFlexboxComponent
   newWithView:{}
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
   }
   children:{
     {
       // Small dark gray rectangle as a bookmark.
       .component =
       [CKComponent
        newWithView:{
          [UIView class],
          {{@selector(setBackgroundColor:), [UIColor darkGrayColor]}}
        }
        size:{20, 40}],
       .spacingBefore = 10
     },
     {
       .component = quoteTextComponent,
       .flexShrink = 1,
       .flexBasis = CKRelativeDimension::Percent(1.0)
     }
   }];

  return [super newWithComponent:
          [QuoteWithBackgroundComponent
           newWithBackgroundImage:[context imageNamed:@"Drops"]
           quoteComponent:
           CK::InsetComponentBuilder()
               .insetsTop(40)
               .insetsBottom(40)
               .component(CK::BackgroundLayoutComponentBuilder()
                              .component(quoteTextWithBookmarkComponent)
                              .background([CKComponent
              newWithView:{
                [UIView class],
                {{@selector(setBackgroundColor:), [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7]}}
              }
              size:{}])
                              .build())
               .build()]];
}

@end
