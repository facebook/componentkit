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
#import <stdlib.h>
#import <string.h>
#import <objc/runtime.h>
#import <unordered_map>

#import <UIKit/UIKit.h>
#import <ComponentKit/CKEqualityHashHelpers.h>
#import <ComponentKit/ComponentViewReuseUtilities.h>

struct CKComponentViewClassIdentifier {
  enum IdentifierType : char {
    EMPTY_IDENTIFIER,
    CLASS_BASED_IDENTIFIER,
    FUNCTION_BASED_IDENTIFIER,
    STRING_BASED_IDENTIFIER
  };
  
  CKComponentViewClassIdentifier() noexcept
    : ptr1(nullptr), ptr2(nullptr), ptr3(nullptr) {}

  CKComponentViewClassIdentifier(CKComponentViewClassIdentifier &&other) noexcept
  : ptr1(other.ptr1), ptr2(other.ptr2), ptr3(std::exchange(other.ptr3, nullptr)), identifierType(other.identifierType) {}

  CKComponentViewClassIdentifier(const CKComponentViewClassIdentifier &other) noexcept
    : ptr1(other.ptr1), ptr2(other.ptr2), ptr3(other.identifierType == STRING_BASED_IDENTIFIER ? strdup((const char *)other.ptr3) : other.ptr3), identifierType(other.identifierType)
  {
  }

  CKComponentViewClassIdentifier(const char *stringIdentifier) noexcept
    : ptr1(nullptr), ptr2(nullptr), ptr3(strdup(stringIdentifier)), identifierType(STRING_BASED_IDENTIFIER) {}
  
  CKComponentViewClassIdentifier(Class viewClass, SEL enter = NULL, SEL leave = NULL) noexcept
    : ptr1(class_getName(viewClass)), ptr2(sel_getName(enter)), ptr3(sel_getName(leave)), identifierType(CLASS_BASED_IDENTIFIER) {}
  
  CKComponentViewClassIdentifier(UIView *(*fact)(void), SEL enter = NULL, SEL leave = NULL) noexcept
    : ptr1((void*)(fact)), ptr2(sel_getName(enter)), ptr3(sel_getName(leave)), identifierType(FUNCTION_BASED_IDENTIFIER) {}
  
  ~CKComponentViewClassIdentifier()
  {
    if (this->identifierType == STRING_BASED_IDENTIFIER) {
      free(const_cast<char *>((char *)this->ptr3));
    }
  }
  
  std::string description() const;
  
  CKComponentViewClassIdentifier& operator=(const CKComponentViewClassIdentifier& other) noexcept {
    if (this != &other) {
      if (identifierType == STRING_BASED_IDENTIFIER) {
        free(const_cast<char *>((char *)this->ptr3));
      }
      
      identifierType = other.identifierType;
      ptr1 = other.ptr1;
      ptr2 = other.ptr2;
      
      if (other.identifierType == STRING_BASED_IDENTIFIER) {
        ptr3 = strdup((const char *)other.ptr3);
      } else {
        ptr3 = other.ptr3;
      }
    }
    return *this;
  }
  
  CKComponentViewClassIdentifier& operator=(CKComponentViewClassIdentifier&& other) noexcept {
    if (this != &other) {
      if (identifierType == STRING_BASED_IDENTIFIER) {
        free(const_cast<char *>((char *)this->ptr3));
      }
      
      identifierType = other.identifierType;
      ptr1 = other.ptr1;
      ptr2 = other.ptr2;
      ptr3 = std::exchange(other.ptr3, nullptr);
    }
    return *this;
  }
  
  bool operator==(const CKComponentViewClassIdentifier &other) const noexcept {
    if (identifierType != other.identifierType) {
      return false;
    }
    if (identifierType == STRING_BASED_IDENTIFIER) {
      if (ptr3 == other.ptr3) {
        return true;
      }
      else if (ptr3 == nullptr || other.ptr3 == nullptr) {
        return false;
      }
      return strcmp((const char *)ptr3, (const char *)other.ptr3) == 0;
    } else {
      return other.ptr1 == ptr1 && other.ptr2 == ptr2 && other.ptr3 == ptr3;
    }
  }
  
  bool operator!=(const CKComponentViewClassIdentifier &other) const noexcept {
    return !operator==(other);
  }
    
