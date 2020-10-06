// Copyright 2004-present Facebook. All Rights Reserved.

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

#import <UIKit/UIKit.h>

#import <ComponentKit/CKComponent.h>
#import <WildeGuessKit/Quote.h>
#import <WildeGuessKit/QuoteContext.h>

NS_ASSUME_NONNULL_BEGIN

typedef CKComponent *_Nonnull(*WildeGuessQuoteComponentProvider)(Quote *_Nonnull, QuoteContext *_Nonnull);

@interface WildeGuessCollectionViewController : UICollectionViewController

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (instancetype)initWithProvider:(WildeGuessQuoteComponentProvider)provider NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
