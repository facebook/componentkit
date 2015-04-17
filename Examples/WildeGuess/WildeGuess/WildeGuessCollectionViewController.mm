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

#import "WildeGuessCollectionViewController.h"

#import <ComponentKit/ComponentKit.h>

#import "InteractiveQuoteComponent.h"
#import "QuoteModelController.h"
#import "Quote.h"
#import "QuoteContext.h"
#import "QuotesPage.h"

@interface WildeGuessCollectionViewController () <CKComponentProvider, UICollectionViewDelegateFlowLayout>
@end

@implementation WildeGuessCollectionViewController
{
  CKCollectionViewDataSource *_dataSource;
  QuoteModelController *_quoteModelController;
  CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
  if (self = [super initWithCollectionViewLayout:layout]) {
    _sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleHeight];
    _quoteModelController = [[QuoteModelController alloc] init];
    self.title = @"Wilde Guess";
    self.navigationItem.prompt = @"Tap to reveal which quotes are from Oscar Wilde";
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Preload images for the component context that need to be used in component preparation. Components preparation
  // happens on background threads but +[UIImage imageNamed:] is not thread safe and needs to be called on the main
  // thread. The preloaded images are then cached on the component context for use inside components.
  NSSet *imageNames = [NSSet setWithObjects:
                       @"LosAngeles",
                       @"MarketStreet",
                       @"Drops",
                       @"Powell",
                       nil];

  self.collectionView.backgroundColor = [UIColor whiteColor];
  self.collectionView.delegate = self;

  QuoteContext *context = [[QuoteContext alloc] initWithImageNames:imageNames];
  _dataSource = [[CKCollectionViewDataSource alloc] initWithCollectionView:self.collectionView
                                               supplementaryViewDataSource:nil                                                         
                                                         componentProvider:[self class]
                                                                   context:context
                                                 cellConfigurationFunction:nil];
  // Insert the initial section
  CKArrayControllerSections sections;
  sections.insert(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:{}];
  [self _enqueuePage:[_quoteModelController fetchNewQuotesPageWithCount:4]];
}

- (void)_enqueuePage:(QuotesPage *)quotesPage
{
  NSArray *quotes = quotesPage.quotes;
  NSInteger position = quotesPage.position;

  // Convert the array of quotes to a valid changeset
  CKArrayControllerInputItems items;
  for (NSInteger i = 0; i < [quotes count]; i++) {
    items.insert([NSIndexPath indexPathForRow:position + i inSection:0], quotes[i]);
  }
  [_dataSource enqueueChangeset:{{}, items}
                constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size]];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [_dataSource sizeForItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath
{
  [_dataSource announceWillAppearForItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView
  didEndDisplayingCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath
{
  [_dataSource announceDidDisappearForItemAtIndexPath:indexPath];
}

#pragma mark - CKComponentProvider

+ (CKComponent *)componentForModel:(Quote *)quote context:(QuoteContext *)context
{
  return [InteractiveQuoteComponent
          newWithQuote:quote
          context:context];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if (scrolledToBottomWithBuffer(scrollView.contentOffset, scrollView.contentSize, scrollView.contentInset, scrollView.bounds)) {
    [self _enqueuePage:[_quoteModelController fetchNewQuotesPageWithCount:8]];
  }
}

static BOOL scrolledToBottomWithBuffer(CGPoint contentOffset, CGSize contentSize, UIEdgeInsets contentInset, CGRect bounds)
{
  CGFloat buffer = CGRectGetHeight(bounds) - contentInset.top - contentInset.bottom;
  const CGFloat maxVisibleY = (contentOffset.y + bounds.size.height);
  const CGFloat actualMaxY = (contentSize.height + contentInset.bottom);
  return ((maxVisibleY + buffer) >= actualMaxY);
}

@end
