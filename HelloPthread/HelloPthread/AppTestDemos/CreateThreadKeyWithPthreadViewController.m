//
//  CreatePthreadSpecificDataViewController.m
//  HelloPthread
//
//  Created by wesley_chen on 2022/11/19.
//

#import "CreateThreadKeyWithPthreadViewController.h"
#include <pthread.h>

// Example code from https://www.ibm.com/docs/en/zos/2.1.0?topic=lf-pthread-key-create-create-thread-specific-data-key
@interface CreateThreadKeyWithPthreadViewController ()

@end

@implementation CreateThreadKeyWithPthreadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self test_pthread_key_create];
}

#pragma mark -

#define NUM_OF_THREAD 3
#define BUFFSIZE  1
pthread_key_t   key;

void *thread_entry_func(void *parm)
{
    int status;
    int threadNumber;
    void *value;
    void *getvalue;
    int buffer[BUFFSIZE];

    threadNumber = *(int *)parm;

    printf("Thread %d executing\n", threadNumber);

    if (!(value = malloc(sizeof(buffer)))) {
        printf("Thread %d could not allocate storage, errno = %d\n", threadNumber, errno);
    }
    
    int *bufferPtr = (int *)value;
    bufferPtr[0] = threadNumber;
    
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

    pthread_exit((void *)0);
}

void destructor_func(void *param)
{
    int *buffer = (int *)param;
    printf("Destructor function invoked on thread %d\n", buffer[0]);
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

    /* create 3 threads, pass each its number */
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
