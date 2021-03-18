/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>


#import <ComponentKit/CKDefines.h>
#import <ComponentKit/RCComponentSize.h>

typedef NS_ENUM(NSUInteger, CKComponentHostingViewWrapperType) {
  CKComponentHostingViewWrapperTypeNone,
  CKComponentHostingViewWrapperTypeFlexbox,
  CKComponentHostingViewWrapperTypeTestComponent,
  CKComponentHostingViewWrapperTypeRenderComponent,
  CKComponentHostingViewWrapperTypeDeepViewHierarchy,
};

@interface CKComponentHostingViewTestModel : NSObject

CK_INIT_UNAVAILABLE;

- (instancetype)initWithColor:(UIColor *)color
                         size:(const RCComponentSize &)size;

- (instancetype)initWithColor:(UIColor *)color
                         size:(const RCComponentSize &)size
                  wrapperType:(CKComponentHostingViewWrapperType)wrapperType
        willGenerateComponent:(void(^)())willGenerateComponent NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) UIColor *color;
@property (nonatomic, readonly) RCComponentSize size;
@property (nonatomic, readonly) CKComponentHostingViewWrapperType wrapperType;
@property (nonatomic, copy, readonly) void(^willGenerateComponent)();

@end

@class CKComponent;

CK_EXTERN_C_BEGIN

CKComponent *CKComponentWithHostingViewTestModel(CKComponentHostingViewTestModel *model);

CK_EXTERN_C_END
