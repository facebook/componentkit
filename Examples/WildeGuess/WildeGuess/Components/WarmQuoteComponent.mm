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
#import <ComponentKit/CKListComponent.h>
#import <ComponentKit/CKComponentSubclass.h>

#import "QuoteWithBackgroundComponent.h"
#import "QuoteContext.h"
#import "LoadingIndicatorComponent.h"

@implementation WarmQuoteComponent

+ (id)initialState
{
  return [[CKListComponentStateWrapper alloc] initWithItems:{@YES, @YES, @YES, @YES, @YES}];
}

+ (instancetype)newWithText:(NSString *)text context:(QuoteContext *)context
{
  CKComponentScope scope(self);

  CKListComponentStateWrapper *wrapper = scope.state();

  return [super newWithComponent:
          [CKListComponent
           newWithItems:wrapper.items
           context:context
           configuration:{
             .componentGenerator = [text, context](NSNumber *model, QuoteContext *context) -> CKComponent * {
               return [QuoteWithBackgroundComponent
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
                          size:{ }]]]];
             },
             .collectionComponentGenerator = [](const std::vector<id<NSObject>> &items, id<NSObject> context, const CKListComponentItemComponentGenerator &componentGenerator) -> CKComponent *
             {
               std::vector<CKStackLayoutComponentChild> stackChildren;
               for (const auto &item : items) {
                 stackChildren.push_back({componentGenerator(item, context)});
               }
               stackChildren.push_back({[LoadingIndicatorComponent new]});
               return [CKStackLayoutComponent
                       newWithView:{}
                       size:{
                         .height = CKRelativeDimension::Percent(1)
                       }
                       style:{
                         .direction = CKStackLayoutDirectionHorizontal,
                         .alignItems = CKStackLayoutAlignItemsStretch
                       }
                       children:stackChildren];
             },
             .nearingListEndAction = {scope, @selector(loadMore)}
           }]];
}

- (void)loadMore
{
  [self updateState:^CKListComponentStateWrapper *(CKListComponentStateWrapper *wrapper) {
    std::vector<id<NSObject>> items = wrapper.items;
    for (int i = 0; i < 20; i++) {
      items.push_back(@YES);
    }
    return [[CKListComponentStateWrapper alloc] initWithItems:items];
  } mode:CKUpdateModeAsynchronous];
}

@end
