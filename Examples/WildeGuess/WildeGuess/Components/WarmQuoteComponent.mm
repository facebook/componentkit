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

#import <ComponentKit/CKIncrementalMountComponent.h>
#import <ComponentKit/CKScrollComponent.h>
#import <ComponentKit/CKComponentScope.h>

#import "QuoteWithBackgroundComponent.h"
#import "QuoteContext.h"

@implementation WarmQuoteComponent

+ (instancetype)newWithText:(NSString *)text context:(QuoteContext *)context
{
  std::vector<CKStackLayoutComponentChild> children;
  for (int i = 0; i < 40; i++) {
    children.push_back({[QuoteWithBackgroundComponent
                         newWithBackgroundImage:[context imageNamed:@"Powell"]
                         quoteComponent:
                         [CKRatioLayoutComponent
                          newWithRatio:1.3
                          size:{
                            .width = [UIScreen mainScreen].bounds.size.width * 0.8
                          }
                          component:
                          [CKInsetComponent
                           // Left and right inset of 30pts; centered vertically:
                           newWithInsets:{.left = 30, .right = 30, .top = INFINITY, .bottom = INFINITY}
                           component:
                           [CKLabelComponent
                            newWithLabelAttributes:{
                              .string = text,
                              .font = [UIFont fontWithName:@"AmericanTypewriter" size:26],
                            }
                            viewAttributes:{
                              {@selector(setBackgroundColor:), [UIColor clearColor]},
                              {@selector(setUserInteractionEnabled:), @NO},
                            }
                            size:{ }]]]]});
  }

  return [super newWithComponent:
          [CKScrollComponent
           newWithConfiguration:{
             .scrollViewDidEndDragging = {@selector(scrollViewDidEndDraggingWithSender:scrollViewState:willDecelerate:)}
           }
           attributes:{}
           component:
           //[CKIncrementalMountComponent
            //newWithComponent:
            [CKStackLayoutComponent
             newWithView:{}
             size:{}
             style:{
               .direction = CKStackLayoutDirectionVertical
             }
             children:{
               {[CKLabelComponent
                 newWithLabelAttributes:{
                   .string = @"string",
                   .font = [UIFont systemFontOfSize:40]
                 }
                 viewAttributes:{}
                 size:{}]},
               {
                 [CKIncrementalMountComponent
                 newWithComponent:
                 [CKStackLayoutComponent
                  newWithView:{}
                  size:{}
                  style:{
                    .direction = CKStackLayoutDirectionHorizontal
                  }
                  children:children]]
               }
             }]]
           //]
  ];

}

- (void)scrollViewDidEndDraggingWithSender:(CKComponent *)sender
                           scrollViewState:(CKScrollViewState)scrollViewState
                            willDecelerate:(BOOL)willDecelerate
{
  NSLog(@"%s", __PRETTY_FUNCTION__);
}

@end
