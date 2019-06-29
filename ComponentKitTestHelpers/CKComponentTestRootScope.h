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
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>

/**
 Opens a root component scope when constructing components manually in tests:

   CKComponentTestRootScope scope;
   CKComponent *c = ...;

 In the example above the component test root scope will be made available to the component and all of its children.
 */
class CKComponentTestRootScope {
 public:
  CKComponentTestRootScope()
      : _previousThreadLocalComponentScope(CKThreadLocalComponentScope::currentScope()),
        _threadLocalComponentScope(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}) {
    /*
     The component test root scope must be created outside of any existing component scope.
     If a previous thread local component scope exists then odds are good the component test root scope is being used
     outside of a test.FBSwitchComponentServerSnapshotTests.mm Component test root scopes are intended to only be used by tests, and attempting to use them
     in production code can lead to subtle issues (e.g. dropping component state updates).
     */
     CKCAssert(_previousThreadLocalComponentScope == nullptr,
               @"Unable to create a component test root scope if another component scope is available\n" \
               "This can happen if a component test root scope is created outside of a test, this is not supported");
  };

 private:
  CKThreadLocalComponentScope *_previousThreadLocalComponentScope;
  CKThreadLocalComponentScope _threadLocalComponentScope;
};
