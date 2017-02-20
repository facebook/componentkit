/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <string>
#import <type_traits>
#import <typeinfo>
#import <unordered_map>
#import <vector>

#import <UIKit/UIKit.h>
#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKEqualityHashHelpers.h>

namespace CK {
  namespace ViewAttribute {

    // Singleton object to signify non-ID-type object. For internal use only.
    extern id nonIDObject;

    /**
     An abstract base type for the value type.
     */
    struct ValueBase
    {
      ValueBase(std::string typeName) : _typeName(typeName) {}
      ValueBase(const ValueBase &) = delete;
      ~ValueBase() {}

      virtual operator id() const = 0;
      virtual size_t hash() const noexcept = 0;
      virtual BOOL isEqualTo(const ValueBase &) const = 0;
      virtual void performSetter(id object, SEL setter) const = 0;

      const std::string typeName() const
      {
        return _typeName;
      }

    protected:
      const std::string _typeName;
    };

    /**
     Templated type used to store an underlying value.
     */
    template<typename T> struct Value : ValueBase
    {
      Value(const T &value) : ValueBase(typeid(Value<T>).name()), _value(value) {}
      Value(const Value<T> &) = delete;
      ~Value() {}

      operator const T() const
      {
        return _value;
      }

      operator id() const
      {
        return nonIDObject;
      }

      template<typename U> operator const Value<U>() const
      {
        return Value<U>(_value);
      }

      size_t hash() const noexcept
      {
        return CK::hash<T>()(_value);
      }

      BOOL isEqualTo(const ValueBase &other) const
      {
        return this->typeName() == other.typeName() && CK::is_equal<T>()(_value, static_cast<const Value<T> &>(other)._value);
      }

      void performSetter(id object, SEL setter) const
      {
        const auto setterIMP = (void (*)(id, SEL, T))[object methodForSelector:setter];
#if DEBUG
        const auto setterSignature = [object methodSignatureForSelector:setter];
        const std::string argumentType = [setterSignature getArgumentTypeAtIndex:2];
        CKCAssert(argumentType.find(@encode(T)) != std::string::npos, @"Setter's argument and current value are of different types.");
#endif
        setterIMP(object, setter, _value);
      }

    private:
      T _value;
    };

    /**
     Template specialization for ID types.
     */
    template<> struct Value<id> : ValueBase
    {
      Value(const id &value) : ValueBase(typeid(Value<id>).name()), _value(value) {}
      Value(const Value<id> &) = delete;
      ~Value() {}

      operator id() const
      {
        return _value;
      }

      size_t hash() const noexcept
      {
        return CK::hash<id>()(_value);
      }

      BOOL isEqualTo(const ValueBase &other) const
      {
        return this->typeName() == other.typeName() && CK::is_equal<id>()(_value, static_cast<const Value<id> &>(other)._value);
      }

      void performSetter(id object, SEL setter) const;
      
    private:
      id _value;
    };

    /**
     NSValue conversions from primitives for backwards compatibility.
     */
    template<> extern Value<bool>::operator id() const;
    template<> extern Value<int8_t>::operator id() const;
    template<> extern Value<uint8_t>::operator id() const;
    template<> extern Value<int16_t>::operator id() const;
    template<> extern Value<uint16_t>::operator id() const;
    template<> extern Value<int32_t>::operator id() const;
    template<> extern Value<uint32_t>::operator id() const;
    template<> extern Value<int64_t>::operator id() const;
    template<> extern Value<uint64_t>::operator id() const;
    template<> extern Value<long>::operator id() const;
    template<> extern Value<unsigned long>::operator id() const;
    template<> extern Value<float>::operator id() const;
    template<> extern Value<double>::operator id() const;
    template<> extern Value<SEL>::operator id() const;
    template<> extern Value<CGRect>::operator id() const;
    template<> extern Value<CGPoint>::operator id() const;
    template<> extern Value<CGSize>::operator id() const;
    template<> extern Value<UIEdgeInsets>::operator id() const;
    template<> extern Value<CGAffineTransform>::operator id() const;
    template<> extern Value<CATransform3D>::operator id() const;

    /**
     Non-templated value wrappers to be used for component view attributes.
     */
    struct BoxedValue {
      BoxedValue() : _value(std::make_shared<Value<id>>(nil)) {}

      template <typename T, typename = typename std::enable_if<!std::is_convertible<T, id>::value>::type>
      BoxedValue(const T &value) : _value(std::make_shared<Value<T>>(value)) {}

      BoxedValue(const id &value) : _value(std::make_shared<Value<id>>(value)) {}

      BoxedValue(const BoxedValue &other) : _value(other._value) {}

      ~BoxedValue() {}

