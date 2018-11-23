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
                    layoutManagerFactory:(NSLayoutManager*(*)(void))layoutManagerFactory
{
  if (self = [super init]) {
    // Concurrently initialising TextKit components crashes (rdar://18448377) so we use a global lock.
    static std::mutex *__static_mutex = new std::mutex;
    std::lock_guard<std::mutex> l(*__static_mutex);
    // Create the TextKit component stack with our default configuration.
    _layoutManager = layoutManagerFactory ? layoutManagerFactory() : [[NSLayoutManager alloc] init];
    _layoutManager.usesFontLeading = NO;
    _textContainer = [[NSTextContainer alloc] initWithSize:constrainedSize];
    // We want the text laid out up to the very edges of the container.
    _textContainer.lineFragmentPadding = 0;
    _textContainer.lineBreakMode = lineBreakMode;
    _textContainer.maximumNumberOfLines = maximumNumberOfLines;
    [_layoutManager addTextContainer:_textContainer];
    // addLayoutManager after addTextContainer can be surer trigger glyph generation and layout.
    _textStorage = [[NSTextStorage alloc] init];
    [_textStorage addLayoutManager:_layoutManager];
    // set attributedString at the last, textkit can handle NSOriginalFont correctly.
    if (attributedString) {
      [_textStorage setAttributedString:attributedString];
    }
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
