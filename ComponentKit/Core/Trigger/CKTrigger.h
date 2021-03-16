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
#import <vector>
#import <memory>

#import <RenderCore/RCAssert.h>
#import <ComponentKit/CKComponentScopeHandle.h>

struct CKTriggerScopedResponderAndKey {
  CKScopedResponder *responder;
  CKScopedResponderKey key;

  CKTriggerScopedResponderAndKey(CKScopedResponder *responder, CKScopedResponderKey key);
  CKTriggerScopedResponderAndKey(id<CKComponentProtocol> component, NSString *context = @"");

  auto operator== (const CKTriggerScopedResponderAndKey& rhs) const {
    return responder == rhs.responder;
  }
};

template<typename... T>
class CKTriggerObservable {
  using ScopedResponderAndKey = CKTriggerScopedResponderAndKey;
  typedef void(*SpecBinderCallback)(id<CKComponentProtocol>, T...);
  struct ObserverComponentSpec {
    ScopedResponderAndKey scope;
    SpecBinderCallback specCallback;

    auto operator== (const ObserverComponentSpec& rhs) const {
      return scope == rhs.scope;
    }
  };

protected:
  std::shared_ptr<std::vector<ObserverComponentSpec>> _observers;

public:
  CKTriggerObservable() : _observers(std::make_shared<std::vector<ObserverComponentSpec>>()) {};

  void addObserver(const ScopedResponderAndKey& scope, const SpecBinderCallback& specCallback) const
  {
    RCCAssert(
      [NSThread isMainThread],
      @"Triggers are expected to be bound/unbound on the main thread (e.g., from didInit/willDispose lifecycle events)"
    );

    if (findObserver(scope) != _observers->end()) {
      RCCFailAssert(@"Attempting to add duplicate observer!");
      return;
    }

    _observers->push_back(ObserverComponentSpec{scope, specCallback});
  };

  void removeObserver(const ScopedResponderAndKey& scope) const
  {
    RCCAssert(
      [NSThread isMainThread],
      @"Triggers are expected to be bound/unbound on the main thread (e.g., from didInit/willDispose lifecycle events)"
    );

    if (findObserver(scope) == _observers->end()) {
      RCCFailAssert(@"Observer not present!");
      return;
    }

    _observers->erase(findObserver(scope));
  };

  auto operator==(const CKTriggerObservable<T...>& rhs) const -> bool {
    return _observers == rhs._observers;
  }

private:
  auto findObserver(const ScopedResponderAndKey& scope) const {
    return std::find_if(_observers->begin(), _observers->end(), [&](const auto& t){ return t.scope == scope; });
  }
};

template<typename... T>
class CKTrigger : public CKTriggerObservable<T...> {
public:
  void operator()(T... args) const
  {
    RCCAssert(
      [NSThread isMainThread],
      @"Triggers are expected to be invoked on the main thread"
    );

    for (const auto &observer : *this->_observers) {
      // Fetch the earliest component that is still alive (same as CKAction).
      id<CKComponentProtocol> updatedComponent = [observer.scope.responder responderForKey:observer.scope.key];
      if (updatedComponent != nil) {
        observer.specCallback(updatedComponent, args...);
      }
    }
  };
};

#endif
