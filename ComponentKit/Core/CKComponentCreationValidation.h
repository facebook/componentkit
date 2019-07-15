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

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKComponentContext.h>

#if CK_ASSERTIONS_ENABLED
/**
 This is used for assertion if component is created outside of component provider function.
 */
@interface CKComponentCreationValidationContext : NSObject
@end

BOOL CKIsRunningInTest();

#define CKValidateComponentCreation() \
  if (!CKIsRunningInTest()) { \
    CKWarnWithCategory(CKComponentContext<CKComponentCreationValidationContext>::get() != nil, \
                       NSStringFromClass(self.class), \
                       @"Component should not be created outside of component provider function."); \
  }
#else
#define CKValidateComponentCreation()
#endif
