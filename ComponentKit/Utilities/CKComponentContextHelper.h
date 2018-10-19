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
  Class key;
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
  static id fetch(id key);

  /** Enable render support */
  static void enableRenderSupport(BOOL enable);
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
 Enable support for render components.

 Should be called from the CKBuildComponent function before any component is being built.
 */
class CKComponentContextRenderSupport {
public:
  CKComponentContextRenderSupport(BOOL enableRenderSupport) : _enableRenderSupport(enableRenderSupport) {
    if (_enableRenderSupport) { CKComponentContextHelper::enableRenderSupport(YES); }
  }
  ~CKComponentContextRenderSupport() {
    if (_enableRenderSupport) { CKComponentContextHelper::enableRenderSupport(NO);}
  }

private:
  BOOL _enableRenderSupport;

  CKComponentContextRenderSupport(const CKComponentContextRenderSupport&) = delete;
  CKComponentContextRenderSupport &operator=(const CKComponentContextRenderSupport&) = delete;
};

