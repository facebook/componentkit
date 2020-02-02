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
#import <UIKit/UIView.h>

#import <ComponentKit/CKComponentAttachController.h>
#import <ComponentKit/CKComponentScopeTypes.h>

/*
 * This will cause the layout referenced by `scopeIdentifier` to be unmounted when `cell` is deallocated.
 * This is useful for collection views, whose cell views are managed by UIKit: usually they are re-used,
 * but sometimes they are deallocated. At that point, the object graph looks like this:

                                             Cell view
                                              |
                                              |
       attachController                       v
(via _scopeIdentifierToAttachedViewMap) --> root view
                                              |
                                              |
                                              v
                                             View <--> Component
                                             / | \
                                            /  |  \
                                           /   |   v
                                          /    |  View <--> Component
                                         /     v
                                        /    View <--> Component
                                       v
                                      View <--> Component

 * The Cell --> RootView link is broken when the cell is deallocated. But everything else sticks around, wasting memory.
 * Thus, we should unmount whatever was mounted to the cell's root view, which will cause the Map->RootView link
 * and all the View <--> Component links to be broken and the whole structure to be freed.
 */
void CKSetupDeallocUnmounter(UIView *cell, CKComponentScopeRootIdentifier scopeIdentifier, CKComponentAttachController *attachController);

#endif
