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

typedef id (^CKComponentWillRemountAnimationBlock)(void);
typedef id (^CKComponentDidRemountAnimationBlock)(id context);
typedef void (^CKComponentCleanupAnimationBlock)(id context);

using CKComponentAnimationCompletion = void (^)();

struct CKComponentAnimationHooks {
  /**
   Corresponds to [CKComponentController -willRemountComponent]. The old component and its children are still mounted.
   Example uses of this hook include computing a fromValue for use in didRemount or creating a snapshotView from a
   component that will be unmounted.
   Returns A context object that will be passed to didRemount.
   */
  CKComponentWillRemountAnimationBlock willRemount;

  /**
   Corresponds to [CKComponentController -didRemountComponent]. The new component and its children are now mounted.
   Old components may or may not still be mounted; if they are mounted, they will be unmounted shortly.
   Receives the context returned by the willRemount block.
   Returns A context object that will be passed to cleanup.
   */
  CKComponentDidRemountAnimationBlock didRemount;

  /**
   Corresponds to [CKComponentController -willUnmount] *and* [CKComponentController -componentWillRelinquishView].
   Perform any cleanup, e.g. removing animations from layers. Note that any number of remounting and view
   recycling operations may have occurred since didRemount was called, including subsequent animations that may even be
   animating the same property! You should pass any views in as part of the context object instead of accessing them
   via a component instance.
   Receives the context returned by the didRemount block.
   */
  CKComponentCleanupAnimationBlock cleanup;

  auto byAddingCompletion(CKComponentAnimationCompletion c) const -> CKComponentAnimationHooks
  {
    if (c == nil) { return *this; }
    // Make sure we're not capturing `this` (which is not managed by ARC)
    auto const origCleanup = cleanup;

    void (^block)(id) = ^(id ctx){
      if (auto _cleanup = origCleanup) { _cleanup(ctx); };
      c();
    };

    return {
      willRemount,
      didRemount,
      [block copy]
    };
  }
};

#endif
