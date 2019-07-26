/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>
#import <ComponentKit/CKComponent.h>

/**
 This protocol is being used by the infrastructure to collect data into systrace if enabled.
 */
@protocol CKSystraceListener <NSObject>

/**
 Start/End a block trace in systrace.
 */
- (void)willStartBlockTrace:(const char *const)blockName;
- (void)didStartBlockTrace:(const char *const)blockName;

/**
 Called before/after building a scoped component.

 Will be called only when systrace is enabled.
 */
- (void)willBuildComponent:(Class)componentClass;
- (void)didBuildComponent:(Class)componentClass;

/**
 Called before/after mounting a component.

 Will be called only when systrace is enabled.
 */
- (void)willMountComponent:(CKComponent *)component;
- (void)didMountComponent:(CKComponent *)component;

/**
 Called before/after layout a component.

 Will be called only when systrace is enabled.
 */
- (void)willLayoutComponent:(CKComponent *)component;
- (void)didLayoutComponent:(CKComponent *)component;

/**
  Called before/after evaluating a component should be updated or not.

  Will be called only when systrace is enabled.
*/
- (void)willCheckShouldComponentUpdate:(CKComponent *)component;
- (void)didCheckShouldComponentUpdate:(CKComponent *)component;

@end
