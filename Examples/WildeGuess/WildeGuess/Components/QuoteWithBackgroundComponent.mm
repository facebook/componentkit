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

#import "QuoteWithBackgroundComponent.h"

@implementation QuoteWithBackgroundComponent
{
  UIImage *_backgroundImage;
  CKComponent *_quoteComponent;
}

+ (instancetype)newWithBackgroundImage:(UIImage *)backgroundImage
                        quoteComponent:(CKComponent *)quoteComponent
{
  auto const c = [super new];
  if (c) {
    c->_backgroundImage = backgroundImage;
    c->_quoteComponent = quoteComponent;
  }
  return c;
}

- (CKComponent *)render:(id)state
{
  return [CKBackgroundLayoutComponent
          newWithComponent:_quoteComponent
          background:
          [CKComponent
           newWithView:{
             [UIImageView class],
             {
               {@selector(setImage:), _backgroundImage},
               {@selector(setContentMode:), @(UIViewContentModeScaleAspectFill)},
               {@selector(setClipsToBounds:), @YES},
             }
           }
           size:{}]];
}

@end
