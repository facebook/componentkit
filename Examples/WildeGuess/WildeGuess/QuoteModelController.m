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

#import "QuoteModelController.h"

#import <UIKit/UIColor.h>

#import "Quote.h"
#import "QuoteDisplayStyle.h"
#import "QuotesPage.h"

@implementation QuoteModelController
{
  NSInteger _numberOfObjects;
}

- (instancetype)init
{
  if (self = [super init]) {
    _numberOfObjects = 0;
  }
  return self;
}

- (QuotesPage *)fetchNewQuotesPageWithCount:(NSInteger)count
{
  NSAssert(count >= 1, @"Count should be a positive integer");
  NSArray * quotes = generateRandomQuotes(count);
  QuotesPage *quotesPage = [[QuotesPage alloc] initWithQuotes:quotes
                                                     position:_numberOfObjects];
  _numberOfObjects += count;
  return quotesPage;
}

#pragma mark - Random Quote Generation

static NSArray<Quote *> *generateRandomQuotes(NSInteger count)
{
  NSMutableArray<Quote *> *quotes = [[NSMutableArray alloc] initWithCapacity:count];
  for (NSUInteger i = 0; i< count; i++) {
    NSDictionary<NSString *, NSString *> *quoteInfo = generateRandomQuoteInfo();
    Quote *quote  = [[Quote alloc] initWithText:quoteInfo[@"text"]
                                         author:quoteInfo[@"author"]
                                          style:generateStyle(i)];
    [quotes addObject:quote];
  }
  return quotes;
}

static NSDictionary<NSString *, NSString *> *generateRandomQuoteInfo()
{
  NSArray<NSDictionary<NSString *, NSString *> *> *quotes = quotesList();
  return quotes[arc4random_uniform((uint32_t)[quotes count])];
}

static QuoteDisplayStyle generateStyle(NSUInteger index)
{
  switch (index % 4) {
    case 0:
      return QuoteDisplayStyleFrosted;
    case 1:
      return QuoteDisplayStyleMonochrome;
    case 2:
      return QuoteDisplayStyleWarm;
    case 3:
    default:
      return QuoteDisplayStyleSombre;
  }
}

static NSArray<NSDictionary<NSString *, NSString *> *> *quotesList()
{
  static NSArray *quotes;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    quotes = @[
               @{
                 @"text": @"I have the simplest tastes. I am always satisfied with the best.",
                 @"author": @"Oscar Wilde",
                 },
               @{
                 @"text": @"A thing is not necessarily true because a man dies for it.",
                 @"author": @"Oscar Wilde",
                 },
               @{
                 @"text": @"A poet can survive everything but a misprint.",
                 @"author": @"Oscar Wilde",
                 },
               @{
                 @"text": @"He is really not so ugly after all, provided, of course, that one shuts one's eyes, and does not look at him.",
                 @"author": @"Oscar Wilde",
                 },
               @{
                 @"text": @"People who count their chickens before they are hatched act very wisely because chickens run about so absurdly that it's impossible to count them accurately.",
                 @"author": @"Oscar Wilde",
                 },
               @{
                 @"text": @"It is better to have a permanent income than to be fascinating.",
                 @"author": @"Oscar Wilde",
                 },
               @{
                 @"text": @"Education is an admirable thing. But it is well to remember from time to time that nothing that is worth knowing can be taught.",
                 @"author": @"Oscar Wilde",
                 },
               @{
                 @"text": @"Art is the only serious thing in the world. And the artist is the only person who is never serious.",
                 @"author": @"Oscar Wilde",
                 },
               @{
                 @"text": @"A man who does not think for himself does not think at all.",
                 @"author": @"Oscar Wilde",
                 },
               @{
                 @"text": @"Prayer must never be answered: if it is, it ceases to be prayer and becomes correspondence.",
                 @"author": @"Oscar Wilde",
                 },
               @{
                 @"text":@"The philosophers have only interpreted the world, in various ways. The point, however, is to change it.",
                 @"author": @"Anonymous",
                 },
               @{
                 @"text":@"To improve is to change, so to be perfect is to have changed often.",
                 @"author": @"Anonymous",
                 },
               @{
                 @"text":@"False words are not only evil in themselves, but they infect the soul with evil.",
                 @"author": @"Anonymous",
                 },
               @{
                 @"text":@"It has been said that love robs those who have it of their wit, and gives it to those who have none.",
                 @"author": @"Anonymous",
                 },
               @{
                 @"text":@"The greatest honor history can bestow is the title of peacemaker.",
                 @"author": @"Anonymous",
                 },
               @{
                 @"text":@"The guest who has escaped from the roof, will think twice before he comes back in by the door.",
                 @"author": @"Anonymous",
                 },
               @{
                 @"text":@"I'll not assert that it was a diversion which prevented a war, but nevertheless, it was a diversion.",
                 @"author": @"Anonymous",
                 },
               @{
                 @"text":@"I gyve unto my wief my second best bed with the furniture.",
                 @"author": @"Anonymous",
                 },
               @{
                 @"text":@"He who knows when he can fight and when he cannot will be victorious.",
                 @"author": @"Anonymous",
                 },
               @{
                 @"text":@"Sticks and stones may break my bones but words will never hurt me.",
                 @"author": @"Anonymous",
                 },
               @{
                 @"text":@"It'll be boring when it's not fun any more.",
                 @"author": @"Anonymous",
                 }
               ];
  });
  return quotes;
}

@end
