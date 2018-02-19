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

#import "SuccessIndicatorComponent.h"

@implementation SuccessIndicatorComponent
{
  BOOL _indicatesSuccess;
  NSString *_successText;
  NSString *_failureText;
}

+ (instancetype)newWithIndicatesSuccess:(BOOL)indicatesSuccess
                            successText:(NSString *)successText
                            failureText:(NSString *)failureText
{
  auto const c = [super newWithView:{[UIView class]} size:{}]; // Need a view so supercomponent can animate this component.
  if (c) {
    c->_indicatesSuccess = indicatesSuccess;
    c->_successText = successText;
    c->_failureText = failureText;
  }
  return c;
}

- (CKComponent *)render:(id)state
{
  UIColor *color =
  _indicatesSuccess
  ? [UIColor colorWithRed:0.1 green:0.4 blue:0.1 alpha:0.9]
  : [UIColor colorWithRed:0.7 green:0.1 blue:0.1 alpha:0.9];

  return [CKInsetComponent
           newWithInsets:{.left = 20, .right = 20}
           component:
           [CKCenterLayoutComponent
            newWithCenteringOptions:CKCenterLayoutComponentCenteringY
            sizingOptions:CKCenterLayoutComponentSizingOptionMinimumY
            child:
            [CKBackgroundLayoutComponent
             newWithComponent:
             [CKInsetComponent
              newWithInsets:{.top = 40, .left = 20, .bottom = 40, .right = 20}
              component:
              [CKFlexboxComponent
               newWithView:{}
               size:{}
               style:{
                 .alignItems = CKFlexboxAlignItemsCenter
               }
               children:{
                 {[CKLabelComponent
                   newWithLabelAttributes:{
                     .string = (_indicatesSuccess ? @"Yes" : @"No"),
                     .color = [UIColor whiteColor],
                     .font = [UIFont fontWithName:@"Cochin-Bold" size:45.0],
                     .alignment = NSTextAlignmentCenter
                   }
                   viewAttributes:{
                     {@selector(setBackgroundColor:), [UIColor clearColor]},
                     {@selector(setUserInteractionEnabled:), @NO},
                   }
                   size:{ }]
                 },
                 {[CKLabelComponent
                   newWithLabelAttributes:{
                     .string = (_indicatesSuccess ? _successText : _failureText),
                     .color = [UIColor whiteColor],
                     .font = [UIFont fontWithName:@"Cochin" size:20.0],
                     .alignment = NSTextAlignmentCenter
                   }
                   viewAttributes:{
                     {@selector(setBackgroundColor:), [UIColor clearColor]},
                     {@selector(setUserInteractionEnabled:), @NO},
                   }
                   size:{ }],
                   .spacingBefore = 20
                 }
               }]]
             background:
             [CKComponent
              newWithView:{
                [UIView class],
                {
                  {@selector(setBackgroundColor:), color},
                  {CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), @10.0}
                }
              }
              size:{}]]
            size:{}]];
}

- (std::vector<CKComponentAnimation>)animationsOnInitialMount
{
  return {{self, scaleToAppear()}};
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
