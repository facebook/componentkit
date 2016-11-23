//
//  Header.h
//  ComponentKit
//
//  Created by Oliver Rickard on 11/23/16.
//
//

#import <ComponentKit/CKTypedPropsComponent.h>
#import <ComponentKit/CKComponentSubclass.h>

@interface CKTypedPropsComponent ()

+ (instancetype)newWithPropsStruct:(const CKTypedComponentStruct &)props
                              view:(const CKComponentViewConfiguration &)view
                              size:(const CKComponentSize &)size;

+ (CKComponent *)renderWithProps:(const CKTypedComponentStruct &)props
                           state:(id)state
                            view:(const CKComponentViewConfiguration &)view
                            size:(const CKComponentSize &)size;

@property (nonatomic, assign, readonly) CKTypedComponentStruct props;
@property (nonatomic, strong, readonly) id state;

@end
