//
//  Test_snprintf.m
//  Test_C
//
//  Created by wesley_chen on 2022/12/17.
//

#import <XCTest/XCTest.h>

@interface Test_snprintf : XCTestCase

@end

@implementation Test_snprintf

// example code from C Manual
- (void)test_snprintf_1 {
    const char fmt[] = "sqrt(2) = %f";
    // Note: calculate the string "sqrt(2) = %f" filled value from sqrt(2)
    int sz = snprintf(NULL, 0, fmt, sqrt(2));
    
    // Note: make one more byte for terminating null
    char buf[sz + 1];
    int length = snprintf(buf, sizeof buf, fmt, sqrt(2));
    // Note: it's safe use %s, which buf is terminated by '\0'
    printf("%s\n", buf);
    printf("length: %d\n", length);
}

- (void)test_snprintf_2 {
    const char fmt[] = "sqrt(2) = %f";
    // Note: sizeof("<string>") will include the '\0'
    int sz = sizeof("sqrt"); // sz is 5
    
    // Note: make one more byte for terminating null
    char buf[sz + 1];
    int length = snprintf(buf, sizeof buf, fmt, sqrt(2));
    // Note: it's safe use %s, which buf is terminated by '\0'
    printf("%s\n", buf);
    printf("length: %d\n", length);
}

- (void)test_snprintf_3_abnormal_case {
    const char fmt[] = "sqrt(2) = %f";
    // Note: "sqrt" length is 4 exclude '\0'
    int sz = 4;
    
    // Note: only store 's', 'q', 'r', 't' on purpose
    char buf[sz /* + 1*/];
    int length = snprintf(buf, sizeof buf, fmt, sqrt(2));
    // Note: it's safe use %s, which buf is terminated by '\0'
    printf("%s\n", buf); // Output: sqr, the last byte used for '\0'
    printf("length: %d\n", length);
}

- (void)test_sprintf_1 {
    const char fmt[] = "sqrt(2) = %f";
    int sz = 25;
    char buf[sz];
    int length = sprintf(buf, fmt, sqrt(2));
    for (int i = 0; i < sz + 1; ++i) {
        printf("%c", buf[i]);
    }
    printf("\n");
    printf("length: %d\n", length);
}

- (void)test_sprintf_2_abnormal_case {
    const char fmt[] = "sqrt(2) = %f";
    int sz = 4;
    char buf[sz];
    
    // Warning: buf size is less then the result of formatted string
    int length = sprintf(buf, fmt, sqrt(2));
    for (int i = 0; i < sz + 1; ++i) {
        printf("%c", buf[i]);
    }
    printf("\n");
    printf("length: %d\n", length);
}

@end
