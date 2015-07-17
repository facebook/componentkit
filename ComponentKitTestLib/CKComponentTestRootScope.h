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

#import <ComponentKit/CKThreadLocalComponentScope.h>

/**
 If you are constructing components manually in a test without using CKComponentLifecycleManager, you must wrap their
 creation in CKComponentTestRootScope. For example:

   CKComponentTestRootScope scope;
   CKComponent *c = ...;
 */
class CKComponentTestRootScope {
public:
  CKComponentTestRootScope() : _threadScope(nil, nullptr) {};
private:
  CKThreadLocalComponentScope _threadScope;
};
