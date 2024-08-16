//
//  Test_keyword_sizeof.m
//  Test_C
//
//  Created by wesley_chen on 2024/4/16.
//

#import <XCTest/XCTest.h>

@interface Test_keyword_sizeof : XCTestCase

@end

@implementation Test_keyword_sizeof

- (void)test {
    NSLog(@"xxx = %lu", sizeof(BOOL));
}

@end
