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

struct CKComponentContextPreviousState {
  id key;
  id originalValue;
  id newValue;
};

struct CKComponentContextContents {
  /** The items stored in CKComponentContext. */
  NSDictionary<Class, id> *objects;

  bool operator==(const CKComponentContextContents&) const;
  bool operator!=(const CKComponentContextContents&) const;
};

/** Internal helper class. Avoid using this externally. */
struct CKComponentContextHelper {
  static CKComponentContextPreviousState store(id key, id object);
  static void restore(const CKComponentContextPreviousState &storeResult);
  static id fetch(id key); // Fetch value from CKComponentContext.
  static id fetchMutable(id key); // Fetch value from CKComponentMutableContext.

  /** Creates a backup of the existing store, in the renderToDictionary map */
  static void didCreateRenderComponent(id component);
  /** Pushes the existing store into a stack and change it with the one from the component's backup */
  static void willBuildComponentTree(id component);
  /** Restores the previous store from the stack */
  static void didBuildComponentTree(id component);

  /**
   Returns a structure with all the items that are currently in CKComponentContext.
   This could be used to bridge CKComponentContext items to another language or system.
   */
  static CKComponentContextContents fetchAll();
};


/**
 Provides a way to set initial context values.
 This could be used to bridge CKComponentContext items to another language or system.
 */
class CKComponentInitialValuesContext {
public:
  CKComponentInitialValuesContext(NSDictionary<Class, id> *objects){
    if (objects) { _oldObjects = setInitialValues(objects); }
  }
  ~CKComponentInitialValuesContext() { cleanInitialValues(_oldObjects); }

private:
  /** Provides a way to set initial context values. */
  static NSMutableDictionary<Class, id>* setInitialValues(NSDictionary<Class, id> *objects);
  /** Provide a way to clean the initial values that were set with `setInitialValues`.*/
  static void cleanInitialValues(NSMutableDictionary<Class, id> *oldObjects);
  /** Save the old objects. */
  NSMutableDictionary *_oldObjects;

  CKComponentInitialValuesContext(const CKComponentInitialValuesContext&) = delete;
  CKComponentInitialValuesContext &operator=(const CKComponentInitialValuesContext&) = delete;
};

#endif
