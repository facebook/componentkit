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


#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKComponentSize.h>

typedef NS_ENUM(NSUInteger, CKComponentHostingViewWrapperType) {
  CKComponentHostingViewWrapperTypeNone,
  CKComponentHostingViewWrapperTypeFlexbox,
  CKComponentHostingViewWrapperTypeTestComponent,
  CKComponentHostingViewWrapperTypeRenderComponent,
  CKComponentHostingViewWrapperTypeDeepViewHierarchy,
};

@interface CKComponentHostingViewTestModel : NSObject

- (instancetype)initWithColor:(UIColor *)color
                         size:(const CKComponentSize &)size;

- (instancetype)initWithColor:(UIColor *)color
                         size:(const CKComponentSize &)size
                  wrapperType:(CKComponentHostingViewWrapperType)wrapperType;

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@property (nonatomic, strong, readonly) UIColor *color;
@property (nonatomic, readonly) CKComponentSize size;
@property (nonatomic, readonly) CKComponentHostingViewWrapperType wrapperType;

@end

@class CKComponent;

#ifdef __cplusplus
extern "C" {
#endif

CKComponent *CKComponentWithHostingViewTestModel(CKComponentHostingViewTestModel *model);

#ifdef __cplusplus
}
#endif
