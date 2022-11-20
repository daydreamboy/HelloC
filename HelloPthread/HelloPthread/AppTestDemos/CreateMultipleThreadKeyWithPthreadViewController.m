//
//  CreateMultipleThreadKeyWithPthreadViewController.m
//  HelloPthread
//
//  Created by wesley_chen on 2022/11/20.
//

#import "CreateMultipleThreadKeyWithPthreadViewController.h"
#include <pthread.h>

@interface CreateMultipleThreadKeyWithPthreadViewController ()

@end

@implementation CreateMultipleThreadKeyWithPthreadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self test_pthread_key_create];
}


#pragma mark -

#define NUM_OF_THREAD 1
#define BUFFSIZE  2
static pthread_key_t   key;
static pthread_key_t   key2;

static void *thread_entry_func(void *parm)
{
    int status;
    int threadNumber;
    void *value;
    void *value2;
    void *getvalue;
    int buffer[BUFFSIZE];

    threadNumber = *(int *)parm;

    printf("Thread %d executing\n", threadNumber);

    if (!(value = malloc(sizeof(buffer)))) {
        printf("Thread %d could not allocate storage, errno = %d\n", threadNumber, errno);
    }
    
    int *bufferPtr = (int *)value;
    bufferPtr[0] = threadNumber;
    bufferPtr[1] = 1; // indicates the key1
    
    status = pthread_setspecific(key, (void *)value);
    if (status < 0) {
        printf("pthread_setspecific failed, thread %d, errno %d", threadNumber, errno);
        pthread_exit((void *)12);
    }
    printf("Thread %d setspecific value: %p\n", threadNumber, value);

    getvalue = 0;
    getvalue = pthread_getspecific(key);
    if (status < 0) {
        printf("pthread_getspecific failed, thread %d, errno %d", threadNumber, errno);
        pthread_exit((void *)13);
    }

    if (getvalue != value) {
        printf("getvalue not valid, getvalue=%p", getvalue);
        pthread_exit((void *)68);
    }
    
    // Note: use key2 to set more thread-specific data
    if (!(value2 = malloc(sizeof(buffer)))) {
        printf("Thread %d could not allocate storage2, errno = %d\n", threadNumber, errno);
    }
    
    int *bufferPtr2 = (int *)value2;
    bufferPtr2[0] = threadNumber;
    bufferPtr2[1] = 2;  // indicates the key2
    
    status = pthread_setspecific(key2, (void *)value2);
    if (status < 0) {
        printf("pthread_setspecific failed2, thread %d, errno %d", threadNumber, errno);
        pthread_exit((void *)12);
    }
    printf("Thread %d setspecific value2: %p\n", threadNumber, value2);

    pthread_exit((void *)0);
}

static void destructor_func(void *param)
{
    int *buffer = (int *)param;
    printf("Destructor function invoked on thread %d for key%d\n", buffer[0], buffer[1]);
    free(buffer);
}

- (void)test_pthread_key_create {
    int status;
    int i;
    int thread_params[NUM_OF_THREAD];
    pthread_t threads[NUM_OF_THREAD];
    int thread_stat[NUM_OF_THREAD];

    if ((status = pthread_key_create(&key, destructor_func)) < 0) {
        printf("pthread_key_create failed, errno=%d", errno);
        exit(1);
    }
    
    if ((status = pthread_key_create(&key2, destructor_func)) < 0) {
        printf("pthread_key_create failed2, errno=%d", errno);
        exit(1);
    }

    // Note: create only 1 threads with 2 keys
    for (i = 0; i < NUM_OF_THREAD; i++) {
        thread_params[i] = i + 1;
        status = pthread_create(&threads[i], NULL, thread_entry_func, (void *)&thread_params[i]);
        if (status != 0) {
            printf("pthread_create failed, errno=%d", errno);
            exit(2);
        }
    }

    for (i = 0; i < NUM_OF_THREAD; i++) {
        status = pthread_join(threads[i], (void *)&thread_stat[i]);
        if (status != 0) {
            printf("pthread_join failed, thread %d, errno=%d\n", i + 1, errno);
        }

        if (thread_stat[i] != 0) {
            printf("bad thread status, thread %d, status=%d\n", i + 1, thread_stat[i]);
        }
    }
}

@end
