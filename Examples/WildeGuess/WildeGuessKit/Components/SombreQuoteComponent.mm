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

#import "SombreQuoteComponent.h"

#import "QuoteWithBackgroundComponent.h"
#import "QuoteContext.h"
#import <ComponentTextKit/CKLabelComponent.h>
#import <ComponentKit/CKInsetComponent.h>
#import <ComponentKit/CKFlexboxComponent.h>

@implementation SombreQuoteComponent

+ (instancetype)newWithText:(NSString *)text context:(QuoteContext *)context
{
  return [super newWithComponent:
          [QuoteWithBackgroundComponent
           newWithBackgroundImage:[context imageNamed:@"MarketStreet"]
           quoteComponent:
           CK::InsetComponentBuilder()
               .insetsTop(40)
               .insetsLeft(30)
               .insetsBottom(40)
               .insetsRight(30)
               .component([CKFlexboxComponent
             newWithView:{}
             size:{}
             style:{
               .alignItems = CKFlexboxAlignItemsStart,
               .spacing = 50
             }
             children:{
               {lineComponent()},
               {[CKLabelComponent
                 newWithLabelAttributes:{
                   .string = [text uppercaseString],
                   .color = [UIColor whiteColor],
                   .font = [UIFont fontWithName:@"Avenir-Black" size:25]
                 }
                 viewAttributes:{
                   {@selector(setBackgroundColor:), [UIColor clearColor]},
                   {@selector(setUserInteractionEnabled:), @NO},
                 }
                 size:{ }]},
               {lineComponent()},
             }])
               .build()]];;
}

static CKComponent *lineComponent()
{
  return [CKComponent
          newWithView:{
            [UIView class],
            {{@selector(setBackgroundColor:), [UIColor whiteColor]}}
          }
          size:{50, 5}];
}

@end
