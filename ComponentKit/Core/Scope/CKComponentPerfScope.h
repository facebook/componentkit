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

#import <Foundation/Foundation.h>

@protocol CKSystraceListener;

/**
 This class measures component's creation time.

 The following methods will be called on CKAnalyticsListener:
 - (void)willBuildComponent:(Class)componentClass;
 - (void)didBuildComponent:(Class)componentClass;

 Notes:
 * If your component already has CKComponentScope, please DON'T use this one; it DOES the same under the hood.
 * It only works when systrace is enabled.

 Example usage:
 + (instancetype)newWithModel:(Model *)model
 {
    CKComponentPerfScope perfScope(self);
    return [super newWithComponent:...];
 }
 */
class CKComponentPerfScope {
public:
  /**
   @param componentClass Always pass self.
   */
  CKComponentPerfScope(Class __unsafe_unretained componentClass) noexcept;
  ~CKComponentPerfScope();

private:
  CKComponentPerfScope(const CKComponentPerfScope&) = delete;
  CKComponentPerfScope &operator=(const CKComponentPerfScope&) = delete;
  id<CKSystraceListener> _systraceListener;
  Class _componentClass;
};

#endif
