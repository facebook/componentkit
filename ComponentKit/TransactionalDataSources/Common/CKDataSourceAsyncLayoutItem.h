/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceQOS.h>

#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKSizeRange.h>


/**
 `CKDataSourceAsyncLayoutItem` is a datasource item which instead of merely
 holding a set of data manages the async computation of a layout. When the
 item is created it will schedule the building a data source item asynchronously
 and then when someone asks for that layout if the item has not yet finished
 computing it will block upon that computation finishing. This can be used to
 tweak the concurrency of the rendering system to better parallelize things
 like mounting with component generation and layout.
 */
@interface CKDataSourceAsyncLayoutItem : CKDataSourceItem

- (instancetype)initWithQueue:(NSOperationQueue *)queue
                 previousRoot:(CKComponentScopeRoot *)previousRoot
                 stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                    sizeRange:(const CKSizeRange &)sizeRange
                configuration:(CKDataSourceConfiguration *)configuration
                        model:(id)model
                      context:(id)context;

/**
 Called to actually kick off the async layout, however we will not kick off
 the layout multiple times if this method is called multiple times.

 NOTE: If you have not kicked off the async layout by the time someone asks for
 the layout for this item it will be done without calling this method.
 */
- (void)beginLayout;

/**
 Generally one should interact with an async layout item as if it were a standard
 datasource item. However sometimes you might want to not need to block on having
 a layout if you're not actually going to use the full layout at that point and can
 come up with a reasonable estimate in the meantime. For example collection view
 with certain layouts will immediately ask for the height of all of the items which
 it knows about, and we don't really need to block on the fully accurate information.
 */
- (BOOL)hasFinishedComputingLayout;

@end
