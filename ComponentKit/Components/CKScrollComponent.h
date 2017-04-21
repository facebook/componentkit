//
//  CKScrollComponent.h
//  ComponentKit
//
//  Created by Oliver Rickard on 1/31/17.
//
//

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentAction.h>
#import <ComponentKit/CKComponentOptionUtilities.h>

struct CKScrollViewState {
  CGPoint contentOffset;
  CGSize contentSize;
  UIEdgeInsets contentInset;
  CGRect bounds;
};

@protocol CKScrollComponentMutationHandle <NSObject>

- (void)setScrollViewState:(const CKScrollViewState &)scrollViewState;

@end

struct CKScrollComponentOptions {
  CKOptionalValue<UIEdgeInsets, UIEdgeInsetsZero> contentInset;

  CKOptionalPrimitiveValue<BOOL, NO> directionalLockEnabled;

  CKOptionalPrimitiveValue<BOOL, YES> bounces;
  CKOptionalPrimitiveValue<BOOL, NO> alwaysBounceVertical;

  CKOptionalPrimitiveValue<BOOL, NO> pagingEnabled;
  CKOptionalPrimitiveValue<BOOL, YES> scrollEnabled;

  CKOptionalPrimitiveValue<BOOL, YES> showsHorizontalScrollIndicator;
  CKOptionalPrimitiveValue<BOOL, YES> showsVerticalScrollIndicator;
  CKOptionalValue<UIEdgeInsets, UIEdgeInsetsZero> scrollIndicatorInsets;
  CKOptionalPrimitiveValue<UIScrollViewIndicatorStyle, UIScrollViewIndicatorStyleDefault> indicatorStyle;

  CKOptionalValue<CGFloat, UIScrollViewDecelerationRateNormal> decelerationRate;

  CKOptionalPrimitiveValue<BOOL, YES> delaysContentTouches;
  CKOptionalPrimitiveValue<BOOL, YES> canCancelContentTouches;

  CKOptionalPrimitiveValue<BOOL, YES> scrollsToTop;
};

struct CKScrollComponentConfiguration {
  CKScrollComponentOptions options;

  CKTypedComponentAction<CKScrollViewState> scrollViewDidScroll;
  CKTypedComponentAction<CKScrollViewState> scrollViewWillBeginDragging;
  /** 
   CGPoint parameter is scrollVelocity
   CGPoint * parameter is the inout CGPoint for the targetContentOffset
   */
  CKTypedComponentAction<CKScrollViewState, CGPoint, CGPoint *> scrollViewWillEndDragging;
  /**
   BOOL parameter is willDecelerate
   */
  CKTypedComponentAction<CKScrollViewState, BOOL> scrollViewDidEndDragging;
  CKTypedComponentAction<CKScrollViewState> scrollViewWillBeginDecelerating;
  CKTypedComponentAction<CKScrollViewState> scrollViewWillBeginDeclerating;
  CKTypedComponentAction<CKScrollViewState> scrollViewDidEndDecelerating;
  CKTypedComponentAction<CKScrollViewState> scrollViewDidEndScrollingAnimation;
  /**
   BOOL parameter is an out parameter to determine if scroll view should scroll to top. Only called if scrollsToTop in the options struct is YES.
   */
  CKTypedComponentAction<CKScrollViewState, BOOL *> scrollViewShouldScrollToTop;
  CKTypedComponentAction<CKScrollViewState> scrollViewDidScrollToTop;
};

@interface CKScrollComponent : CKComponent

+ (instancetype)newWithConfiguration:(const CKScrollComponentConfiguration &)configuration
                          attributes:(const CKViewComponentAttributeValueMap &)attributes
                           component:(CKComponent *)component;

@end
