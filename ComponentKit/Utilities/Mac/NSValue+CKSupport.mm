
#import "NSValue+CKSupport.h"

@implementation NSValue (CKPlatform)

+ (NSValue *)valueWithCGRect:(CGRect)rect
{
  return [self valueWithRect:rect];
}

- (CGRect)CGRectValue
{
  return [self rectValue];
}

@end
