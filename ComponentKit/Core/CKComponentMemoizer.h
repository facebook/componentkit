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

#import <ComponentKit/CKComponentContext.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKSizeRange.h>
#import <ComponentKit/CKComponentSize.h>
#import <ComponentKit/CKEqualityHashHelpers.h>

#include <functional>

// Aspect-oriented type erasure of hash/equals on a tuple
struct CKMemoizationKey;

id CKMemoize(CKMemoizationKey memoizationKey, id (^block)(void));

/**
 
 How to use the component memoization:
 
 + (instancetype)newWithMyModel:(MyModel *)model otherInput:(int)other
 {
   return CKMemoize(CKMakeTupleMemoizationKey(model, other), ^{
     return [self
            newWithComponent:
            [CKStackLayoutComponent
              newWith...
   });
 
 }
 
 MyKey must consist only of objects that define -hash and -isEqual:.

 If you're building something that calls CKMountComponentLayout() directly,
 just add a CKComponentMemoizer in the right scope:

 {
   CKComponentMemoizer memoizer(_memoizerState);
 
   result = CKBuildComponent(...)
 
   layout = [result.component layoutThatFits:constrainedSize parentSize:constrainedSize.max]
 
    ...
   CKMountComponentLayout(layout)

   _memoizerState = memoizer.nextMemoizerState();

 }
 
 How to use component layout memoization:
 
 - (BOOL)shouldMemoizeLayout
 {
   return YES;
 }
 
 Calls to -layoutThatFits:constrainedSize: will then be transparently memoized across re-layouts
 for a given component instance, constrained size, and parent size.

 */
struct CKComponentMemoizer {

  /**
   Create a memoizer with the provided layout. Will make memoized components available to CKMemoize().
   
   This object must remain in scope for objects to be vended, however.
   */
  CKComponentMemoizer(id previousMemoizerState);

  /**
   Destructor cleans up the intermediate state for the memoizer.
   */
  ~CKComponentMemoizer();

  /**
   Store this state across rebuilding components.
   Do not use this object from multiple threads simultaneously!!
   */
  id nextMemoizerState();

private:
  id previousMemoizer_;
};

struct CKMemoizationKey
{
  size_t hash;

  // This is a shared_ptr to const void* so we can have value semantics (just increment refcount),
  // but use our own equals fn, etc
  std::shared_ptr<const void> internal;

  // This key's quality function
  bool (*equals)(const void *, const void *);

  bool operator == (const CKMemoizationKey other) const {
    // Two keys are the same type if their equality functions are the same
    return equals == other.equals
    // The keys are equal if the equality function returns true
    && (internal == other.internal || equals(internal.get(), other.internal.get()));
  };
};

template <typename ...Types, typename Pred = CKTupleOperations::equal_to<std::tuple<Types...>> >
CKMemoizationKey CKMakeTupleMemoizationKey(Types... args) {
  using Tuple = std::tuple<Types...>;

  Tuple *tuple = new Tuple(std::forward_as_tuple(args...));
  size_t hash = CKTupleOperations::hash<Tuple>()(*tuple);

  return {
    .hash = hash,
    .internal = std::shared_ptr<const void>(tuple, [](const void *ptr) {
      delete static_cast<const Tuple *>(ptr);
    }),
    .equals = [](const void* a, const void* b) {
      if (!a || !b) {
        return false;
      }
      const Tuple* aa = static_cast<const Tuple*>(a);
      const Tuple* bb = static_cast<const Tuple*>(b);
      return Pred()(*aa, *bb);
    },
  };

  return CKMemoizationKey{};
};

