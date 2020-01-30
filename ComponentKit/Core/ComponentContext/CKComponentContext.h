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

#import <ComponentKit/CKComponentContextHelper.h>

/**
 Provides a way to implicitly pass parameters to child components. Items are keyed by class.

 CKComponentContext values are NOT expected to change between component generations. This is an optimization to allow better component reuse.
 If your context values need to be changed between component generations, take a look on CKComponentMutableContext.

 Using CKComponentMutableContext can affect component reuse, which could make components' creation slower.
 By using CKComponentContext, the infrasturctue can reuse components safley and make the component creation faster.
 Unless your component context value is expeted to change, you should ALWAYS use CKComponentContext.

 Example usage:

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

/**
 Similar to CKComponentContext, but allows context values **changes** between generations. This could affect perf.

 Provides a way to implicitly pass parameters to child components. Items are keyed by class.

 Example usage:

 {
   CKComponentMutableContext<CKFoo> c(foo);
   // Any components created while c is in scope will be able to read its value
   // by calling CKComponentMutableContext<CKFoo>::get().
 }

 You may nest contexts with the same class, in which case the innermost context defines the value when fetched:

 {
   CKComponentMutableContext<CKFoo> c1(foo1);
   {
     CKComponentMutableContext<CKFoo> c2(foo2);
     // CKComponentMutableContext<CKFoo>::get() will return foo2 here
   }
   // CKComponentMutableContext<CKFoo>::get() will return foo1 here
 }

 @warning Context should be used sparingly. Prefer explicitly passing parameters instead.
 @warning If you have to use context, consider using CKComponentContext instead. CKComponentMutableContext makes component reuse more difficult.
 */
template<typename T>
class CKComponentMutableContext {
public:
  /**
   Fetches an object from the context dictionary.
   You may only call this from inside +new. If you want access to something from context later, store it in an ivar.
   @example CKFoo *foo = CKComponentMutableContext<CKFoo>::get();
   */
  static T *get() { return CKComponentContextHelper::fetchMutable([T class]); }

  CKComponentMutableContext(T *object) : _previousState(CKComponentContextHelper::store([T class], object)) {}
  ~CKComponentMutableContext() { CKComponentContextHelper::restore(_previousState); }

private:
  const CKComponentContextPreviousState _previousState;

  CKComponentMutableContext(const CKComponentMutableContext&) = delete;
  CKComponentMutableContext &operator=(const CKComponentMutableContext&) = delete;
};

#endif
