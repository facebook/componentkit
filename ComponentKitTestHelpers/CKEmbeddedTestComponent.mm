// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKEmbeddedTestComponent.h"

#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>

@interface CKEmbeddedTestComponent()
{
  CKLifecycleTestComponent *_lifecycleTestComponent;
}
@end

@implementation CKEmbeddedTestComponent

+ (id)initialState
{
  return @NO;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size
{
  CKComponentScope scope(self);
  const BOOL isLifecycleTestComponentHidden = [scope.state() boolValue];
  
  auto const lifecycleTestComponent = isLifecycleTestComponentHidden ? nil : [CKLifecycleTestComponent newWithView:view size:size];
  auto const innerComponent = lifecycleTestComponent ?: CK::ComponentBuilder()
                                                            .size(size)
                                                            .build();
  
  auto const c = [super newWithView:view component:innerComponent];
  if (c && lifecycleTestComponent) {
    c->_lifecycleTestComponent = lifecycleTestComponent;
  }
  return c;
}

- (void)setLifecycleTestComponentIsHidden:(BOOL)isHidden
{
  [self updateState:^(id oldState){
    return @(isHidden);
  } mode:CKUpdateModeSynchronous];
}

- (CKLifecycleTestComponent *)lifecycleTestComponent
{
  return _lifecycleTestComponent;
}

@end
