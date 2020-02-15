/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#include <functional>

#import <Foundation/Foundation.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKMountable.h>
#import <ComponentKit/CKLayout.h>

@protocol CKMountable;
@protocol CKRenderComponentProtocol;

/**
 This protocol is being used by the infrastructure to collect data into systrace if enabled.
 */
@protocol CKSystraceListener <CKMountLayoutListener>

/**
 Start of the block that will start on one thread and end on another

 @return completion block that will be called after the switch to different queue
 */
- (std::function<void(void)>)willStartAsyncBlockTrace:(const char *const)blockName;
- (void)didEndAsyncBlockTrace:(const char *const)blockName;

/**
 Start/End a block trace in systrace.
 */
- (void)willStartBlockTrace:(const char *const)blockName;
- (void)didEndBlockTrace:(const char *const)blockName;

/**
 Called before/after building a scoped component.

 Will be called only when systrace is enabled.
 */
- (void)willBuildComponent:(Class)componentClass;
- (void)didBuildComponent:(Class)componentClass;

/**
 Called before/after layout a component.

 Will be called only when systrace is enabled.
 */
- (void)willLayoutComponent:(id<CKMountable>)component;
- (void)didLayoutComponent:(id<CKMountable>)component;

/**
  Called before/after evaluating a component should be updated or not.

  Will be called only when systrace is enabled.
*/
- (void)willCheckShouldComponentUpdate:(id<CKRenderComponentProtocol>)component;
- (void)didCheckShouldComponentUpdate:(id<CKRenderComponentProtocol>)component;

@end

#endif
