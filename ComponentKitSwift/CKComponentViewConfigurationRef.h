//
//  CKComponentViewConfigurationRef.h
//  ComponentKit
//
//  Created by Oliver Rickard on 12/11/16.
//
//

#ifndef CKComponentViewConfigurationRef_h
#define CKComponentViewConfigurationRef_h

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

struct CKViewComponentAttributeValueMapRef;
typedef struct CKViewComponentAttributeValueMapRef CKViewComponentAttributeValueMapRef;

CKViewComponentAttributeValueMapRef *CKViewComponentAttributeValueMapRefCreate();
void CKViewComponentAttributeValueMapRefAddAttribute(CKViewComponentAttributeValueMapRef *ref, SEL selector, id value);
void CKViewComponentAttributeValueMapRefDestroy(CKViewComponentAttributeValueMapRef *ref);

struct CKComponentViewConfigurationRef;
typedef struct CKComponentViewConfigurationRef CKComponentViewConfigurationRef;

CKComponentViewConfigurationRef *CKComponentViewConfigurationRefCreate(Class viewClass, CKViewComponentAttributeValueMapRef *viewAttributes);

void CKComponentViewConfigurationRefDestroy(CKComponentViewConfigurationRef *ref);

#ifdef __cplusplus
}
#endif

#endif /* CKComponentViewConfigurationRef_h */