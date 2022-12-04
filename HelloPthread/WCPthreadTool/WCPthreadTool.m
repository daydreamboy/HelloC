//
//  WCPthreadTool.m
//  HelloPthread
//
//  Created by wesley_chen on 2022/12/4.
//

#import "WCPthreadTool.h"
#import <pthread/pthread.h>

@implementation WCPthreadTool

@end

__uint64_t WCGetCurrentPthreadID(void)
{
    __uint64_t threadId;
    if (pthread_threadid_np(0, &threadId)) {
        threadId = pthread_mach_thread_np(pthread_self());
    }
    return threadId;
}
