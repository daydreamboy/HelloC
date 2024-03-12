//
//  Test_keyword__Generic.m
//  Test_C
//
//  Created by wesley_chen on 2024/3/12.
//

#import <XCTest/XCTest.h>

@interface Test_keyword__Generic : XCTestCase

@end

@implementation Test_keyword__Generic


- (void)testExample {
    char c = 'A';
    double x = 8.0;
    const float y = 3.375;
    char s[] = "Hello,world";
    
    printf("x = %s\n", _Generic((x), char: "char", double: "double"));
    printf("c = %s\n", _Generic((c), char: "char", double: "double"));
}

@end
