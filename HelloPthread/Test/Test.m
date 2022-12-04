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

#pragma mark - pthread_setname_np/pthread_getname_np

static void * thread_entry_point2(void *parm)
{
    int rc;
    rc = pthread_setname_np("THREADFOO");
    if (rc != 0)
        NSLog(@"pthread_setname_np failed");
    
    sleep(5);          // allow main program to set the thread name
    return NULL;
}

// Example from https://man7.org/linux/man-pages/man3/pthread_setname_np.3.html
- (void)test_pthread_setname_np {
#define NAMELEN 16
    
    pthread_t thread;
    int rc;
    char thread_name[NAMELEN];

    rc = pthread_create(&thread, NULL, thread_entry_point2, NULL);
    if (rc != 0)
       NSLog(@"pthread_create failed");

    rc = pthread_getname_np(thread, thread_name, NAMELEN);
    if (rc != 0)
       NSLog(@"pthread_getname_np failed");

    NSLog(@"Created a thread. Default name is: %s\n", thread_name);

    sleep(2);

    rc = pthread_getname_np(thread, thread_name, NAMELEN);
    if (rc != 0)
       NSLog(@"pthread_getname_np failed");
    
    NSLog(@"The thread name after setting it is %s.\n", thread_name);

    rc = pthread_join(thread, NULL);
    if (rc != 0)
       NSLog(@"pthread_join failed");

    printf("Done\n");
}

// Example from @see https://stackoverflow.com/questions/8995650/what-does-the-prefix-in-nslog-mean
- (void)test_pthread_threadid_np {
    __uint64_t threadId;
    if (pthread_threadid_np(0, &threadId)) {
        threadId = pthread_mach_thread_np(pthread_self());
    }
    NSLog(@"current threadId is: %llu\n", threadId);
}

- (void)test_pthread_mach_thread_np {
    // Warning: pthread_mach_thread_np no longer can get the correct thread id,
    __uint64_t threadId = pthread_mach_thread_np(pthread_self());
    // Note: the threadId is not same as the NSLog prefix
    NSLog(@"current threadId is: %llu\n", threadId);
}

@end
