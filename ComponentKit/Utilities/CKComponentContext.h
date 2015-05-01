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

#import <ComponentKit/CKComponentContextImpl.h>

/**
 Provides a way to implicitly pass parameters to child components.

 @warning Contexts should be used sparingly. Prefer explicitly passing parameters instead.
 */
template<typename T>
class CKComponentContext {
public:
  /**
   Puts an object in the context dictionary. Objects are currently keyed by class, meaning you cannot store multiple
   objects of the same class.

   @example CKComponentContext<CKFoo> fooContext(foo);
   */
  CKComponentContext(T *object) : _key([T class])
  {
    CK::Component::Context::store(_key, object);
  }

  /**
   Fetches an object from the context dictionary.

   You may only call this from inside +new. If you want access to something from context later, store it in an ivar.

   @example CKFoo *foo = CKComponentContext<CKFoo>::get();
   */
  static T *get()
  {
    return CK::Component::Context::fetch([T class]);
  }

  CKComponentContext(const CKComponentContext&) = delete;
  CKComponentContext &operator=(const CKComponentContext&) = delete;
  ~CKComponentContext()
  {
    CK::Component::Context::clear(_key);
  }

private:
  const Class _key;
};
