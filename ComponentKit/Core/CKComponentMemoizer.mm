/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentMemoizer.h"

#import "CKCollection.h"
#import "CKComponentInternal.h"
#import "CKComponentScopeFrameInternal.h"
#import "CKComponentSubclass.h"
#import "CKMacros.h"
#import "CKInternalHelpers.h"
#import "CKThreadLocalComponentScope.h"

#include <map>

static NSString *CKComponentMemoizerThreadKey = @"CKComponentMemoizer";
static NSString *CKComponentLayoutMemoizerThreadKey = @"CKComponentLayoutMemoizer";

// Define hash as just pulling out the precomputed hash field
namespace std {
  template <>
  struct hash<CKMemoizationKey> {
    size_t operator ()(CKMemoizationKey a) const {
      return a.hash;
    };
  };
}

struct CKLayoutMemoizationKey {
  CKComponent *component;
  CKSizeRange thatFits;
  CGSize parentSize;

  struct Hash {
    size_t operator ()(CKLayoutMemoizationKey a) const {
      NSUInteger subhashes[] = {
        CK::hash<id>()(a.component),
        CK::hash<CKSizeRange>()(a.thatFits),
        CK::hash<CGFloat>()(a.parentSize.width),
        CK::hash<CGFloat>()(a.parentSize.height),
      };
      return CKIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
    };
  };

  struct Equals {
    bool operator ()(CKLayoutMemoizationKey a, CKLayoutMemoizationKey b) const {
      return a.component == b.component
      && a.thatFits == b.thatFits
      && CGSizeEqualToSize(a.parentSize, b.parentSize);
    }
  };
};

@interface CKComponentScopeHandle (ParentCheck)
- (bool)isParentOfOrEqualTo:(CKComponentScopeHandle *)other;
@end

@implementation CKComponentScopeHandle (ParentCheck)
- (bool)isParentOfOrEqualTo:(CKComponentScopeHandle *)other
{
  auto candidate = other;
  while (candidate != nil) {
    if (std::equal_to<CKComponentScopeHandle *>()(candidate, self)) {
      return true;
    }
    candidate = candidate.parent;
  }
  return false;
}
@end

@interface CKComponentMemoizerState : NSObject {
  @package
  // Store into the next state, read from the current
  CKComponentMemoizerState *_next;
  // maps CKMemoizationKey -> any number of CKComponent *
  std::unordered_multimap<CKMemoizationKey, CKComponent *> componentCache_;
}

@end


@implementation CKComponentMemoizerState

static bool currentScopeIsAffectedByPendingStateUpdates()
{
  const auto threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (threadLocalScope == nullptr) {
    return false;
  }

  const auto currentScopeHandle = threadLocalScope->stack.top().frame.handle;
  const auto updates = threadLocalScope->stateUpdates;
  const auto currentScopeOrDescendantHasStateUpdate = CK::Collection::containsWhere(updates, [=](const auto &pair){
    return [currentScopeHandle isParentOfOrEqualTo:pair.first];
  });

  return currentScopeOrDescendantHasStateUpdate;
}

- (CKComponent *)dequeueComponentForKey:(CKMemoizationKey)key
{
  const auto it = componentCache_.find(key);
  if (it != componentCache_.end()) {
    CKComponent *c = it->second;
    const auto componentHasScope = (c.scopeFrameToken != nil);
    if (!componentHasScope || currentScopeIsAffectedByPendingStateUpdates()) {
      return nil;
    }
    // Remove this component from the cache, since you can't mount a component twice
    componentCache_.erase(it);
    const auto threadLocalScope = CKThreadLocalComponentScope::currentScope();
    if (threadLocalScope != nullptr) {
      const auto currentFramePair = threadLocalScope->stack.top();
      [currentFramePair.frame copyChildrenFrom:currentFramePair.equivalentPreviousFrame];
      // Use previous scope tree to gather children of the vended component and move them to
      // the next memoizer state
      [self copyChildComponentsToNextMemoizerStateFrom:currentFramePair.equivalentPreviousFrame];
    }
    return c;
  }
  return nil;
}

- (void)copyChildComponentsToNextMemoizerStateFrom:(CKComponentScopeFrame *)frame
{
  const auto implicitlyMemoizedChildren = [frame allAcquiredComponentsInDescendants];
  for (const auto &pair : componentCache_) {
    if (CK::Collection::containsWhere(implicitlyMemoizedChildren, [=](const auto &c){ return c == pair.second; })) {
      [self enqueueComponent:pair.second forKey:pair.first];
    }
  }
}

- (CKComponentMemoizerState *)next
{
  if (!_next) {
    _next = [[CKComponentMemoizerState alloc] init];
  }
  return _next;
}

- (void)enqueueComponent:(CKComponent *)component forKey:(CKMemoizationKey)key
{
  self.next->componentCache_.insert({key, component});
}

+ (CKComponentMemoizerState *)currentMemoizer
{
  return [[NSThread currentThread] threadDictionary][CKComponentMemoizerThreadKey];
}

