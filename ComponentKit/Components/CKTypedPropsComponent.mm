//
//  CKTypedPropsComponent.m
//  ComponentKit
//
//  Created by Oliver Rickard on 11/22/16.
//
//

#import "CKTypedPropsComponent.h"

#import "CKInternalHelpers.h"
#import "CKTypedPropsComponentSubclass.h"
#import "CKComponentSubclass.h"
#import "CKComponentInternal.h"

@implementation CKTypedPropsComponent
{
  CKComponent *_child;
}

#if DEBUG
+ (void)initialize
{
  if (self != [CKCompositeComponent class]) {
    CKAssert(!CKSubclassOverridesSelector([CKTypedPropsComponent class], self, @selector(newWithView:size:)),
             @"%@ overrides -newWithView:size: which is not allowed. "
             "Consider subclassing CKComponent or CKCompositeComponent directly.",
             self);
    CKAssert(!CKSubclassOverridesSelector([CKTypedPropsComponent class], self, @selector(newWithPropsStruct:view:size:)),
             @"%@ overrides -newWithProps:view:size: which is not allowed. "
             "Instead, you should implement renderWithProps:state:view:size:.",
             self);
  }
}
#endif

+ (instancetype)newWithPropsStruct:(const CKTypedComponentStruct &)props
                              view:(const CKComponentViewConfiguration &)view
                              size:(const CKComponentSize &)size
{
  CKComponentScope scope(self);
  CKTypedPropsComponent *c = [super newWithView:view size:size];
  if (c) {
    c->_props = props;
    c->_state = scope.state();
    c->_child = [self renderWithPropsStruct:props
                                      state:c->_state
                                       view:view
                                       size:size];
  }
  return c;
}

+ (CKComponent *)renderWithPropsStruct:(const CKTypedComponentStruct &)props
                                 state:(id)state
                                  view:(const CKComponentViewConfiguration &)view
                                  size:(const CKComponentSize &)size
{
  return nil;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKComponentLayout l = [_child layoutThatFits:constrainedSize parentSize:parentSize];
  return {self, l.size, {{{0,0}, l}}};
}

- (UIView *)viewForAnimation
{
  // Delegate to the wrapped component's viewForAnimation if we don't have one.
  return [super viewForAnimation] ?: [_child viewForAnimation];
}

@end
