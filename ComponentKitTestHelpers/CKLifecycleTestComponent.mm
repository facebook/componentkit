/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>

#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKFatal.h>

@implementation CKLifecycleTestComponent

+ (Class<CKComponentControllerProtocol>)controllerClass
{
  return [CKLifecycleTestComponentController class];
}

static BOOL _shouldEarlyReturnNew = NO;

auto CKLifecycleTestComponentSetShouldEarlyReturnNew(BOOL shouldEarlyReturnNew) -> void
{
  _shouldEarlyReturnNew = shouldEarlyReturnNew;
}

+ (id)initialState
{
  return @NO;
}

+ (instancetype)new
{
  CKComponentScope scope(self); // components with controllers must have a scope
  if (_shouldEarlyReturnNew) {
    return nil;
  }
  CKViewComponentAttributeValueMap attrs;
  if ([scope.state() boolValue]) {
    attrs.insert({@selector(setBackgroundColor:), [UIColor redColor]});
  }
  return [super newWithView:{[UIView class], std::move(attrs)} size:{}];
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size
{
  CKComponentScope scope(self); // components with controllers must have a scope
  return [super newWithView:view size:size];
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  const auto result = [super computeLayoutThatFits:constrainedSize
                                  restrictedToSize:size
                              relativeToParentSize:parentSize];

  _computeLayoutCount++;
  return result;
}

- (CKLifecycleTestComponentController *)controller
{
  // We provide this convenience method here to avoid having all the casts in the tests above.
  return (CKLifecycleTestComponentController *)[super controller];
}

- (void)updateStateToIncludeNewAttribute
{
  [self updateState:^(id oldState){
    return @YES;
  } mode:CKUpdateModeSynchronous];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  return (sender == self);
}

@end

@implementation CKLifecycleTestComponentController

- (void)didInit
{
  if (![NSThread isMainThread]) {
    CKFatal(@"didInit should only be called on main thread");
  } else if (_calledDidInit) {
    CKFatal(@"didInit should only be called once");
  }

  [super didInit];
  _calledDidInit = YES;
}

- (void)willMount
{
  [super willMount];
  _counts.willMount++;
}

- (void)didMount
{
  [super didMount];
  _counts.didMount++;
}

- (void)willRemount
{
  [super willRemount];
  _counts.willRemount++;
}

- (void)didRemount
{
  [super didRemount];
  _counts.didRemount++;
}

- (void)willUnmount
{
  [super willUnmount];
  _counts.willUnmount++;
}

- (void)didUnmount
{
  [super didUnmount];
  _counts.didUnmount++;
}

- (void)componentDidAcquireView
{
  [super componentDidAcquireView];
  _counts.didAcquireView++;
}

- (void)componentWillRelinquishView
{
  [super componentWillRelinquishView];
  _counts.willRelinquishView++;
}

- (void)componentTreeWillAppear
{
  [super componentTreeWillAppear];
  _calledComponentTreeWillAppear = YES;
}

- (void)componentTreeDidDisappear
{
  [super componentTreeDidDisappear];
  _calledComponentTreeDidDisappear = YES;
}

- (void)willUpdateComponent
{
  [super willUpdateComponent];
  _calledWillUpdateComponent = YES;
}

- (void)didUpdateComponent
{
  [super didUpdateComponent];
  _calledDidUpdateComponent = YES;
}

- (void)invalidateController
{
  if (![NSThread isMainThread]) {
    CKFatal(@"InvalidateController should only be called on main thread");
  } else if (_calledInvalidateController) {
    CKFatal(@"InvalidateController should only be called once");
  }
  [super invalidateController];
  _calledInvalidateController = YES;
}

- (void)didPrepareLayout:(const CKComponentLayout &)layout forComponent:(CKComponent *)component
{
  CKAssertMainThread();
  _calledDidPrepareLayoutForComponent = YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  return YES;
}

@end

@implementation CKRenderLifecycleTestComponent

- (CKComponent *)render:(id)state
{
  _isRenderFunctionCalled = YES;
  return [CKLifecycleTestComponent newWithView:{} size:{}];
}

- (BOOL)shouldComponentUpdate:(id<CKRenderComponentProtocol>)component
{
  return NO;
}

@end
