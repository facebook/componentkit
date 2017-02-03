//
//  QuotesListComponent.h
//  WildeGuess
//
//  Created by Oliver Rickard on 2/1/17.
//
//

#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKStackLayoutComponent.h>

@class QuoteContext;

@interface QuotesListComponent : CKCompositeComponent

+ (instancetype)newWithQuoteContext:(QuoteContext *)quoteContext
                          direction:(CKStackLayoutDirection)direction;

@end
