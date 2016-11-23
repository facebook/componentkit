//
//  CKTestTypedPropsComponent.m
//  ComponentKit
//
//  Created by Oliver Rickard on 11/23/16.
//
//

#import "CKTestTypedPropsComponent.h"

#import "CKTypedPropsComponentSubclass.h"
#import "CKLabelComponent.h"

@implementation CKTestTypedPropsComponent

+ (CKComponent *)renderWithProps:(const CKTypedComponentStruct &)props
                           state:(id)state
                            view:(const CKComponentViewConfiguration &)view
                            size:(const CKComponentSize &)size
{
  const CKTestTypedPropsComponentProps p = props;
  return [CKLabelComponent
          newWithLabelAttributes:{
            .string = p.string,
            .font = p.font
          }
          viewAttributes:*view.attributes()
          size:size];
}

@end
