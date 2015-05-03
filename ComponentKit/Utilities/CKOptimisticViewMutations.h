/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

/**
 Use this function to optimistically mutate the view owned by a CKComponent. When the view is recycled, the mutation
 will be safely undone, resetting all properties to their original values.

 @warning Optimistically mutating the view for a component is **strongly** discouraged. You should instead use
 updateState: or trigger a change in the source model object.
 */
void CKPerformOptimisticViewMutation(UIView *view, NSString *keyPath, id value);

/** Used by the infrastructure to tear down optimistic mutations. Don't call this yourself. */
void CKResetOptimisticMutationsForView(UIView *view);
