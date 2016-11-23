//
//  CKTypedPropsComponent.h
//  ComponentKit
//
//  Created by Oliver Rickard on 11/22/16.
//
//

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
