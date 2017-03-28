//
//  CKBuildComponent.h
//  ComponentKit
//
//  Created by Oliver Rickard on 3/28/17.
//
//

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKComponentBoundsAnimation.h>

@protocol CKScopedComponent;

@class CKComponentScopeRoot;
@class CKComponent;

struct CKBuildComponentResult {
  CKComponent *component;
  CKComponentScopeRoot *scopeRoot;
  CKComponentBoundsAnimation boundsAnimation;
};

CKBuildComponentResult CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        CKComponent *(^function)(void));
