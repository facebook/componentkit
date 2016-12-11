//
//  CKComponentViewConfigurationRef.m
//  ComponentKit
//
//  Created by Oliver Rickard on 12/11/16.
//
//

#import "CKComponentViewConfigurationRef.h"

#import "CKComponentViewConfiguration.h"



CKViewComponentAttributeValueMapRef *CKViewComponentAttributeValueMapRefCreate()
{
  return reinterpret_cast<CKViewComponentAttributeValueMapRef *>(new CKViewComponentAttributeValueMap());
}

void CKViewComponentAttributeValueMapRefAddAttribute(CKViewComponentAttributeValueMapRef *ref, SEL selector, id value)
{
  CKViewComponentAttributeValueMap *map = reinterpret_cast<CKViewComponentAttributeValueMap *>(ref);
  map->insert({selector, value});
}

void CKViewComponentAttributeValueMapRefDestroy(CKViewComponentAttributeValueMapRef *ref)
{
  delete reinterpret_cast<CKViewComponentAttributeValueMap *>(ref);
}

CKComponentViewConfigurationRef *CKComponentViewConfigurationRefCreate(Class viewClass, CKViewComponentAttributeValueMapRef *viewAttributes)
{
  CKViewComponentAttributeValueMap map = *reinterpret_cast<CKViewComponentAttributeValueMap *>(viewAttributes);
  return reinterpret_cast<CKComponentViewConfigurationRef *>(new CKComponentViewConfiguration(viewClass, std::move(map)));
}

void CKComponentViewConfigurationRefDestroy(CKComponentViewConfigurationRef *ref) {
  delete reinterpret_cast<CKComponentViewConfiguration *>(ref);
}


