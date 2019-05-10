/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceAsyncLayoutItem.h"
#import "CKDataSourceItemInternal.h"
#import "CKDataSourceQOSHelper.h"
#import "CKAnalyticsListener.h"
#import "CKDataSourceModificationHelper.h"

#import <ComponentKit/CKComponentLayout.h>

#import <mutex>

@implementation CKDataSourceAsyncLayoutItem
{
  std::atomic<BOOL> _hasStartedLayout;
  dispatch_queue_t _queue;
  CKDataSourceQOS _qos;

  std::atomic<BOOL> _isFinished;
  std::mutex _waitOnLayoutMutex;
  CKDataSourceItem *_item;
  id<CKSystraceListener> _systraceListener;

  CKComponentScopeRoot *_previousRoot;
  CKComponentStateUpdateMap _stateUpdateMap;
  CKSizeRange _sizeRange;
  CKDataSourceConfiguration *_configuration;
  id _model;
  id _context;
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue
                          qos:(CKDataSourceQOS)qos
                 previousRoot:(CKComponentScopeRoot *)previousRoot
                 stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                    sizeRange:(const CKSizeRange &)sizeRange
                configuration:(CKDataSourceConfiguration *)configuration
                        model:(id)model
                      context:(id)context
{
  if(self = [self initWithModel:model scopeRoot:previousRoot]) {
    _isFinished = NO;
    _hasStartedLayout = NO;
    _queue = queue;
    _qos = qos;
    _previousRoot = previousRoot;
    _stateUpdateMap = stateUpdates;
    _sizeRange = sizeRange;
    _configuration = configuration;
    _model = model;
    _context = context;
    _systraceListener = [[previousRoot analyticsListener] systraceListener];
  }
  return self;
}

- (void)beginLayout
{
  if (!_hasStartedLayout.exchange(YES)) {
   _waitOnLayoutMutex.lock();
   dispatch_async(_queue, blockUsingDataSourceQOS(^{
      auto item = CKBuildDataSourceItem(_previousRoot, _stateUpdateMap, _sizeRange, _configuration, _model, _context);
      _item = item;
      _isFinished = YES;
      _waitOnLayoutMutex.unlock();
    }, _qos));
  }
}

- (const CKComponentRootLayout &)rootLayout
{
  return [[self _getItemSync] rootLayout];
}

- (CKComponentBoundsAnimation)boundsAnimation
{
  return [[self _getItemSync] boundsAnimation];
}

- (CKDataSourceItem *)_getItemSync
{
  if (_isFinished == YES) {
    return _item;
  } else {
    [_systraceListener willBlockThreadOnGeneratingItemLayout];
    std::lock_guard<std::mutex> l(_waitOnLayoutMutex);
    [_systraceListener didBlockThreadOnGeneratingItemLayout];
    return _item;
  }
}

- (BOOL)hasFinishedComputingLayout
{
  return _isFinished;
}

@end
