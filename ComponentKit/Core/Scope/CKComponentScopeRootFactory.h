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

@protocol CKComponentStateListener;

@class CKComponentScopeRoot;

/**
 Initializes a CKComponentScopeRoot with the normal, infrastructure-provided predicates necessary for the framework
 to work. You should use this function to create scope roots unless you really know what you're doing.
 */
CKComponentScopeRoot *CKComponentScopeRootWithDefaultPredicates(id<CKComponentStateListener> listener);
