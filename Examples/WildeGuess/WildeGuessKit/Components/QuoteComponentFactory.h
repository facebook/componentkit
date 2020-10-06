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

#import <ComponentKit/CKDefines.h>
#import <ComponentKit/CKComponent.h>

@class CKComponent;
@class Quote;
@class QuoteContext;

NS_ASSUME_NONNULL_BEGIN

CK_EXTERN_C_BEGIN

CKComponent *QuoteComponentFactory(Quote *quote, QuoteContext *context);

CK_EXTERN_C_END

NS_ASSUME_NONNULL_END
