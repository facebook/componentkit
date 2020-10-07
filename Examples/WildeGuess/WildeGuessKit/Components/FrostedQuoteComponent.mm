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

#import "FrostedQuoteComponent.h"

#import "QuoteWithBackgroundComponent.h"
#import "QuoteContext.h"
#import <ComponentTextKit/CKLabelComponent.h>
#import <ComponentKit/CKInsetComponent.h>
#import <ComponentKit/CKFlexboxComponent.h>

@implementation FrostedQuoteComponent

+ (instancetype)newWithText:(NSString *)text
                    context:(QuoteContext *)context
{
  return [super newWithComponent:
          [QuoteWithBackgroundComponent
           newWithBackgroundImage:[context imageNamed:@"LosAngeles"]
           quoteComponent:
           CK::InsetComponentBuilder()
               .insetsTop(70)
               .insetsBottom(25)
               .insetsLeft(20)
               .insetsRight(20)
               .component([CKFlexboxComponent
             newWithView:{}
             size:{}
             style:{.alignItems = CKFlexboxAlignItemsStart}
             children:{
               {
                 [CKLabelComponent
                  newWithLabelAttributes:{
                    .string = text,
                    .font = [UIFont fontWithName:@"Baskerville" size:30]
                  }
                  viewAttributes:{
                    {@selector(setBackgroundColor:), [UIColor clearColor]},
                    {@selector(setUserInteractionEnabled:), @NO},
                  }
                  size:{ }],
                 .alignSelf = CKFlexboxAlignSelfCenter
               },
               {
                 // A semi-transparent end quote (") symbol placed below the quote.
                 CK::InsetComponentBuilder()
                     .insetsRight(5)
                     .component([CKLabelComponent
                   newWithLabelAttributes:{
                     .string = @"\u201D",
                     .color = [UIColor colorWithWhite:1 alpha:0.5],
                     .font = [UIFont fontWithName:@"Baskerville" size:140]
                   }
                   viewAttributes:{
                     {@selector(setBackgroundColor:), [UIColor clearColor]},
                     {@selector(setUserInteractionEnabled:), @NO},
                   }
                   size:{ }])
                     .build(),
                 .alignSelf = CKFlexboxAlignSelfEnd, // Right aligned
               }
             }])
               .build()]];
}

@end
