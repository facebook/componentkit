//
//  CKListComponent.m
//  ComponentKit
//
//  Created by Oliver Rickard on 1/31/17.
//
//

#import "CKListComponent.h"

#import "CKStackLayoutComponent.h"
#import "CKIncrementalMountComponent.h"
#import "CKMemoizingComponent.h"
#import "CKScrollComponent.h"

CKComponent *CKListComponentVerticalStackGenerator(const std::vector<id<NSObject>> &items, id<NSObject> context, const CKListComponentItemComponentGenerator &componentGenerator)
{
  std::vector<CKStackLayoutComponentChild> stackChildren;
  for (const auto &item : items) {
    stackChildren.push_back({componentGenerator(item, context)});
  }
  return [CKStackLayoutComponent
          newWithView:{}
          size:{
            .width = CKRelativeDimension::Percent(1)
          }
          style:{
            .direction = CKStackLayoutDirectionVertical,
            .alignItems = CKStackLayoutAlignItemsStretch
          }
          children:stackChildren];
}

CKComponent *CKListComponentHorizontalStackGenerator(const std::vector<id<NSObject>> &items, id<NSObject> context, const CKListComponentItemComponentGenerator &componentGenerator)
{
  std::vector<CKStackLayoutComponentChild> stackChildren;
  for (const auto &item : items) {
    stackChildren.push_back({componentGenerator(item, context)});
  }
  return [CKStackLayoutComponent
          newWithView:{}
          size:{
            .height = CKRelativeDimension::Percent(1)
          }
          style:{
            .direction = CKStackLayoutDirectionHorizontal,
            .alignItems = CKStackLayoutAlignItemsStretch
          }
          children:stackChildren];
}

@implementation CKListComponent
{
  CKListComponentConfiguration _configuration;
}

+ (instancetype)newWithItems:(const std::vector<id<NSObject>> &)items
                     context:(id<NSObject>)context
               configuration:(const CKListComponentConfiguration &)configuration
{
  CKComponentScope scope(self);

  CKScrollComponentConfiguration scrollConfiguration {configuration.scrollConfiguration};
  scrollConfiguration.scrollViewDidEndDragging = {scope, @selector(scrollViewDidEndDragging:scrollState:willDecelerate:)};

  CKListComponent *c =
  [super newWithComponent:
   [CKScrollComponent
    newWithConfiguration:scrollConfiguration
    attributes:{}
    component:
    [CKIncrementalMountComponent
     newWithComponent:
     (configuration.collectionComponentGenerator ?: CKListComponentVerticalStackGenerator)(items, context, configuration.componentGenerator)]]];
  if (c) {
    c->_configuration = configuration;
  }
  return c;
}

- (void)scrollViewDidEndDragging:(CKComponent *)sender scrollState:(CKScrollViewState)scrollState willDecelerate:(BOOL)willDecelerate
{
  if (scrollState.contentSize.width < scrollState.contentSize.height) {
    if (CGRectGetMaxY(scrollState.bounds) > scrollState.contentSize.height - 2.f * CGRectGetHeight(scrollState.bounds)) {
      if (_configuration.nearingListEndAction) {
        _configuration.nearingListEndAction.send(self);
      }
    }
  } else {
    if (CGRectGetMaxX(scrollState.bounds) > scrollState.contentSize.width - 2.f * CGRectGetWidth(scrollState.bounds)) {
      if (_configuration.nearingListEndAction) {
        _configuration.nearingListEndAction.send(self);
      }
    }
  }
  if (_configuration.scrollConfiguration.scrollViewDidEndDragging) {
    _configuration.scrollConfiguration.scrollViewDidEndDragging.send(sender, scrollState, willDecelerate);
  }
}

@end

@implementation CKListComponentStateWrapper
{
  std::vector<id<NSObject>> _items;
}

- (instancetype)initWithItems:(const std::vector<id<NSObject>> &)items
{
  if (self = [super init]) {
    _items = items;
  }
  return self;
}

- (const std::vector<id<NSObject>> &)items
{
  return _items;
}

@end
