//
//  Test_printf.m
//  Test_C
//
//  Created by wesley_chen on 2022/10/24.
//

#import <XCTest/XCTest.h>

@interface Test_printf : XCTestCase

@end

@implementation Test_printf

- (void)test_printf_format {
    // Note: one byte size
    // @see https://stackoverflow.com/questions/23697090/how-to-print-2-or-4-bytes-in-hex-format-in-c
    char ch1 = 1;
    printf("%02X\n", ch1); // print 02
    printf("%hhX\n ", ch1); // print 1
}

@end
