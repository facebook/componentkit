/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentController.h>

struct CKLifecycleMethodCounts {
  NSUInteger willMount;
  NSUInteger didMount;
  NSUInteger willRemount;
  NSUInteger didRemount;
  NSUInteger willUnmount;
  NSUInteger didUnmount;
  
  NSString *description() const
  {
    return [NSString stringWithFormat:@"willMount:%lu didMount:%lu willRemount:%lu didRemount:%lu willUnmount:%lu didUnmount:%lu",
            (unsigned long)willMount, (unsigned long)didMount, (unsigned long)willRemount,
            (unsigned long)didRemount, (unsigned long)willUnmount, (unsigned long)didUnmount];
  }
  
  bool operator==(const CKLifecycleMethodCounts &other) const
  {
    return willMount == other.willMount && didMount == other.didMount
    && willRemount == other.willRemount && didRemount == other.didRemount
    && willUnmount == other.willUnmount && didUnmount == other.didUnmount;
  }
};

@interface CKLifecycleTestComponentController : CKComponentController
@property (nonatomic, assign) BOOL calledDidAcquireView;
@property (nonatomic, assign) BOOL calledWillRelinquishView;
@property (nonatomic, assign) BOOL calledComponentTreeWillAppear;
@property (nonatomic, assign) BOOL calledComponentTreeDidDisappear;
@property (nonatomic, assign) BOOL calledDidUpdateComponent;
@property (nonatomic, assign) BOOL calledInvalidateController;
@property (nonatomic, assign) BOOL calledDidPrepareLayoutForComponent;
@property (nonatomic, assign) CKLifecycleMethodCounts counts;
@end

@interface CKLifecycleTestComponent : CKComponent
+ (void)setShouldEarlyReturnNew:(BOOL)shouldEarlyReturnNew;
- (CKLifecycleTestComponentController *)controller;
- (void)updateStateToIncludeNewAttribute;
@end
