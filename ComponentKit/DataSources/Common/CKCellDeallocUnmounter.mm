/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKCellDeallocUnmounter.h"
#import <objc/runtime.h>

@interface CKCellDeallocUnmounter : NSObject

@property (nonatomic, assign) CKComponentScopeRootIdentifier scopeIdentifier;
@property (nonatomic, weak) CKComponentAttachController *attachController;

+ (CKCellDeallocUnmounter *)unmounterForCell:(UIView *)cell;
@end

@implementation CKCellDeallocUnmounter

- (void)setScopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
{
  CKAssertMainThread();
  _scopeIdentifier = scopeIdentifier;
}

- (void)setAttachController:(CKComponentAttachController *)attachController
{
  CKAssertMainThread();
  _attachController = attachController;
}

- (void)dealloc
{
  CKAssertMainThread();
  [_attachController detachComponentLayoutWithScopeIdentifier:_scopeIdentifier];
}

+ (CKCellDeallocUnmounter *)unmounterForCell:(UIView *)cell
{
  static char kUnmounterKey;
  CKCellDeallocUnmounter *unmounter = objc_getAssociatedObject(cell, &kUnmounterKey);
  if (!unmounter) {
    unmounter = [CKCellDeallocUnmounter new];
    objc_setAssociatedObject(cell, &kUnmounterKey, unmounter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return unmounter;
}
@end


void CKSetupDeallocUnmounter(UIView *cell, CKComponentScopeRootIdentifier scopeIdentifier, CKComponentAttachController *attachController)
{
  CKCellDeallocUnmounter *unmounter = [CKCellDeallocUnmounter unmounterForCell:cell];
  unmounter.scopeIdentifier = scopeIdentifier;
  unmounter.attachController = attachController;
}
