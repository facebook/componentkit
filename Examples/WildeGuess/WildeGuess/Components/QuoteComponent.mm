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

#import "QuoteComponent.h"

#import "FrostedQuoteComponent.h"
#import "MonochromeQuoteComponent.h"
#import "Quote.h"
#import "QuoteContext.h"
#import "SombreQuoteComponent.h"
#import "WarmQuoteComponent.h"

@implementation QuoteComponent

+ (instancetype)newWithQuote:(Quote *)quote context:(QuoteContext *)context
{
  return [super newWithComponent:quoteComponent(quote, context)];
}

static CKComponent *quoteComponent(Quote *quote, QuoteContext *context)
{
  switch (quote.style) {
    case QuoteDisplayStyleFrosted:
      return [FrostedQuoteComponent
              newWithText:quote.text
              context:context];
    case QuoteDisplayStyleMonochrome:
      return [MonochromeQuoteComponent
              newWithText:quote.text
              context:context];
    case QuoteDisplayStyleSombre:
      return [SombreQuoteComponent
              newWithText:quote.text
              context:context];
    case QuoteDisplayStyleWarm:
      return [WarmQuoteComponent
              newWithText:quote.text
              context:context];
  }
}

@end
