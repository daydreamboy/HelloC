//
//  Test.m
//  Test
//
//  Created by wesley_chen on 2022/11/19.
//

#import <XCTest/XCTest.h>
#import <pthread/pthread.h>

@interface Test : XCTestCase

@end

@implementation Test

void * thread_entry_point(void *arg)
{
    NSLog(@"thread started with arg pointer: %p", arg);
    
    // Note: if you're sure that arg is some NSObject, it's safe to convert it to NSObejct
    // Note: use CFBridgingRelease to tell compiler should release arg
    NSObject *object = CFBridgingRelease(arg);
    NSLog(@"actual arg: %@", object);
    
    return NULL;
}

- (void)test_pthread_create {
    pthread_t thread;
    // Note: use alloc to create a NSString object which will be release, instead of use literal NSString which allocated memory controlled ObjC runtime
    NSString *param = [[NSString alloc] initWithFormat:@"%@", @"This is a param"];
    
    // Note: after pthread exit, in LLDB to print the pointer address, see it will not be the NSString
    NSLog(@"param: %p", param);
    // Note: use CFBridgingRetain to tell compiler param will be retained
    int status = pthread_create(&thread, NULL, thread_entry_point, (void *)CFBridgingRetain(param));
    if (status == 0) {
        NSLog(@"Create pthread successfully");
    }
}

- (void)test_pthread_join {
    
}

@end
