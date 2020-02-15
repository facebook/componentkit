// Copyright 2004-present Facebook. All Rights Reserved.

#import <ComponentKit/CKCompositeComponent.h>

@class CKLifecycleTestComponent;

/** A component that either has a LifecycleTestComponent embedded in it or a dummy CKComponent.
    This can be used to test what happens when state changes and the LifecycleTestComponent is removed.
    Call setLifecycleTestComponentIsHidden to trigger the corresponding state change. */
@interface CKEmbeddedTestComponent : CKCompositeComponent

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size;

- (void)setLifecycleTestComponentIsHidden:(BOOL)isHidden;
- (CKLifecycleTestComponent *)lifecycleTestComponent;

@end
