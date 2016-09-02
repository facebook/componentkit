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

#import <ComponentKit/CKComponentContextHelper.h>

/**
 Provides a way to implicitly pass parameters to child components. Items are keyed by class. Example usage:

 {
   CKComponentContext<CKFoo> c(foo);
   // Any components created while c is in scope will be able to read its value
   // by calling CKComponentContext<CKFoo>::get().
 }

 You may nest contexts with the same class, in which case the innermost context defines the value when fetched:

 {
   CKComponentContext<CKFoo> c1(foo1);
   {
     CKComponentContext<CKFoo> c2(foo2);
     // CKComponentContext<CKFoo>::get() will return foo2 here
   }
   // CKComponentContext<CKFoo>::get() will return foo1 here
 }

 @warning Context should be used sparingly. Prefer explicitly passing parameters instead.
 */
template<typename T>
class CKComponentContext {
public:
  /**
   Fetches an object from the context dictionary.
   You may only call this from inside +new. If you want access to something from context later, store it in an ivar.
   @example CKFoo *foo = CKComponentContext<CKFoo>::get();
   */
  static T *get() { return CKComponentContextHelper::fetch([T class]); }

  CKComponentContext(T *object) : _previousState(CKComponentContextHelper::store([T class], object)) {}
  ~CKComponentContext() { CKComponentContextHelper::restore(_previousState); }

private:
  const CKComponentContextPreviousState _previousState;

  CKComponentContext(const CKComponentContext&) = delete;
  CKComponentContext &operator=(const CKComponentContext&) = delete;
};
