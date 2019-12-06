//
//  TERunTimeFuncAndMessage.m
//  TERunTimeLearnTests
//
//  Created by offcn_Terry on 2019/12/6.
//  Copyright © 2019 offcn_Terry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
@interface TERunTimeFuncAndMessage : XCTestCase

@end

@implementation TERunTimeFuncAndMessage

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    SEL sel1 = @selector(method1);
    NSLog(@"sel : %p", sel1);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}



@end
