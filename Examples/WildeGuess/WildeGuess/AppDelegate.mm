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

#import "AppDelegate.h"

#import <WildeGuessKit/WildeGuessCollectionViewController.h>
#import <ComponentKit/CKComponent.h>
#import <WildeGuessKit/Quote.h>
#import <WildeGuessKit/QuoteContext.h>
#import <SwiftWildeGuessKit/SwiftWildeGuessKit-Swift.h>

@implementation AppDelegate
{
  UIWindow *_window;
  UINavigationController *_navigationController;
  BOOL _showsSwiftViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [_window setRootViewController:[[UINavigationController alloc] initWithRootViewController:[self makeObjectiveCViewController]]];
  [_window makeKeyAndVisible];
  return YES;
}

- (UIViewController *)makeObjectiveCViewController
{
  UIViewController *viewController = [WildeGuessCollectionViewController new];
  viewController.navigationItem.rightBarButtonItem = [self makeBarButtonItem];
  return viewController;
}

static CKComponent *swiftComponentGenerator(Quote *quote, QuoteContext *quoteContext) {
  return [Trampoline componentWithText:quote.text author:quote.author style:(NSInteger)quote.style];
}

- (UIViewController *)makeSwiftViewController
{
  UIViewController *viewController = [[WildeGuessCollectionViewController alloc] initWithProvider:swiftComponentGenerator];
  viewController.navigationItem.rightBarButtonItem = [self makeBarButtonItem];
  return viewController;
}

- (UIBarButtonItem *)makeBarButtonItem
{
  NSString *const title = _showsSwiftViewController ? @"Obj-C" : @"Swift";
  return [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(toggleViewController)];
}

- (void)toggleViewController
{
  _showsSwiftViewController = _showsSwiftViewController == NO;
  UINavigationController *navigationController = (id)_window.rootViewController;
  navigationController.viewControllers = @[_showsSwiftViewController ?
                                           [self makeSwiftViewController]
                                           : [self makeObjectiveCViewController]];
}

@end

