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

#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>

/**
 Opens a root component scope when constructing components manually in tests:

   CKComponentTestRootScope scope;
   CKComponent *c = ...;

 In the example above the test root scope will be made available to the component and all of its children.
 */
class CKComponentTestRootScope {
public:
  CKComponentTestRootScope() : _threadScope([CKComponentScopeRoot rootWithListener:nil], {}) {};
private:
  CKThreadLocalComponentScope _threadScope;
};
