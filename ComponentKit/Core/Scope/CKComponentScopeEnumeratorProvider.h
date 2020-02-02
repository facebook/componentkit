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

#import <ComponentKit/CKComponentScopeTypes.h>

@protocol CKComponentScopeEnumeratorProvider <NSObject>

/**
 Allows rapid enumeration over the components or controllers that matched a predicate. The predicate should be provided
 in the initializer of the scope root in order to reduce the runtime costs of the enumeration.

 There is no guaranteed ordering of arguments that are provided to the enumerators.
 */
- (void)enumerateComponentsMatchingPredicate:(CKComponentPredicate)predicate
                                       block:(CKComponentScopeEnumerator)block;

- (void)enumerateComponentControllersMatchingPredicate:(CKComponentControllerPredicate)predicate
                                                 block:(CKComponentControllerScopeEnumerator)block;

@end

#endif
