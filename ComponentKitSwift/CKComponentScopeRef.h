//
//  CKComponentScopeRef.hpp
//  ComponentKit
//
//  Created by Oliver Rickard on 12/11/16.
//
//

#ifndef CKComponentScopeRef_h
#define CKComponentScopeRef_h

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

NS_ASSUME_NONNULL_BEGIN

struct CKComponentScopeRef;
typedef struct CKComponentScopeRef CKComponentScopeRef;

extern CKComponentScopeRef *CKComponentScopeRefCreate(Class __unsafe_unretained componentClass, _Nullable id identifier, id (^_Nullable initialStateCreator)(void));
extern void CKComponentScopeRefDestroy(CKComponentScopeRef *ref);
extern id CKComponentScopeRefGetState(CKComponentScopeRef *ref);

NS_ASSUME_NONNULL_END

#ifdef __cplusplus
}
#endif

#endif /* CKComponentScopeRef_h */
