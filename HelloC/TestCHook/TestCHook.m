//
//  TestCHook.m
//  TestCHook
//
//  Created by wesley_chen on 2023/5/5.
//

#import <XCTest/XCTest.h>

@interface TestCHook : XCTestCase
@end

@implementation TestCHook

- (void)test_hook_NSLog_by_overwrite {
    NSLog(@"Test %@", @"NSLog");
}

@end
