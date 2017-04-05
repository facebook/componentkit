/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

struct CKComponentContextPreviousState {
  id key;
  id originalValue;
  id newValue;
};

@protocol CKComponentContextDynamicLookup <NSObject>
- (id)contextValueForClass:(Class)c;
@end

struct CKComponentContextContents {
  /** The items stored in CKComponentContext. */
  NSDictionary<Class, id> *objects;
  /** The dynamic lookup implementation, if any; used for classes not found in objects. */
  id<CKComponentContextDynamicLookup> dynamicLookup;

  bool operator==(const CKComponentContextContents&) const;
  bool operator!=(const CKComponentContextContents&) const;
};

struct CKComponentContextPreviousDynamicLookupState {
  NSDictionary *previousContents;
  id<CKComponentContextDynamicLookup> originalLookup;
  id<CKComponentContextDynamicLookup> newLookup;
};

/** Internal helper class. Avoid using this externally. */
struct CKComponentContextHelper {
  static CKComponentContextPreviousState store(id key, id object);
  static void restore(const CKComponentContextPreviousState &storeResult);
  static id fetch(id key);
  /**
   Returns a structure with all the items that are currently in CKComponentContext.
   This could be used to bridge CKComponentContext items to another language or system.
   */
  static CKComponentContextContents fetchAll();
  /**
   Removes all items currently stored in CKComponentContext, and specifies an object that should be consulted
   for each lookup instead. This can be used to bridge CKComponentContext to another language or system,
   deferring any translation cost to each lookup instead of performing it eagerly.

   Since this removes all currently existing items from CKComponentContext, you should always call fetchAll()
   first and supply those values to the lookup for it to use. This includes the task of consulting the
   *previous* dynamic lookup, if one was already specified.

   If new items are stored while the dynamic lookup is active, those items will be returned immediately instead
   of consulting the dynamic lookup for as long as they are present. For example:

     store([Foo class], foo1);
     setDynamicLookup(lookup);
     fetch([Foo class]); // consults lookup
     store([Foo class], foo2);
     fetch([Foo class]); // returns foo2 without consulting lookup
   */
  static CKComponentContextPreviousDynamicLookupState setDynamicLookup(id<CKComponentContextDynamicLookup> lookup);
  /** Restores the state of CKComponentContext to what it was before a call to setDynamicLookup. */
  static void restoreDynamicLookup(const CKComponentContextPreviousDynamicLookupState &setResult);
};
