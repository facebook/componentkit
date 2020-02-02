/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

#import <RenderCore/CKLayout.h>

@protocol CKMountable;

/* This functions prints only the class, or in case of Stateless component, the description that will help us identify the Spec */
NSString *CKComponentCompactDescription(id<CKMountable> component);
NSString *CKComponentBacktraceDescription(NSArray<id<CKMountable>> *componentBacktrace) noexcept;
NSString *CKComponentBacktraceStackDescription(NSArray<id<CKMountable>> *componentBacktrace) noexcept;

NSString *CKComponentChildrenDescription(std::shared_ptr<const std::vector<CKComponentLayoutChild>> children) noexcept;
NSArray<id<CKMountable>> *CKComponentGenerateBacktrace(id<CKMountable> component);

__BEGIN_DECLS

extern NSString *CKComponentDescriptionWithChildren(NSString *description, NSArray *children);

__END_DECLS

#endif
