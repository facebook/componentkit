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

#import "InteractiveQuoteComponent.h"

#import <ComponentKit/CKComponentSubclass.h>

#import "Quote.h"
#import "QuoteComponent.h"
#import "QuoteContext.h"
#import "SuccessIndicatorComponent.h"

static NSString *const oscarWilde = @"Oscar Wilde";

@implementation InteractiveQuoteComponent
{
  Quote *_quote;
  QuoteContext *_context;
}

+ (instancetype)newWithQuote:(Quote *)quote
                     context:(QuoteContext *)context
{
  InteractiveQuoteComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_quote = quote;
    c->_context = context;
  }
  return c;
}

- (CKComponent *)render:(id)state
{
  auto const revealAnswer = [state boolValue];

  CKComponent *overlay =
  revealAnswer
  ? [SuccessIndicatorComponent
     newWithIndicatesSuccess:[_quote.author isEqualToString:oscarWilde]
     successText:[NSString stringWithFormat:@"This quote is by %@", oscarWilde]
     failureText:[NSString stringWithFormat:@"This quote isn't by %@", oscarWilde]]
  : nil;

  return [CKFlexboxComponent
          newWithView:{
            [UIView class],
            {CKComponentTapGestureAttribute(@selector(didTap))}
          }
          size:{}
          style:{
            .alignItems = CKFlexboxAlignItemsStretch
          }
          children:{
            {[CKOverlayLayoutComponent
              newWithComponent:[QuoteComponent newWithQuote:_quote context:_context]
              overlay:overlay]},
            {[CKComponent
              newWithView:{
                [UIView class],
                {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}}
              }
              size:{.height = 1/[UIScreen mainScreen].scale}]}
          }];
}

+ (id)initialState
{
  return @NO;
}

- (void)didTap
{
  [self updateState:^(NSNumber *oldState){
    return [oldState boolValue] ? @NO : @YES;
  } mode:CKUpdateModeSynchronous];
}

@end
