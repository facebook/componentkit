/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <mutex>

#import <ComponentKit/CKTextKitContext.h>

@implementation CKTextKitContext
{
  // All TextKit operations (even non-mutative ones) must be executed serially.
  std::mutex _textKitMutex;

  NSLayoutManager *_layoutManager;
  NSTextStorage *_textStorage;
  NSTextContainer *_textContainer;
}

- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString
                           lineBreakMode:(NSLineBreakMode)lineBreakMode
                    maximumNumberOfLines:(NSUInteger)maximumNumberOfLines
                         constrainedSize:(CGSize)constrainedSize
{
  if (self = [super init]) {
    // Concurrently initialising TextKit components crashes (rdar://18448377) so we use a global lock.
    static std::mutex __static_mutex;
    std::lock_guard<std::mutex> l(__static_mutex);
    // Create the TextKit component stack with our default configuration.
    _textStorage = (attributedString ? [[NSTextStorage alloc] initWithAttributedString:attributedString] : [[NSTextStorage alloc] init]);
    _layoutManager = [[NSLayoutManager alloc] init];
    _layoutManager.usesFontLeading = NO;
    [_textStorage addLayoutManager:_layoutManager];
    _textContainer = [[NSTextContainer alloc] initWithSize:constrainedSize];
    // We want the text laid out up to the very edges of the container.
    _textContainer.lineFragmentPadding = 0;
    _textContainer.lineBreakMode = lineBreakMode;
    _textContainer.maximumNumberOfLines = maximumNumberOfLines;
    [_layoutManager addTextContainer:_textContainer];
  }
  return self;
}

- (void)performBlockWithLockedTextKitComponents:(void (^)(NSLayoutManager *,
                                                          NSTextStorage *,
                                                          NSTextContainer *))block
{
  std::lock_guard<std::mutex> l(_textKitMutex);
  block(_layoutManager, _textStorage, _textContainer);
}

@end
