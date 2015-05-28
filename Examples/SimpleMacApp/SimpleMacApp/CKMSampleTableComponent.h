/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/ComponentKit.h>

/**
 * This is just a sample of how you can insert a tableview as a component into a bigger layout.
 * It makes an NSTableView with one column.
 */
@interface CKMSampleTableComponent : CKComponent

+ (instancetype)newWithScrollView:(CKComponentViewConfiguration)scrollView
                        tableView:(CKComponentViewConfiguration)tableView
                           models:(NSArray *)modelObjects
                componentProvider:(Class)componentProvider
                             size:(CKComponentSize)size;

@end
