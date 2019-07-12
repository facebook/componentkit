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

#import <ComponentKit/CKComponentLayout.h>

NSString *CKComponentBacktraceDescription(NSArray<CKComponent *> *componentBacktrace) noexcept;
NSString *CKComponentBacktraceStackDescription(NSArray<CKComponent *> *componentBacktrace) noexcept;

NSString *CKComponentChildrenDescription(std::shared_ptr<const std::vector<CKComponentLayoutChild>> children) noexcept;

__BEGIN_DECLS

extern NSString *CKComponentDescriptionWithChildren(NSString *description, NSArray *children);

__END_DECLS
