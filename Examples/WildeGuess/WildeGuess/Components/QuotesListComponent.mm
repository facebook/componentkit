//
//  QuotesListComponent.m
//  WildeGuess
//
//  Created by Oliver Rickard on 2/1/17.
//
//

#import "QuotesListComponent.h"

#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKListComponent.h>
#import <ComponentKit/CKStackLayoutComponent.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKUniqueComponent.h>

#import "QuoteComponent.h"
#import "QuoteModelController.h"
#import "QuotesPage.h"
#import "QuoteContext.h"
#import "InteractiveQuoteComponent.h"
#import "Quote.h"
#import "LoadingIndicatorComponent.h"

@interface QuotesListComponentController : CKComponentController<QuotesListComponent *>

- (void)loadMore;

@end

@implementation QuotesListComponent

+ (id)initialState
{
  return [CKListComponentStateWrapper new];
}

+ (instancetype)newWithQuoteContext:(QuoteContext *)quoteContext
                          direction:(CKStackLayoutDirection)direction
{
  CKComponentScope scope(self);

  CKListComponentStateWrapper *wrapper = scope.state();

  return [super newWithComponent:
          [CKListComponent
           newWithItems:wrapper.items
           context:quoteContext
           configuration:{
             .componentGenerator = [](id<NSObject> model, id<NSObject> context) -> CKComponent * {
               return [InteractiveQuoteComponent newWithQuote:(Quote *)model
                                                      context:(QuoteContext *)context];
             },
             .collectionComponentGenerator = [](const std::vector<id<NSObject>> &items, id<NSObject> context, const CKListComponentItemComponentGenerator &componentGenerator)
             {
               std::vector<CKStackLayoutComponentChild> stackChildren;
               for (const auto &item : items) {
                 stackChildren.push_back({componentGenerator(item, context)});
               }
               stackChildren.push_back({[LoadingIndicatorComponent new]});
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
             },
             .nearingListEndAction = {scope, @selector(loadMore)}
           }]];
}

@end

@implementation QuotesListComponentController
{
  BOOL _isLoading;
  QuoteModelController *_modelController;
}

- (instancetype)initWithComponent:(QuotesListComponent *)component
{
  if (self = [super initWithComponent:component]) {
    _modelController = [[QuoteModelController alloc] init];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self loadMore];
    });
  }
  return self;
}

- (void)loadMore
{
  if (_isLoading) {
    return;
  }
  _isLoading = YES;
  [self.component updateState:^CKListComponentStateWrapper *(CKListComponentStateWrapper *wrapper) {
    _isLoading = NO;
    std::vector<id<NSObject>> copied = wrapper.items;
    NSArray *quotes = [_modelController fetchNewQuotesPageWithCount:20].quotes;
    for (Quote *quote in quotes) {
      copied.push_back(quote);
    }
    return [[CKListComponentStateWrapper alloc] initWithItems:copied];
  } mode:CKUpdateModeAsynchronous];
}

@end
