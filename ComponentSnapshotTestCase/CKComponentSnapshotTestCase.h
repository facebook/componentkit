/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDimension.h>
#import <ComponentKit/CKInsetComponent.h>
#import <ComponentKit/CKAvailability.h>

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

#if __LP64__
#define CK_64 1
#else
#define CK_64 0
#endif

/**
 Maps platform to reference image directory suffix
 */
#define CKSnapshotReferenceDirectorySuffix() \
({ \
NSString *suffix = \
CK_AT_LEAST_IOS12 ? @"_IOS12" : \
CK_AT_LEAST_IOS11_3 ? @"_IOS11_3" : \
CK_AT_LEAST_IOS11 ? @"_IOS11" : \
CK_AT_LEAST_IOS10_BETA_4 ? @"_IOS10" : \
@""; \
CK_64 ? [suffix stringByAppendingString:@"_64"] : suffix; \
})

@class CKComponent;

/**
 Similar to our much-loved XCTAssert() macros. Use this to perform your test. No need to write an explanation, though.
 @param component The component to snapshot
 @param sizeRange An CKSizeRange specifying the size the component should be mounted at
 @param identifier An optional identifier, used if there are multiple snapshot tests in a given -test method.
 */
#define CKSnapshotVerifyComponent(component__, sizeRange__, identifier__) \
{ \
NSError *error__ = nil; \
NSString *referenceImagesDirectory__ = [NSString stringWithFormat:@"%@%@", [self getReferenceImageDirectoryWithDefault:(@ FB_REFERENCE_IMAGE_DIR)], CKSnapshotReferenceDirectorySuffix()]; \
BOOL comparisonSuccess__ = [self compareSnapshotOfComponent:(component__) sizeRange:(sizeRange__) referenceImagesDirectory:referenceImagesDirectory__ identifier:(identifier__) error:&error__]; \
XCTAssertTrue(comparisonSuccess__, @"Snapshot comparison failed: %@", error__); \
}

/**
 A convenience macro for snapshotting a component with some additional insets so that borders/shadows can be captured.
 @param component The component to snapshot
 @param sizeRange An CKSizeRange specifying the size the component should be mounted at
 @param insets A UIEdgeInsets struct to specify the insets around the component being snapshotted.
 @param identifier An optional identifier, used if there are multiple snapshot tests in a given -test method.
 */
#define CKSnapshotVerifyComponentWithInsets(component__, sizeRange__, insets__, identifier__) \
{ \
CKSnapshotVerifyComponent([CKInsetComponent newWithInsets:insets__ component:component__], sizeRange__, identifier__) \
}

/**
 Similar CKSnapshotVerifyComponent except it allows you to test a component with a particular state (i.e. CKComponentScope state).
 Rather than passing in a component, pass in a block that returns a component. Also, pass in a block that returns state.
 You need to pass in a block rather than just a component because the lifecycle manager creates a scope, and we need to defer
 creation of that component until after that scope exists.
 @param componentBlock A block that returns a component to snapshot
 @param updateStateBlock An update state block for the component. Returns the state you want the component to be tested with.
 @param sizeRange An CKSizeRange specifying the size the component should be mounted at
 @param identifier An optional identifier, used if there are multiple snapshot tests in a given -test method.
 */
#define CKSnapshotVerifyComponentBlockWithState(componentBlock__, updateStateBlock__, sizeRange__, identifier__) \
{ \
NSError *error__ = nil; \
NSString *referenceImagesDirectory__ = [NSString stringWithFormat:@"%@%@", [self getReferenceImageDirectoryWithDefault:(@ FB_REFERENCE_IMAGE_DIR)], CKSnapshotReferenceDirectorySuffix()]; \
BOOL comparisonSuccess__ = [self compareSnapshotOfComponentBlock:(componentBlock__) updateStateBlock:(updateStateBlock__) sizeRange:(sizeRange__) referenceImagesDirectory:referenceImagesDirectory__ identifier:(identifier__) error:&error__]; \
XCTAssertTrue(comparisonSuccess__, @"Snapshot comparison failed: %@", error__); \
}

@interface CKComponentSnapshotTestCase : FBSnapshotTestCase

/**
 The percentage difference to still count as identical - 0 mean pixel perfect, 1 means I don't care
 */
@property (readwrite, nonatomic, assign) CGFloat tolerance;

/**
 Performs the comparison or records a snapshot of the view if recordMode is YES.
 @param component The component to snapshot
 @param referenceImagesDirectory The directory in which reference images are stored.
 @param identifier An optional identifier, used is there are muliptle snapshot tests in a given -test method.
 @param error An error to log in an XCTAssert() macro if the method fails (missing reference image, images differ, etc).
 @returns YES if the comparison (or saving of the reference image) succeeded.
 */
- (BOOL)compareSnapshotOfComponent:(CKComponent *)component
                         sizeRange:(CKSizeRange)sizeRange
          referenceImagesDirectory:(NSString *)referenceImagesDirectory
                        identifier:(NSString *)identifier
                             error:(NSError **)errorPtr;

/**
 Performs the comparison or records a snapshot of the view if recordMode is YES.
 Allows you to test a component with a particular state (i.e. CKComponentScope state).
 @param componentBlock A block that returns a component to snapshot
 @param updateStateBlock An update state block for the component. Returns the state you want the component to be tested with.
 @param referenceImagesDirectory The directory in which reference images are stored.
 @param identifier An optional identifier, used is there are muliptle snapshot tests in a given -test method.
 @param error An error to log in an XCTAssert() macro if the method fails (missing reference image, images differ, etc).
 @returns YES if the comparison (or saving of the reference image) succeeded.
 */
- (BOOL)compareSnapshotOfComponentBlock:(CKComponent *(^)())componentBlock
                       updateStateBlock:(id (^)(id))updateStackBlock
                              sizeRange:(CKSizeRange)sizeRange
               referenceImagesDirectory:(NSString *)referenceImagesDirectory
                             identifier:(NSString *)identifier
                                  error:(NSError **)errorPtr;

@end
