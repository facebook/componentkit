/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <stack>

#import <Foundation/Foundation.h>

#import <ComponentKit/CKAssert.h>

@class CKComponentScopeFrame;
@protocol CKComponentStateListener;

class CKComponentScopeCursor {
  struct CKComponentScopeCursorFrame {
    CKComponentScopeFrame *frame;
    CKComponentScopeFrame *equivalentPreviousFrame;
  };

  std::stack<CKComponentScopeCursorFrame> _frames;
 public:
  /** Push a new frame onto both state-trees. */
  void pushFrameAndEquivalentPreviousFrame(CKComponentScopeFrame *frame, CKComponentScopeFrame *equivalentPreviousFrame);

  /** Pop off one frame on both state trees.  */
  void popFrame();

  CKComponentScopeFrame *currentFrame() const;
  CKComponentScopeFrame *equivalentPreviousFrame() const;

  bool empty() const { return _frames.empty(); }
};

class CKThreadLocalComponentScope {
public:
  CKThreadLocalComponentScope(id<CKComponentStateListener> listener, CKComponentScopeFrame *previousRootFrame);
  ~CKThreadLocalComponentScope() throw(...);

  static CKComponentScopeCursor *cursor();
};
