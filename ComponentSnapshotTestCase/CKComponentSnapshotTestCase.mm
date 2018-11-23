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

#import <ComponentKitTestHelpers/CKComponentLifecycleTestHelper.h>

#import <ComponentKit/CKComponent.h>
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
  const CKComponentLayout componentLayout = [component layoutThatFits:sizeRange parentSize:sizeRange.max];
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nil
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController updateWithState:(CKComponentLifecycleTestHelperState){
    .componentLayout = componentLayout
  }];
  UIView *view = [[UIView alloc] initWithFrame:{{0,0}, componentLayout.size}];
  [componentLifecycleTestController attachToView:view];
  return [self compareSnapshotOfView:view
            referenceImagesDirectory:referenceImagesDirectory
                  imageDiffDirectory:[self getImageDiffDirectoryWithDefault:@IMAGE_DIFF_DIR]
                          identifier:identifier
                           tolerance:self.tolerance
                               error:errorPtr];
}

- (BOOL)compareSnapshotOfComponentBlock:(CKComponent *(^)())componentBlock
                       updateStateBlock:(id (^)(id))updateStackBlock
                              sizeRange:(CKSizeRange)sizeRange
               referenceImagesDirectory:(NSString *)referenceImagesDirectory
                             identifier:(NSString *)identifier
                                  error:(NSError **)errorPtr;
{
  _componentBlock = componentBlock;
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController updateWithState:[componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                constrainedSize:sizeRange
                                                                                                        context:nil]];
  [_leakyComponent updateState:updateStackBlock mode:CKUpdateModeSynchronous];
  return [self compareSnapshotOfComponent:[componentLifecycleTestController state].componentLayout.component
                                sizeRange:sizeRange
                 referenceImagesDirectory:referenceImagesDirectory
                               identifier:identifier
                                    error:errorPtr];
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  _leakyComponent = _componentBlock();
  return _leakyComponent;
}

@end
