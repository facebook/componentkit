//
//  CKComponentScopeRef.cpp
//  ComponentKit
//
//  Created by Oliver Rickard on 12/11/16.
//
//

#include "CKComponentScopeRef.h"

#import "CKComponentScope.h"

CKComponentScopeRef *CKComponentScopeRefCreate(Class __unsafe_unretained componentClass, id identifier, id (^initialStateCreator)(void))
{
  return reinterpret_cast<CKComponentScopeRef *>(new CKComponentScope(componentClass, identifier, initialStateCreator));
}

void CKComponentScopeRefDestroy(CKComponentScopeRef *ref)
{
  delete reinterpret_cast<CKComponentScope *>(ref);
}

id CKComponentScopeRefGetState(CKComponentScopeRef *ref)
{
  return reinterpret_cast<CKComponentScope *>(ref)->state();
}
