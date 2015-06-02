
#import "CKPlatform.h"

@interface NSValue (CKPlatform)

+ (NSValue *)valueWithCGRect:(CGRect)rect;

- (CGRect)CGRectValue;

@end
