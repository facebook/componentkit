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

/**
 This is a base class every announcer extends.

 Since we want to keep announcers Obj-C friendly
 we hide the Obj-C++ part in CKComponentAnnouncerBaseInternal.h.
 Otherwise it would leak out through declaration of an announcer class.
 */
@interface CKComponentAnnouncerBase : NSObject
@end
