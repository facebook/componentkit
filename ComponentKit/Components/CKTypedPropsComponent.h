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


class CKTypedComponentStruct
{
public:

  CKTypedComponentStruct() : _content(nullptr) {}

  CKTypedComponentStruct(const CKTypedComponentStruct& other) : _content(other._content) {}

  template<class T> CKTypedComponentStruct(const T& value) : _content(std::make_shared<holder<T>>(value)) { }

  class placeholder
  {
  public:
    placeholder() {}
    virtual ~placeholder() {}
  };

  template<typename T> class holder : public placeholder
  {
  public:
    T content;
    holder(const T& value) : content(value) {}
    ~holder<T>() {}
  };

  template<typename T> operator T () const
  {
    return std::dynamic_pointer_cast<holder<T>>(_content)->content;
  }

private:
  std::shared_ptr<placeholder> _content;
};

template <typename T>
struct CKRequiredProp {
  CKRequiredProp<T>() = delete;
  CKRequiredProp<T>(const T &val) : _value(val) {};
  operator T() const {
    return _value;
  }
private:
  T _value;
};

@interface CKTypedPropsComponent : CKComponent

@end