      BoxedValue operator=(const BoxedValue &other)
      {
        _value = other._value;
        return *this;
      }

      template <typename T, typename = typename std::enable_if<!std::is_convertible<T, id>::value>::type>
      operator T() const
      {
        return static_cast<const Value<T> &>(*_value);
      }

      operator id() const
      {
        id const idObject = *_value;
        if (idObject != nonIDObject) {
          return idObject;
        }
        CKCFailAssert(@"value isn't an ID type object.");
        return nil;
      }

      size_t hash() const noexcept
      {
        return _value->hash();
      }

      BOOL operator==(const BoxedValue &other) const
      {
        return _value->isEqualTo(*other._value);
      }

      BOOL operator!=(const BoxedValue &other) const
      {
        return !(*this == other);
      }

      void performSetter(id object, SEL setter) const
      {
        _value->performSetter(object, setter);
      }

    private:
      std::shared_ptr<ValueBase> _value;
    };
    
  }
}

/**
 View attributes usually correspond to properties (like background color or alpha) but can represent arbitrarily complex
 operations on the view.
 */
struct CKComponentViewAttribute {

  using ApplicatorFunc = std::function<void (id, CK::ViewAttribute::BoxedValue)>;
  using UpdaterFunc = std::function<void (id, CK::ViewAttribute::BoxedValue, CK::ViewAttribute::BoxedValue)>;

  /**
   The most common way to specify an attribute is by using a SEL corresponding to a setter, e.g. @selector(setColor:).
   This single-argument constructor allows implicit conversions, so you can pass a SEL as an attribute without actually
   typing CKComponentViewAttribute().
   */
  CKComponentViewAttribute(SEL setter) noexcept;
  /**
   Constructor for complex attributes.

   @param ident A unique identifier for the attribute, used by the infrastructure to distinguish them internally.
   @param app   An "applicator" for the attribute. If the value of an attribute differs from the previously applied
   value for a recycled view (or if the view is newly created), the applicator is called with the view
   and the attribute's value.
   @param unapp An optional "un-applicator". This is called when a view that had an applicator is being reused. This
   is where you do teardown that requires more than just the next applicator smashing over an
   old value. Note: the unapplicator will not be called before a view is released.
   @param upd   An optional "updater". This may be used as an advanced performance optimization if you can reconfigure
   the view more efficiently if you know the previous value.

   This diagram summarizes the behaviors of unapplicator and updater in combination:

   |--------|----------|-----------------------------------------------------------------------------------------------|
   | unapp? | updater? | Behavior                                                                                      |
   |--------|----------|-----------------------------------------------------------------------------------------------|
   | no     | no       | Views cannot be recycled to show components that do not have the attribute.                   |
   |        |          | In almost all cases, this is the best option.                                                 |
   |--------|----------|-----------------------------------------------------------------------------------------------|
   | yes    | no       | Unapplic. is called if the view is being recycled to show a component without the attribute,  |
   |        |          | or if the value of the attribute has changed (followed by applicator with new value).         |
   |--------|----------|-----------------------------------------------------------------------------------------------|
   | no     | yes      | Views cannot be recycled to show components that do not have the attribute.                   |
   |        |          | Applicator is called first time; subsequently, updater is called if the value changes.        |
   |--------|----------|-----------------------------------------------------------------------------------------------|
   | yes    | yes      | Unapplic. is called if the view is being recycled to show a component without the attribute.  |
   |        |          | Updater is called if the attribute was previously applied and the value changes.              |
   |--------|----------|-----------------------------------------------------------------------------------------------|
   */
  template <typename AppFunc, typename UpdFunc>
  CKComponentViewAttribute(const std::string &ident, AppFunc app, AppFunc unapp, UpdFunc upd) :
  identifier(ident),
  applicator([=](id view, CK::ViewAttribute::BoxedValue value){ app(view, value); }),
  unapplicator([=](id view, CK::ViewAttribute::BoxedValue value){ unapp(view, value); }),
  updater([=](id view, CK::ViewAttribute::BoxedValue oldValue, CK::ViewAttribute::BoxedValue newValue){ upd(view, oldValue, newValue); }) {};

  template <typename AppFunc, typename UpdFunc>
  CKComponentViewAttribute(const std::string &ident, AppFunc app, std::nullptr_t unapp, UpdFunc upd) :
  identifier(ident),
  applicator([=](id view, CK::ViewAttribute::BoxedValue value){ app(view, value); }),
  unapplicator(nullptr),
  updater([=](id view, CK::ViewAttribute::BoxedValue oldValue, CK::ViewAttribute::BoxedValue newValue){ upd(view, oldValue, newValue); }) {};

