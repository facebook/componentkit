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

#import <ComponentKit/ComponentKit.h>

@class QuoteContext;

/**
 A monochrome quote component creates a left-aligned transucent white box on which it places a small bookmark-like gray
 box and the quote, horizontally stacked. This is placed on top of a monochrome background.
 */
@interface MonochromeQuoteComponent : CKCompositeComponent

+ (instancetype)newWithText:(NSString *)text context:(QuoteContext *)context;

@end
