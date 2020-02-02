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

#import <ComponentKit/CKThreadLocalComponentScope.h>

/**
 Allows a parent to assign a "key" to child components to distinguish them, preventing a CKComponentScope collision.
 This is analogous to the concept of "key" in React.

 A CKComponentKey distinguishes any children that are created while it is in scope. Consider this example:

 CK::map(contacts, ^(Contact *contact) {
   CKComponentKey key(contact.uniqueIdentifier);
   return [ContactComponent newWithContact:context];
 });

 Each ContactComponent will have its own state; if contacts are inserted, deleted, or moved they will maintain the
 correct state.
 */
class CKComponentKey {
public:
  CKComponentKey(id<NSObject> key) noexcept;
  ~CKComponentKey() noexcept;
private:
  CKComponentKey(const CKComponentKey&) = delete;
  CKComponentKey &operator=(const CKComponentKey&) = delete;
  CKThreadLocalComponentScope *_threadLocalScope;
  id<NSObject> _key;
};

#endif
