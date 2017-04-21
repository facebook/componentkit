//
//  CKScrollComponent.m
//  ComponentKit
//
//  Created by Oliver Rickard on 1/31/17.
//
//

#import "CKScrollComponent.h"

#import "CKComponentScope.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKComponentController.h"

@interface CKScrollComponentController : CKComponentController<CKScrollComponent *> <UIScrollViewDelegate>

- (void)triggerContentOffsetChange:(CKComponent *)sender
                     contentOffset:(CGPoint)contentOffset
                          animated:(BOOL)animated;

@end

@interface CKScrollComponent ()

- (const CKScrollComponentConfiguration &)configuration;

@end

@implementation CKScrollComponent
{
  CKScrollComponentConfiguration _configuration;

  CKComponent *_component;
}

+ (instancetype)newWithConfiguration:(const CKScrollComponentConfiguration &)configuration
                          attributes:(const CKViewComponentAttributeValueMap &)passedAttributes
                           component:(CKComponent *)component
{
  CKComponentScope scope(self);
  CKViewComponentAttributeValueMap attributes {
    { @selector(setDirectionalLockEnabled:), (BOOL)configuration.options.directionalLockEnabled },
    { @selector(setBounces:), (BOOL)configuration.options.bounces },
    { @selector(setAlwaysBounceVertical:), (BOOL)configuration.options.alwaysBounceVertical },
    { @selector(setPagingEnabled:), (BOOL)configuration.options.pagingEnabled },
    { @selector(setScrollEnabled:), (BOOL)configuration.options.scrollEnabled },
    { @selector(setShowsHorizontalScrollIndicator:), (BOOL)configuration.options.showsHorizontalScrollIndicator },
    { @selector(setShowsVerticalScrollIndicator:), (BOOL)configuration.options.showsVerticalScrollIndicator },
    { @selector(setScrollIndicatorInsets:), (UIEdgeInsets)configuration.options.scrollIndicatorInsets },
    { @selector(setIndicatorStyle:), (UIScrollViewIndicatorStyle)configuration.options.indicatorStyle },
    { @selector(setDecelerationRate:), (CGFloat)configuration.options.decelerationRate},
    { @selector(setDelaysContentTouches:), (BOOL)configuration.options.delaysContentTouches},
    { @selector(setCanCancelContentTouches:), (BOOL)configuration.options.canCancelContentTouches},
    { @selector(setDelaysContentTouches:), (BOOL)configuration.options.canCancelContentTouches},
    { @selector(setScrollsToTop:), (BOOL)configuration.options.scrollsToTop},
  };

  // Apply the passed attributes after the normal configuration. This allows overriding
  // any values defined in 
  attributes.insert(passedAttributes.begin(), passedAttributes.end());

  CKScrollComponent *c = [super
                          newWithView:{
                            {[UIScrollView class]},
                            std::move(attributes)
                          }
                          size:{}];
  if (c) {
    c->_component = component;
    c->_configuration = configuration;
  }
  return c;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKComponentLayout l = [_component layoutThatFits:{} parentSize:parentSize];
  return {self, constrainedSize.clamp(l.size), {{{0,0}, l}}};
}

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
                              supercomponent:(CKComponent *)supercomponent
{
  CK::Component::MountResult result = [super mountInContext:context
                                                       size:size
                                                   children:children
                                             supercomponent:supercomponent];
  if (children && !children->empty()) {
    [((UIScrollView *)self.viewContext.view) setContentSize:children->at(0).layout.size];
  }
  return result;
}

- (const CKScrollComponentConfiguration &)configuration
{
  return _configuration;
}

@end

@implementation CKScrollComponentController
{
  CGPoint _lastRecordedContentOffset;
}

- (UIScrollView *)scrollView
{
  return (UIScrollView *)self.view;
}

- (void)componentWillRelinquishView
{
  [super componentWillRelinquishView];
  self.scrollView.delegate = nil;
  _lastRecordedContentOffset = self.scrollView.contentOffset;
}

- (void)componentDidAcquireView
{
  [super componentDidAcquireView];
  self.scrollView.delegate = self;
  if (!CGPointEqualToPoint(self.scrollView.contentOffset, _lastRecordedContentOffset)) {
    [self.scrollView setContentOffset:_lastRecordedContentOffset animated:NO];
  }
}

#pragma mark - Triggers

- (void)triggerContentOffsetChange:(CKComponent *)sender
                     contentOffset:(CGPoint)contentOffset
                        animated:(BOOL)animated
{
  CKAssert(self.scrollView, @"Trigger invoked when no scroll view is present");
  [self.scrollView setContentOffset:contentOffset animated:animated];
}

#pragma mark - UIScrollViewDelegate

static CKScrollViewState scrollViewState(UIScrollView *scrollView)
{
  return {
    .contentOffset = scrollView.contentOffset,
    .contentSize = scrollView.contentSize,
    .contentInset = scrollView.contentInset,
    .bounds = scrollView.bounds
  };
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if (self.view && self.component.configuration.scrollViewDidScroll) {
    self.component.configuration.scrollViewDidScroll.send(self.component, scrollViewState(scrollView));
  }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  if (self.view && self.component.configuration.scrollViewWillBeginDragging) {
    self.component.configuration.scrollViewWillBeginDragging.send(self.component, scrollViewState(scrollView));
  }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
  if (self.view && self.component.configuration.scrollViewWillEndDragging) {
    self.component.configuration.scrollViewWillEndDragging.send(self.component, scrollViewState(scrollView), velocity, targetContentOffset);
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
  if (self.view && self.component.configuration.scrollViewDidEndDragging) {
    self.component.configuration.scrollViewDidEndDragging.send(self.component, scrollViewState(scrollView), decelerate);
  }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
  if (self.view && self.component.configuration.scrollViewWillBeginDecelerating) {
    self.component.configuration.scrollViewWillBeginDecelerating.send(self.component, scrollViewState(scrollView));
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  if (self.view && self.component.configuration.scrollViewDidEndDecelerating) {
    self.component.configuration.scrollViewDidEndDecelerating.send(self.component, scrollViewState(scrollView));
  }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
  if (self.view && self.component.configuration.scrollViewDidEndScrollingAnimation) {
    self.component.configuration.scrollViewDidEndScrollingAnimation.send(self.component, scrollViewState(scrollView));
  }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
  BOOL shouldScrollToTop = YES;
  if (self.view && self.component.configuration.scrollViewShouldScrollToTop) {
    self.component.configuration.scrollViewShouldScrollToTop.send(self.component, scrollViewState(scrollView), &shouldScrollToTop);
  }
  return shouldScrollToTop;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
  if (self.view && self.component.configuration.scrollViewDidScrollToTop) {
    self.component.configuration.scrollViewDidScrollToTop.send(self.component, scrollViewState(scrollView));
  }
}

@end
