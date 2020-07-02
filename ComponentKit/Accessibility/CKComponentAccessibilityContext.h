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

#import <ComponentKit/CKAction.h>
#import <RenderCore/CKAccessibilityContext.h>

/**
 Sometimes you may wish to trigger the CKAction for a component externally
 as part of implementing a UIAccessibilityCustomAction for VoiceOver.
 ComponentKit itself never does this, but components may expose their action
 for such external use by storing an entry in the extra dictionary
 of CKAccessibilityContext under this key.

 The corresponding value should be an Objective-C block that returns a
 CKAction<>. You can safely generate this using the
 CKAccessibilityExtraActionValue function.

 For example:

 ```
 CKAccessibilityContext {
   .extra = @{
     CKAccessibilityExtraActionKey: CKAccessibilityExtraActionValue(action)
   }
 }
 ```
 */
extern NSString *const CKAccessibilityExtraActionKey;

/** For use with CKAccessibilityExtraActionKey. */
id CKAccessibilityExtraActionValue(CKAction<> action);

/**
 Extracts the value stored using CKAccessibilityExtraActionValue.
 If the parameter is nil, returns a default-constructed no-op action.
 For example:

 ```
 CKAction<> action = CKAccessibilityActionFromExtraValue(
   context.extra[CKAccessibilityExtraActionKey]
 );
 ```
 */
CKAction<> CKAccessibilityActionFromExtraValue(id extraValue);

/** An obsolete name for CKAccessibilityContext. Should be removed. */
using CKComponentAccessibilityContext = CKAccessibilityContext;

#endif
