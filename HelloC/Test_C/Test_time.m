//
//  Test_time.m
//  Test_time
//
//  Created by wesley_chen on 2022/10/22.
//

#import <XCTest/XCTest.h>
#include <time.h>
#include <sys/time.h>

@interface Test_time : XCTestCase

@end

@implementation Test_time

- (void)test_clock {
    clock_t begin = clock();

    /* here, do your time-consuming job */
    
    static int sum = 0;
    for (NSInteger i = 0; i < 100000; ++i) {
        sum += i;
    }

    clock_t end = clock();
    double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
    
    NSLog(@"time cost: %f", time_spent);
}

// example code from https://www.epochconverter.com/programming/c
- (void)test_strftime {
    time_t     now;
    struct tm  ts;
    char       buf[80];

    // Get current time
    time(&now);

    // Format time, "ddd yyyy-mm-dd hh:mm:ss zzz"
    ts = *localtime(&now);
    strftime(buf, sizeof(buf), "%a %Y-%m-%d %H:%M:%S %Z", &ts);
    printf("%s\n", buf);
    
    strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S %z", &ts);
    printf("%s\n", buf);
    
    NSLog(@"test");
}

// code from https://stackoverflow.com/questions/1551597/using-strftime-in-c-how-can-i-format-time-exactly-like-a-unix-timestamp
- (void)test_strftime_with_microseconds {
    char fmt[64], buf[64];
    struct timeval tv;
    struct tm *tm;

    gettimeofday(&tv, NULL);
    if ((tm = localtime(&tv.tv_sec)) != NULL) {
        strftime(fmt, sizeof fmt, "%Y-%m-%d %H:%M:%S.%%06u%z", tm);
        snprintf(buf, sizeof buf, fmt, tv.tv_usec);
        printf("%s\n", buf);
        NSLog(@"test");
    }
}

@end
