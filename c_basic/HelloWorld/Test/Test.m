//
//  Test_time.m
//  Test_time
//
//  Created by wesley_chen on 2022/10/22.
//

#import <XCTest/XCTest.h>
#include <time.h>

@interface Test_time : XCTestCase

@end

@implementation Test_time

- (void)test_clock {
    clock_t begin = clock();

    /* here, do your time-consuming job */

    clock_t end = clock();
    double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
    
    NSLog(@"time cost: %f", time_spent);
}

@end
