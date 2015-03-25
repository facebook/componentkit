/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentSnapshotTestCase.h"

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentLifecycleManager.h>
#import <ComponentKit/CKComponentLifecycleManagerInternal.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentSubclass.h>

static CKComponent *(^_componentBlock)();
static CKComponent *_leakyComponent;

@interface CKComponentSnapshotTestCase () <CKComponentProvider>

@end

@implementation CKComponentSnapshotTestCase

- (BOOL)compareSnapshotOfComponent:(CKComponent *)component
                         sizeRange:(CKSizeRange)sizeRange
          referenceImagesDirectory:(NSString *)referenceImagesDirectory
                        identifier:(NSString *)identifier
                             error:(NSError **)errorPtr
{
  CKComponentLayout spec = [component layoutThatFits:sizeRange parentSize:sizeRange.max];
  CKComponentLifecycleManager *m = [[CKComponentLifecycleManager alloc] init];
  [m updateWithState:(CKComponentLifecycleManagerState){.layout = spec}];
  UIView *v = [[UIView alloc] initWithFrame:{{0,0}, spec.size}];
  [m attachToView:v];
  return [self compareSnapshotOfView:v
            referenceImagesDirectory:referenceImagesDirectory
                          identifier:identifier
                               error:errorPtr];
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  _leakyComponent = _componentBlock();
  return _leakyComponent;
}

- (BOOL)compareSnapshotOfComponentBlock:(CKComponent *(^)())componentBlock
                       updateStateBlock:(id (^)(id))updateStackBlock
                              sizeRange:(CKSizeRange)sizeRange
               referenceImagesDirectory:(NSString *)referenceImagesDirectory
                             identifier:(NSString *)identifier
                                  error:(NSError **)errorPtr;
{
  _componentBlock = componentBlock;

  CKComponentLifecycleManager *lifecycleManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [lifecycleManager updateWithState:[lifecycleManager prepareForUpdateWithModel:nil constrainedSize:sizeRange]];
  [_leakyComponent updateState:updateStackBlock];

  return [self compareSnapshotOfComponent:[lifecycleManager state].layout.component
                                sizeRange:sizeRange
                 referenceImagesDirectory:referenceImagesDirectory
                               identifier:identifier
                                    error:errorPtr];
}

@end