  template <typename AppFunc>
  CKComponentViewAttribute(const std::string &ident, AppFunc app, AppFunc unapp, std::nullptr_t upd = nil) :
  identifier(ident),
  applicator([=](id view, CK::ViewAttribute::BoxedValue value){ app(view, value); }),
  unapplicator([=](id view, CK::ViewAttribute::BoxedValue value){ unapp(view, value); }),
  updater(nullptr) {};

  template <typename AppFunc>
  CKComponentViewAttribute(const std::string &ident, AppFunc app, std::nullptr_t unapp = nil, std::nullptr_t upd = nil) :
  identifier(ident),
  applicator([=](id view, CK::ViewAttribute::BoxedValue value){ app(view, value); }),
  unapplicator(nullptr),
  updater(nullptr) {};

  ~CKComponentViewAttribute();

  /**
   Creates an attribute that invokes the given setter on the view's layer (rather than the view itself). Useful for
   easy access to layer properties, e.g. @selector(setBorderColor:), @selector(setAnchorPoint:), and so on.
   */
  static CKComponentViewAttribute LayerAttribute(SEL setter) noexcept;

  std::string identifier;
  ApplicatorFunc applicator;
  ApplicatorFunc unapplicator;
  UpdaterFunc updater;

  bool operator==(const CKComponentViewAttribute &attr) const { return identifier == attr.identifier; };
};

typedef std::unordered_map<CKComponentViewAttribute, CK::ViewAttribute::BoxedValue> CKViewComponentAttributeValueMap;

namespace std {

  template<> struct hash<CKComponentViewAttribute>
  {
    size_t operator()(const CKComponentViewAttribute &attr) const noexcept
    {
      return hash<std::string>()(attr.identifier);
    }
  };
}
/**
 This typedef is provided for convenience for helper functions that return both an attribute and a value, ready-made
 for dropping into the initialization list for attributes.
 e.g: It is currently used in CKComponentViewConfiguration, CKComponentViewConfiguration.attribute is of type
 std::unordered_map<CKComponentViewAttribute, id> (CKViewComponentAttributeValueMap). Its aggregate initialization
 constructor takes a list of std::pair<CKComponentViewAttribute, id>.
 */
typedef CKViewComponentAttributeValueMap::value_type CKComponentViewAttributeValue;

namespace std {

  template<> struct hash<CKViewComponentAttributeValueMap>
  {
    size_t operator()(const CKViewComponentAttributeValueMap &attr) const noexcept
    {
      uint64_t hash = 0;
      for (const auto& it: attr) {
        hash = CKHashCombine(hash, std::hash<CKComponentViewAttribute>()(it.first));
        hash = CKHashCombine(hash, it.second.hash());
      }
      return CKHash64ToNative(hash);
    }
  };

}

// Explicitly instantiate these types to improve compile time.
extern template class std::unordered_map<CKComponentViewAttribute, CK::ViewAttribute::BoxedValue>;

extern template class CK::ViewAttribute::Value<id>;
extern template class CK::ViewAttribute::Value<bool>;
extern template class CK::ViewAttribute::Value<int8_t>;
extern template class CK::ViewAttribute::Value<uint8_t>;
extern template class CK::ViewAttribute::Value<int16_t>;
extern template class CK::ViewAttribute::Value<uint16_t>;
extern template class CK::ViewAttribute::Value<int32_t>;
extern template class CK::ViewAttribute::Value<uint32_t>;
extern template class CK::ViewAttribute::Value<int64_t>;
extern template class CK::ViewAttribute::Value<uint64_t>;
extern template class CK::ViewAttribute::Value<long>;
extern template class CK::ViewAttribute::Value<unsigned long>;
extern template class CK::ViewAttribute::Value<float>;
extern template class CK::ViewAttribute::Value<double>;
extern template class CK::ViewAttribute::Value<SEL>;
extern template class CK::ViewAttribute::Value<CGRect>;
extern template class CK::ViewAttribute::Value<CGPoint>;
extern template class CK::ViewAttribute::Value<CGSize>;
extern template class CK::ViewAttribute::Value<UIEdgeInsets>;
extern template class CK::ViewAttribute::Value<CGAffineTransform>;
extern template class CK::ViewAttribute::Value<CATransform3D>;

extern template CK::ViewAttribute::BoxedValue::BoxedValue(const bool &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const int8_t &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const uint8_t &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const int16_t &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const uint16_t &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const int32_t &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const uint32_t &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const int64_t &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const uint64_t &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const long &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const unsigned long &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const float &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const double &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const SEL &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const CGRect &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const CGPoint &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const CGSize &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const UIEdgeInsets &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const CGAffineTransform &);
extern template CK::ViewAttribute::BoxedValue::BoxedValue(const CATransform3D &);
