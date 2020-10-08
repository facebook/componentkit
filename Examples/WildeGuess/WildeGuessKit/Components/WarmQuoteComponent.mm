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

#import "WarmQuoteComponent.h"
#import "QuoteWithBackgroundComponent.h"
#import "QuoteContext.h"

#import <ComponentTextKit/CKLabelComponent.h>
#import <ComponentKit/CKInsetComponent.h>
#import <ComponentKit/CKRatioLayoutComponent.h>

@implementation WarmQuoteComponent

+ (instancetype)newWithText:(NSString *)text context:(QuoteContext *)context
{
  return [super newWithComponent:
          [QuoteWithBackgroundComponent
           newWithBackgroundImage:[context imageNamed:@"Powell"]
           quoteComponent:
           CK::RatioLayoutComponentBuilder()
            .ratio(1.3)
            .component(
                CK::InsetComponentBuilder()
                    .insetsLeft(30)
                    .insetsRight(30)
                    .insetsTop(INFINITY)
                    .insetsBottom(INFINITY)
                    .component([CKLabelComponent
                  newWithLabelAttributes:{
                    .string = text,
                    .font = [UIFont fontWithName:@"AmericanTypewriter" size:26],
                  }
                  viewAttributes:{
                    {@selector(setBackgroundColor:), [UIColor clearColor]},
                    {@selector(setUserInteractionEnabled:), @NO},
                  }
                  size:{ }])
                 .build()
            )
            .build()]];
}

@end
