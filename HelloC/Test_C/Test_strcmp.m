//
//  Test_strcmp.m
//  Test_C
//
//  Created by wesley_chen on 2024/3/12.
//

#import <XCTest/XCTest.h>

@interface Test_strcmp : XCTestCase

@end

@implementation Test_strcmp


- (void)test_strcmp {
    char *s;
    
    s = "123456";
    XCTAssertTrue(strcmp(s, "123456") == 0);
    
    s = "123456";
    XCTAssertFalse(strcmp(s, "12345678") == 0);
}


@end
