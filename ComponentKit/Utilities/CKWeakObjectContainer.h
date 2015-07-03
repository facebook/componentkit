/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif

extern void ck_objc_setNonatomicAssociatedWeakObject(id container, void *key, id value);
extern void ck_objc_setAssociatedWeakObject(id container, void *key, id value);
extern id ck_objc_getAssociatedWeakObject(id container, void *key);

#ifdef __cplusplus
}
#endif
