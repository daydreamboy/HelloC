//
//  Test_hook_static_c_function_pseudo.m
//  Test_C
//
//  Created by wesley_chen on 2023/3/30.
//

#import <XCTest/XCTest.h>

#include <stdio.h>

// Note: the original c static function
static int add(int a, int b) {
    return a + b;
}

// Note: the replacement c static function to hook
static int hooked_add(int a, int b) {
    printf("hooked_add() called\n");
    
    // Note: should use address of original function,
    // here use function name for demonstration
    return add(a, b) + 10;
}

@interface Test_hook_static_c_function_pseudo : XCTestCase
@end

@implementation Test_hook_static_c_function_pseudo

- (void)test {
    int (*fp)(int, int);
       
    fp = add;
    printf("add(2,3) = %d\n", fp(2,3));
    
    fp = hooked_add;
    printf("hooked_add(2,3) = %d\n", fp(2,3));
}

@end
