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
  CKComponent *_overlay;
}

+ (instancetype)newWithQuote:(Quote *)quote
                     context:(QuoteContext *)context
{
  CKComponentScope scope(self);
  const BOOL revealAnswer = [scope.state() boolValue];

  CKComponent *overlay =
  revealAnswer
  ? [SuccessIndicatorComponent
     newWithIndicatesSuccess:[quote.author isEqualToString:oscarWilde]
     successText:[NSString stringWithFormat:@"This quote is by %@", oscarWilde]
     failureText:[NSString stringWithFormat:@"This quote isn't by %@", oscarWilde]]
  : nil;

  InteractiveQuoteComponent *c =
  [super newWithComponent:
   [CKFlexboxComponent
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
        newWithComponent:[QuoteComponent newWithQuote:quote context:context]
        overlay:overlay]},
      {[CKComponent
        newWithView:{
          [UIView class],
          {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}}
        }
        size:{.height = 1 / [UIScreen mainScreen].scale}]}
    }]];
  if (c) {
    c->_overlay = overlay;
  }
  return c;
}

+ (id)initialState
{
  return @NO;
}

- (void)didTap
{
  [self updateState:^(NSNumber *oldState) {
    return [oldState boolValue] ? @NO : @YES;
  } mode:CKUpdateModeSynchronous];
}

- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(InteractiveQuoteComponent *)previousComponent
{
  if (previousComponent->_overlay == nil && _overlay != nil) {
    return {{_overlay, scaleToAppear()}}; // Scale the overlay in when it appears.
  } else {
    return {};
  }
}

static CAAnimation *scaleToAppear()
{
  CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform"];
  scale.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.0, 0.0, 0.0)];
  scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
  scale.duration = 0.2;
  return scale;
}

@end
