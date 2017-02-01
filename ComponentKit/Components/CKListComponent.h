//
//  CKListComponent.h
//  ComponentKit
//
//  Created by Oliver Rickard on 1/31/17.
//
//

#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentProvider.h>

struct CKListComponentConfiguration {
  std::function<CKComponent *(id<NSObject> model, id<NSObject> context)> componentGenerator;
  std::function<CKComponent *(const std::vector<CKComponent *> &childComponents, id<NSObject> context)> collectionComponentGenerator;

  CKTypedComponentAction<> nearingListEndAction;
};

@interface CKListComponent : CKCompositeComponent

+ (instancetype)newWithItems:(NSArray *)items
                     context:(id<NSObject>)context
               configuration:(const CKListComponentConfiguration &)configuration;

@end
