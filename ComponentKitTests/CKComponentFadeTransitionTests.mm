//
//  CKComponentFadeTransitionTests.m
//  ComponentKit
//
//  Created by Marco Sero on 05/06/2015.
//
//

#import <XCTest/XCTest.h>

#import "CKComponentFadeTransition.h"

@interface CKComponentFadeTransitionTests : XCTestCase
@end

@implementation CKComponentFadeTransitionTests

- (void)testTransitionGeneration
{
  NSTimeInterval duration = 0.5;
  CATransition *fadeTransition = CKComponentGenerateTransition({.duration = duration});
  XCTAssertEqual(fadeTransition.duration, duration);
  XCTAssertEqual(fadeTransition.type, kCATransitionFade);
  XCTAssertEqual(fadeTransition.timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]);
}

@end