+ (void)setCurrentMemoizer:(CKComponentMemoizerState *)memoizer
{
  if (memoizer) {
    [[NSThread currentThread] threadDictionary][CKComponentMemoizerThreadKey] = memoizer;
  } else {
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:CKComponentMemoizerThreadKey];
  }
}

@end

@interface CKComponentLayoutMemoizerState : NSObject {
  @package
  // Store into the next state, read from the current
  CKComponentLayoutMemoizerState *_next;
  std::unordered_map<CKLayoutMemoizationKey, CKComponentLayout, CKLayoutMemoizationKey::Hash, CKLayoutMemoizationKey::Equals> layoutCache_;
}

@end


@implementation CKComponentLayoutMemoizerState

- (CKComponentLayoutMemoizerState *)next
{
  if (!_next) {
    _next = [[CKComponentLayoutMemoizerState alloc] init];
  }
  return _next;
}

- (CKComponentLayout)cachedLayout:(CKComponent *)component
                         thatFits:(CKSizeRange)constrainedSize
                 restrictedToSize:(CKComponentSize)size
                       parentSize:(CGSize)parentSize
                            block:(CKComponentLayout (^)())block
{
  CKLayoutMemoizationKey key{.component = component, .thatFits = constrainedSize, .parentSize = parentSize};
  auto it = layoutCache_.find(key);
  if (it != layoutCache_.end()) {
    self.next->layoutCache_.insert({key, it->second});
    return it->second;
  } else {
    CKComponentLayout layout = block();
    self.next->layoutCache_.insert({key, layout});
    return layout;
  }
}

+ (CKComponentLayoutMemoizerState *)currentMemoizer
{
  return [[NSThread currentThread] threadDictionary][CKComponentLayoutMemoizerThreadKey];
}

+ (void)setCurrentMemoizer:(CKComponentLayoutMemoizerState *)memoizer
{
  if (memoizer) {
    [[NSThread currentThread] threadDictionary][CKComponentLayoutMemoizerThreadKey] = memoizer;
  } else {
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:CKComponentLayoutMemoizerThreadKey];
  }
}

@end

# pragma mark - CKComponentMemoizer

template <typename State>
CKComponentMemoizer<State>::CKComponentMemoizer(State *previousMemoizerState)
{
  State *impl = previousMemoizerState ?: [[State alloc] init];

  // Push this memoizer onto the current thread
  const auto current = [State currentMemoizer];
  previousMemoizer_ = current;
  [State setCurrentMemoizer:impl];
};

template <typename State>
CKComponentMemoizer<State>::~CKComponentMemoizer()
{
  // Pop memoizer
  [State setCurrentMemoizer:previousMemoizer_];
}

template <typename State>
State *CKComponentMemoizer<State>::nextMemoizerState()
{
  const auto impl = [State currentMemoizer];
  return impl ? impl->_next : nil;
}

template CKComponentMemoizer<CKComponentMemoizerState>::CKComponentMemoizer(CKComponentMemoizerState *previousMemoizerState);
template CKComponentMemoizer<CKComponentLayoutMemoizerState>::CKComponentMemoizer(CKComponentLayoutMemoizerState *previousMemoizerState);
template CKComponentMemoizer<CKComponentMemoizerState>::~CKComponentMemoizer();
template CKComponentMemoizer<CKComponentLayoutMemoizerState>::~CKComponentMemoizer();
template CKComponentMemoizerState *CKComponentMemoizer<CKComponentMemoizerState>::nextMemoizerState();
template CKComponentLayoutMemoizerState *CKComponentMemoizer<CKComponentLayoutMemoizerState>::nextMemoizerState();

# pragma mark - Public API

id CKMemoize(CKMemoizationKey memoizationKey, id (^block)(void))
{
  CKComponentMemoizerState *impl = [CKComponentMemoizerState currentMemoizer];
  // Attempt to get it from the cache on the current memoizer
  CKComponent *component = [impl dequeueComponentForKey:memoizationKey];
  if (!component && block) {
    component = block();
  }
  CKCAssertNotNil(impl, @"There is no current memoizer, cannot memoize component generation. You probably forgot to add a CKMemoizingComponent in the hierarchy above %@", component);
  const auto componentHasScope = (component.scopeFrameToken != nil);
  if (component && componentHasScope) {
    // Add it to the cache
    [impl enqueueComponent:component forKey:memoizationKey];
  }
  return component;
}

CKComponentLayout CKMemoizeLayout(CKComponent *component, CKSizeRange constrainedSize, const CKComponentSize& size, CGSize parentSize, CKComponentLayout (^block)())
{
  if (component != nil) {
    const auto impl = [CKComponentLayoutMemoizerState currentMemoizer];
    CKCAssertNotNil(impl, @"There is no current memoizer, cannot memoize layout. You probably forgot to add a CKMemoizingComponent in the hierarchy above %@", component);
    if (impl) { // If component wants layout memoization but there isn't a current memoizer, fall down to compute case
      return [impl cachedLayout:component
                       thatFits:constrainedSize
               restrictedToSize:size
                     parentSize:parentSize
                          block:block];
    }
  }
  return block();
}