  size_t hash() const noexcept {
    if (identifierType == STRING_BASED_IDENTIFIER) {
      return CKHash64ToNative(CKHashCString((const char *)this->ptr3));
    } else {
      return CKHash64ToNative(identifierType == STRING_BASED_IDENTIFIER
        ? std::hash<uint64_t>()((uint64_t)this->ptr3)
        : CKHashCombine(std::hash<uint64_t>()((uint64_t)this->ptr1), (uint64_t)this->ptr2));
    }
  }
  
private:
  const void *ptr1;
  const void *ptr2;
  const void *ptr3;
  IdentifierType identifierType;
};

namespace std {
  template<> struct hash<CKComponentViewClassIdentifier>
  {
    size_t operator()(const CKComponentViewClassIdentifier &cl) const
    {
      return cl.hash();
    }
  };
}

typedef UIView *(^CKComponentViewFactoryBlock)(void);
typedef UIView *(*CKComponentViewFactoryFunc)(void);

class CKComponentDebugConfiguration;
typedef void (^CKComponentViewReuseBlock)(UIView *);

struct CKComponentViewClass {
  
  /**
   The no-argument default constructor, which specifies that the component should not have a corresponding view.
   */
  CKComponentViewClass() noexcept;
  
  /**
   Specifies that the component should have a view of the given class. The class will be instantiated with UIView's
   designated initializer -initWithFrame:.
   */
  CKComponentViewClass(Class viewClass) noexcept;
  
  /**
   A variant that allows you to specify two selectors that are sent as a view is hidden/unhidden for future reuse.
   Note that a view can be reused but not hidden so never enters the pool (in which case these selectors won't be sent).
   @param didEnterReusePoolMessage Sent to the view just after it has been hidden for future reuse.
   @param willLeaveReusePoolMessage Sent to the view just before it is revealed after being reused.
   */
  CKComponentViewClass(Class viewClass, SEL didEnterReusePoolMessage, SEL willLeaveReusePoolMessage) noexcept;
  
  /**
   Specifies a view class that cannot be instantiated with -initWithFrame:.
   Allows you to specify two blocks that are invoked as a view is hidden/unhidden for future reuse.
   Note that a view can be reused but not hidden so never enters the pool (in which case these blocks won't be invoked).
   @param factory A pointer to a function that returns a new instance of a view.
   @param didEnterReusePool Executed after a view has been hidden for future reuse.
   @param willLeaveReusePool Executed just before a view is revealed after being reused.
   */
  CKComponentViewClass(CKComponentViewFactoryFunc factory,
                       CKComponentViewReuseBlock didEnterReusePool = nil,
                       CKComponentViewReuseBlock willLeaveReusePool = nil) noexcept;
  
  /** Invoked by the infrastructure to create a new instance of the view. You should not call this directly. */
  UIView *createView() const;
  
  /** Invoked by the infrastructure to determine if this will create a view or not. */
  BOOL hasView() const;
  
  bool operator==(const CKComponentViewClass &other) const noexcept
  {
    if (usingStringIdentifier) {
      return other.stringIdentifier == stringIdentifier;
    } else {
      return other.identifier == identifier;
    }
  }
  
  bool operator!=(const CKComponentViewClass &other) const noexcept
  {
    if (usingStringIdentifier) {
      return other.stringIdentifier != stringIdentifier;
    } else {
      return other.identifier != identifier;
    }
  }
  
  const CKComponentViewClassIdentifier &getIdentifier() const noexcept { return identifier; }
  const std::string &getStringIdentifier() const noexcept { return stringIdentifier; }
  
  const std::string getIdentifierDescription() const noexcept
  {
    if (usingStringIdentifier) {
      return stringIdentifier;
    } else {
      return identifier.description();
    }
  }
  
  size_t hash() const
  {
    if (usingStringIdentifier) {
      return std::hash<std::string>()(stringIdentifier);
    } else {
      return std::hash<CKComponentViewClassIdentifier>()(identifier);
    }
  }
  
private:
  CKComponentViewClass(const std::string &ident,
                       CKComponentViewFactoryBlock factory,
                       CKComponentViewReuseBlock didEnterReusePool = nil,
                       CKComponentViewReuseBlock willLeaveReusePool = nil) noexcept;
  
  bool usingStringIdentifier;
  std::string stringIdentifier;
  CKComponentViewClassIdentifier identifier;
  UIView *(^factory)(void);
  CKComponentViewReuseBlock didEnterReusePool;
  CKComponentViewReuseBlock willLeaveReusePool;
  friend class CK::Component::ViewReuseUtilities;
};

namespace std {
  template<> struct hash<CKComponentViewClass>
  {
    size_t operator()(const CKComponentViewClass &cl) const
    {
      return cl.hash();
    }
  };
}
