/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <objc/message.h>
#import <vector>

#import <Foundation/Foundation.h>
#import <ComponentKit/CKComponentAnnouncerBase.h>
#import <ComponentKit/CKComponentAnnouncerBaseInternal.h>

namespace CK {
  namespace Component {
    struct AnnouncerHelper
    {
    private:
      // function to load the current listeners vector in a thread safe way
      static std::shared_ptr<const std::vector<__weak id>> loadListeners(CKComponentAnnouncerBase *self);
    public:
      template<typename... ARGS>
      static void call(CKComponentAnnouncerBase *self, SEL s, ARGS... args) {
        typedef void (*TT)(id self, SEL _cmd, ARGS...); // for floats, etc, we need to use the strong typed versions
        TT objc_msgSendTyped = (TT)(void*)objc_msgSend;
        
        auto frozenListeners = loadListeners(self);
        if (frozenListeners) {
          for (id listener : *frozenListeners) {
            objc_msgSendTyped(listener, s, args...);
          }
        }
      }
      
      template<typename... ARGS>
      static void callOptional(CKComponentAnnouncerBase *self, SEL s, ARGS... args) {
        typedef void (*TT)(id self, SEL _cmd, ARGS...); // for floats, etc, we need to use the strong typed versions
        TT objc_msgSendTyped = (TT)(void*)objc_msgSend;
        
        auto frozenListeners = loadListeners(self);
        if (frozenListeners) {
          for (id listener : *frozenListeners) {
            if ([listener respondsToSelector:s]) {
              objc_msgSendTyped(listener, s, args...);
            }
          }
        }
      }
      
      static void addListener(CKComponentAnnouncerBase *self, SEL s, id listener);
      
      static void removeListener(CKComponentAnnouncerBase *self, SEL s, id listener);
    };
  }
}
