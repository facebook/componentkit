/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */
#import "CKStatefulViewComponentController.h"

#import "CKStatefulViewReusePool.h"

#import <unordered_map>

class FBStatefulReusePoolItem {
public:
  FBStatefulReusePoolItem()
  : views([NSMutableArray array]) {};

  UIView *viewWithPreferredSuperview(UIView *preferredSuperview)
  {
    if ([views count] == 0) {
      return nil;
    }
    const NSUInteger matchingIndex = [views indexOfObjectPassingTest:^BOOL(UIView *view, NSUInteger idx, BOOL *stop) {
      return [view superview] == preferredSuperview;
    }];
    const NSUInteger viewIndex = (matchingIndex == NSNotFound) ? 0 : matchingIndex;
    UIView *view = views[viewIndex];
    [views removeObjectAtIndex:viewIndex];
    return view;
  };
  
  NSUInteger viewCount()
  {
    return [views count];
  };

  void addView(UIView *view)
  {
    [views addObject:view];
  };

private:
  NSMutableArray<UIView *> *views;
};

struct PoolKeyHasher {
  std::size_t operator()(const std::pair<__unsafe_unretained Class, id> &pair) const
  {
    return [pair.first hash] ^ [pair.second hash];
  }
};

@implementation CKStatefulViewReusePool
{
  std::unordered_map<std::pair<__unsafe_unretained Class, id>, FBStatefulReusePoolItem, PoolKeyHasher> _pool;
}

+ (instancetype)sharedPool
{
  static CKStatefulViewReusePool *pool;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pool = [[CKStatefulViewReusePool alloc] init];
  });
  return pool;
}

- (UIView *)dequeueStatefulViewForControllerClass:(Class)controllerClass
                               preferredSuperview:(UIView *)preferredSuperview
                                          context:(id)context
{
  NSAssert([NSThread isMainThread], nil);
  NSParameterAssert(controllerClass != nil);
  const auto it = _pool.find(std::make_pair(controllerClass, context));
  if (it == _pool.end()) { // Avoid overhead of creating the item unless it already exists
    return nil;
  }
  return it->second.viewWithPreferredSuperview(preferredSuperview);
}

- (void)enqueueStatefulView:(UIView *)view
         forControllerClass:(Class)controllerClass
                    context:(id)context
{
  NSAssert([NSThread isMainThread], nil);
  NSParameterAssert(view != nil);
  NSParameterAssert(controllerClass != nil);
  
  // maximumPoolSize will be -1 by default
  NSInteger maximumPoolSize = [controllerClass maximumPoolSize:context];
  
  FBStatefulReusePoolItem poolItem = _pool[std::make_pair(controllerClass, context)];
  if (maximumPoolSize < 0 || poolItem.viewCount() < maximumPoolSize) {
    poolItem.addView(view);
  }
}

@end
