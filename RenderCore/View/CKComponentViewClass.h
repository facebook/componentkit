/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#import <string>
#import <stdlib.h>
#import <string.h>
#import <objc/runtime.h>
#import <unordered_map>

#import <UIKit/UIKit.h>
#import <RenderCore/CKEqualityHelpers.h>
#import <RenderCore/ComponentViewReuseUtilities.h>

struct CKComponentViewClassIdentifier {
  enum IdentifierType : char {
    EMPTY_IDENTIFIER,
    CLASS_BASED_IDENTIFIER,
    FUNCTION_BASED_IDENTIFIER
  };

  CKComponentViewClassIdentifier() noexcept
    : ptr1(nullptr), ptr2(nullptr), ptr3(nullptr), identifierType(EMPTY_IDENTIFIER) {}

  CKComponentViewClassIdentifier(Class viewClass, SEL enter = NULL, SEL leave = NULL) noexcept
    : ptr1(class_getName(viewClass)), ptr2(sel_getName(enter)), ptr3(sel_getName(leave)), identifierType(CLASS_BASED_IDENTIFIER) {}

  CKComponentViewClassIdentifier(UIView *(*fact)(void), SEL enter = NULL, SEL leave = NULL) noexcept
    : ptr1((void*)(fact)), ptr2(sel_getName(enter)), ptr3(sel_getName(leave)), identifierType(FUNCTION_BASED_IDENTIFIER) {}

  std::string description() const;

  bool operator==(const CKComponentViewClassIdentifier &other) const noexcept {
    return identifierType == other.identifierType && other.ptr1 == ptr1 && other.ptr2 == ptr2 && other.ptr3 == ptr3;
  }

  bool operator!=(const CKComponentViewClassIdentifier &other) const noexcept {
    return !operator==(other);
  }

  size_t hash() const noexcept {
    return CKHash64ToNative(CKHashCombine(std::hash<uint64_t>()((uint64_t)this->ptr1), (uint64_t)this->ptr2));
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
    return other.identifier == identifier;
  }

  bool operator!=(const CKComponentViewClass &other) const noexcept
  {
    return other.identifier != identifier;
  }

  const CKComponentViewClassIdentifier &getIdentifier() const noexcept { return identifier; }

  size_t hash() const
  {
    return std::hash<CKComponentViewClassIdentifier>()(identifier);
  }

private:

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

#endif
