/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKThreadLocalComponentScope.h"

#import <pthread.h>
#import <stack>

#import <ComponentKit/CKAssert.h>

#import "CKComponentScopeFrame.h"
#import "CKComponentScopeInternal.h"

void CKComponentScopeCursor::pushFrameAndEquivalentPreviousFrame(CKComponentScopeFrame *frame, CKComponentScopeFrame *equivalentFrame)
{
  _frames.push({frame, equivalentFrame});
}

void CKComponentScopeCursor::popFrame()
{
  _frames.pop();
}

CKComponentScopeFrame *CKComponentScopeCursor::currentFrame() const
{
  return _frames.empty() ? nullptr :  _frames.top().frame;
}

CKComponentScopeFrame *CKComponentScopeCursor::equivalentPreviousFrame() const
{
  return _frames.empty() ? nullptr : _frames.top().equivalentPreviousFrame;
}

static pthread_key_t thread_key;
static pthread_once_t key_once = PTHREAD_ONCE_INIT;

static void _valueDestructor(void *context)
{
  CKComponentScopeCursor *ptr = (CKComponentScopeCursor *)context;
  delete ptr;
}

static void _makeThreadKey()
{
  (void)pthread_key_create(&thread_key, _valueDestructor);
}

CKComponentScopeCursor *CKThreadLocalComponentScope::cursor()
{
  // Return the TLS, allocating if this is the first time through.
  (void)pthread_once(&key_once, _makeThreadKey);
  CKComponentScopeCursor *cursor = (CKComponentScopeCursor *)pthread_getspecific(thread_key);
  if (!cursor) {
    cursor = new CKComponentScopeCursor;
    pthread_setspecific(thread_key, cursor);
  }
  return cursor;
}

CKThreadLocalComponentScope::CKThreadLocalComponentScope(id<CKComponentStateListener> listener,
                                                         CKComponentScopeFrame *previousRootFrame)
{
  CKCAssert(cursor()->empty(), @"CKThreadLocalStateScope already exists. You cannot create two at the same time.");
  cursor()->pushFrameAndEquivalentPreviousFrame([CKComponentScopeFrame rootFrameWithListener:listener], previousRootFrame);
}

CKThreadLocalComponentScope::~CKThreadLocalComponentScope() throw(...)
{
  cursor()->popFrame();
  CKCAssert(cursor()->empty(), @"");
}
