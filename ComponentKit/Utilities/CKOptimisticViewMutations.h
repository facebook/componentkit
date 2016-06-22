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

typedef id (*CKOptimisticViewMutationGetter)(UIView *view, id context);
typedef void (*CKOptimisticViewMutationSetter)(UIView *view, id value, id context);

/**
 Use this function to optimistically mutate the view owned by a CKComponent. When the view is recycled, the mutation
 will be safely undone, resetting all properties to their original values.

 @warning Optimistically mutating the view for a component is **strongly** discouraged. You should instead use
 updateState: or trigger a change in the source model object.

 @param view The view to modify.
 @param getter A function that accepts a view instance and returns the value of the property you want to modify.
 @param setter A function that accepts a view instance and some target value and sets the property to that target value.
 @param value The value you want to be set on the view using the setter.
 @param context Passed to both the getter and setter functions. Optional.

 The getter will be invoked to fetch the current value; then the setter will be invoked with the passed value.
 When the view is recycled, the setter will be invoked again with the saved result from the getter block.
 The getter and setter should be free of any side effects that modify other views, global state, etc.
 */
void CKPerformOptimisticViewMutation(UIView *view,
                                     CKOptimisticViewMutationGetter getter,
                                     CKOptimisticViewMutationSetter setter,
                                     id value,
                                     id context = nil);

/** A helper that creates a getter and setter for a given keypath. */
void CKPerformOptimisticViewMutation(UIView *view, NSString *keyPath, id value);

/** Used by the infrastructure to tear down optimistic mutations. Don't call this yourself. */
void CKResetOptimisticMutationsForView(UIView *view);
