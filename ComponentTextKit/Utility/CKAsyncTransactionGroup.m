 /*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAsyncTransactionGroup.h"

#import <ComponentKit/CKAssert.h>

#import "CKAsyncTransaction.h"
#import "CKAsyncTransactionContainer+Private.h"

static void _transactionGroupRunLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info);

@implementation CKAsyncTransactionGroup {
  NSHashTable *_containerLayers;
}

+ (CKAsyncTransactionGroup *)mainTransactionGroup
{
  CKAssertMainThread();
  static CKAsyncTransactionGroup *mainTransactionGroup;

  if (mainTransactionGroup == nil) {
    mainTransactionGroup = [[CKAsyncTransactionGroup alloc] init];
    [self registerTransactionGroupAsMainRunloopObserver:mainTransactionGroup];
  }
  return mainTransactionGroup;
}

+ (void)registerTransactionGroupAsMainRunloopObserver:(CKAsyncTransactionGroup *)transactionGroup
{
  CKAssertMainThread();
  static CFRunLoopObserverRef observer;
  CKAssert(observer == NULL, @"A CKAsyncTransactionGroup should not be registered on the main runloop twice");
  // defer the commit of the transaction so we can add more during the current runloop iteration
  CFRunLoopRef runLoop = CFRunLoopGetCurrent();
  CFOptionFlags activities = (kCFRunLoopBeforeWaiting | // before the run loop starts sleeping
                              kCFRunLoopExit);          // before exiting a runloop run
  CFRunLoopObserverContext context = {
    0,           // version
    (__bridge void *)transactionGroup,  // info
    &CFRetain,   // retain
    &CFRelease,  // release
    NULL         // copyDescription
  };

  observer = CFRunLoopObserverCreate(NULL,        // allocator
                                     activities,  // activities
                                     YES,         // repeats
                                     INT_MAX,     // order after CA transaction commits
                                     &_transactionGroupRunLoopObserverCallback,  // callback
                                     &context);   // context
  CFRunLoopAddObserver(runLoop, observer, kCFRunLoopCommonModes);
  CFRelease(observer);
}

- (id)init
{
  if ((self = [super init])) {
    _containerLayers = [[NSHashTable alloc] initWithOptions:NSHashTableStrongMemory|NSHashTableObjectPointerPersonality capacity:0];
  }
  return self;
}

#pragma mark Public methods

- (void)addTransactionContainer:(CALayer *)containerLayer
{
  CKAssertMainThread();
  CKAssertNotNil(containerLayer, @"Cannot add a nil layer to the group");
  [_containerLayers addObject:containerLayer];
}

#pragma mark Transactions

- (void)commit
{
  CKAssertMainThread();

  if ([_containerLayers count]) {
    NSSet *containerLayersToCommit = [_containerLayers copy];
    [_containerLayers removeAllObjects];

    for (CALayer *containerLayer in containerLayersToCommit) {
      // Note that the act of committing a transaction may open a new transaction,
      // so we must nil out the transaction we're committing first.
      CKAsyncTransaction *transaction = containerLayer.ck_currentAsyncLayerTransaction;
      containerLayer.ck_currentAsyncLayerTransaction = nil;
      [transaction commit];
    }
  }
}

@end

static void _transactionGroupRunLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
  CKCAssertMainThread();
  CKAsyncTransactionGroup *group = (__bridge CKAsyncTransactionGroup *)info;
  [group commit];
}
