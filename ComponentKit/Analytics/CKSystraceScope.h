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

#import <ComponentKit/CKAsyncBlock.h>

@protocol CKSystraceListener;

/**
 Starts a block tracer when it is constructed and ends it when destructed.

 Notes:
 The following methods will be called on CKSystraceListener:
 - (void)willStartBlockTrace:(const char *const)blockName;
 - (void)didEndBlockTrace:(const char *const)blockName;

 Example usage:
 - (void)proccessImage
 {
    CKSystraceScope s("Processing image");
    // Do some expensive work here:
 }
 */
class CKSystraceScope {
public:
  CKSystraceScope(const char *const blockName) noexcept;
  CKSystraceScope(const CK::Analytics::AsyncBlock &asyncBlock) noexcept;
  ~CKSystraceScope();

private:
  const char *const _blockName;
  id<CKSystraceListener> _systraceListener;
  bool _isAsync;
  CKSystraceScope(const CKSystraceScope &) = delete; // copy
  CKSystraceScope &operator=(const CKSystraceScope&) = delete;
  CKSystraceScope(CKSystraceScope&&) = delete; // move
  CKSystraceScope &operator=(CKSystraceScope&&) = delete;
};

#endif
