//
//  Test_variadic_function.m
//  Test_C
//
//  Created by wesley_chen on 2024/8/16.
//

#import <XCTest/XCTest.h>
#import "variadic_parameters_function.h"

@interface Test_variadic_function : XCTestCase

@end

@implementation Test_variadic_function

- (void)test_variadic_func {
    // Case1
    int r1 = variadic_func1(5, 1, 2, 3, 4, 5);
    XCTAssertTrue(r1 == 15);
    
    // Case2
    char *r2 = variadic_func2("%s, %s", "Hello", "world!");
    XCTAssertTrue(strcmp(r2, "Hello, world!") == 0);
    NSLog(@"%s", r2);
    free(r2);
    
    // Case 3
    printValues("dcff", 4, 3, 'a', 1.999, 42.5);
    
    // Case 4
    NSString *r4 = variadic_func3(@"%@ = %@", @"Hello", @"world!");
    XCTAssertEqualObjects(r4, @"Hello = world!");
}

static NSString * variadic_func3 (NSString *format, ...) {
    printf("variadic_func3 called\n");
    
    va_list ap;
    va_start(ap, format);
    NSString *logMessage = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);
    
    return logMessage;
}

@end
