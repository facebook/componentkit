/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

#import "ComponentKitApplicationTestsHostAppDelegate.h"

int main(int argc, char *argv[])
{
  @autoreleasepool {
      return UIApplicationMain(argc, argv, nil, NSStringFromClass([ComponentKitTestHostAppDelegate class]));
  }
}


#else

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[])
{
  return NSApplicationMain(argc, argv);
}

#endif