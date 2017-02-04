//
//  CKListComponent.h
//  ComponentKit
//
//  Created by Oliver Rickard on 1/31/17.
//
//

#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKScrollComponent.h>

typedef std::function<CKComponent *(id<NSObject> model, id<NSObject> context)> CKListComponentItemComponentGenerator;
typedef std::function<CKComponent *(const std::vector<id<NSObject>> &items, id<NSObject> context, const CKListComponentItemComponentGenerator &componentGenerator)> CKListCollectionComponentGenerator;

CKComponent *CKListComponentVerticalStackGenerator(const std::vector<id<NSObject>> &items, id<NSObject> context, const CKListComponentItemComponentGenerator &componentGenerator);
CKComponent *CKListComponentHorizontalStackGenerator(const std::vector<id<NSObject>> &items, id<NSObject> context, const CKListComponentItemComponentGenerator &componentGenerator);

struct CKListComponentConfiguration {
  CKListComponentItemComponentGenerator componentGenerator;
  CKListCollectionComponentGenerator collectionComponentGenerator;

  CKScrollComponentConfiguration scrollConfiguration;

  CKTypedComponentAction<> nearingListEndAction;
};

@interface CKListComponent : CKCompositeComponent

+ (instancetype)newWithItems:(const std::vector<id<NSObject>> &)items
                     context:(id<NSObject>)context
               configuration:(const CKListComponentConfiguration &)configuration;

@end

@interface CKListComponentStateWrapper : NSObject

- (instancetype)initWithItems:(const std::vector<id<NSObject>> &)items;
- (const std::vector<id<NSObject>> &)items;

@end
