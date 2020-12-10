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

#import <functional>
#import <unordered_map>
#import <memory>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKComponentScopeHandle.h>

template<typename... T>
class CKTriggerObservable {
protected:
  typedef CKScopedResponderUniqueIdentifier Key;
  typedef void(*fn_type)(CKScopedResponder *, CKScopedResponderKey, T...);

  struct Value {
    CKScopedResponder *scopedResponder;
    CKScopedResponderKey scopedResponderKey;
    fn_type fn;
  };
  std::shared_ptr<std::unordered_map<Key, Value>> _observers;

public:
  CKTriggerObservable() : _observers(std::make_shared<std::unordered_map<Key, Value>>()) {};

  void addObserver(Key key, const Value &observer) const
  {
    CKCAssert(
      [NSThread isMainThread],
      @"Triggers are expected to be bound/unbound on the main thread (e.g., from didInit/willDispose lifecycle events)"
    );

    _observers->insert(std::make_pair(key, observer));
  };

  void removeObserver(Key key) const
  {
    CKCAssert(
      [NSThread isMainThread],
      @"Triggers are expected to be bound/unbound on the main thread (e.g., from didInit/willDispose lifecycle events)"
    );

    _observers->erase(key);
  };
};

template<typename... T>
class CKTrigger : public CKTriggerObservable<T...> {
public:
  void operator()(T... args) const
  {
    CKCAssert(
      [NSThread isMainThread],
      @"Triggers are expected to be invoked on the main thread"
    );

    for (const auto &observer : *this->_observers) {
      observer.second.fn(observer.second.scopedResponder, observer.second.scopedResponderKey, args...);
    }
  };
};

#endif
