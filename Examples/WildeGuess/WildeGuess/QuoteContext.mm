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

#import "QuoteContext.h"

@implementation QuoteContext
{
  NSDictionary<NSString *, UIImage *> *_images;
}

- (instancetype)initWithImageNames:(NSSet<NSString *> *)imageNames
{
  if (self = [super init]) {
    _images = loadImages(imageNames);
  }
  return self;
}

- (UIImage *)imageNamed:(NSString *)imageName
{
  return _images[imageName];
}

static NSDictionary<NSString *, UIImage *> *loadImages(NSSet *imageNames)
{
  NSMutableDictionary<NSString *, UIImage *> *imageDictionary = [NSMutableDictionary new];
  for (NSString *imageName in imageNames) {
    UIImage *image = [UIImage imageNamed:imageName];
    if (image) {
      imageDictionary[imageName] = image;
    }
  }
  return imageDictionary;
}

@end
