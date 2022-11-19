//
//  CreatePthreadSpecificDataViewController.m
//  HelloPthread
//
//  Created by wesley_chen on 2022/11/19.
//

#import "CreatePthreadSpecificDataViewController.h"
#include <pthread.h>

// Example code from https://www.ibm.com/docs/en/zos/2.1.0?topic=lf-pthread-key-create-create-thread-specific-data-key
@interface CreatePthreadSpecificDataViewController ()

@end

@implementation CreatePthreadSpecificDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    //[self test_pthread];
}

#pragma mark -

#define NUM_OF_THREAD 3
#define BUFFSZ  48
pthread_key_t   key;

void *threadfunc(void *parm)
{
    int        status;
    void      *value;
    int        threadnum;
    int       *tnum;
    void      *getvalue;
    char       Buffer[BUFFSZ];

    tnum = parm;
    threadnum = *tnum;

    printf("Thread %d executing\n", threadnum);

    if (!(value = malloc(sizeof(Buffer))))
    printf("Thread %d could not allocate storage, errno = %d\n", threadnum, errno);
    
    status = pthread_setspecific(key, (void *) value);
    if ( status <  0) {
        printf("pthread_setspecific failed, thread %d, errno %d",
                                                  threadnum, errno);
        pthread_exit((void *)12);
    }
    printf("Thread %d setspecific value: %d\n", threadnum, value);

    getvalue = 0;
    getvalue = pthread_getspecific(key);
    if ( status <  0) {
        printf("pthread_getspecific failed, thread %d, errno %d",
                                                  threadnum, errno);
        pthread_exit((void *)13);
    }

    if (getvalue != value) {
        printf("getvalue not valid, getvalue=%d", (int)getvalue);
        pthread_exit((void *)68);
    }

    pthread_exit((void *)0);
}


void destr_fn(void *parm)
{
   printf("Destructor function invoked\n");
   free(parm);
}


- (void)test_pthread_create {
    int status;
    int i;
    int thread_params[NUM_OF_THREAD];
    pthread_t threads[NUM_OF_THREAD];
    int thread_stat[NUM_OF_THREAD];

    if ((status = pthread_key_create(&key, destr_fn)) < 0) {
        printf("pthread_key_create failed, errno=%d", errno);
        exit(1);
    }

    /* create 3 threads, pass each its number */
    for (i = 0; i < NUM_OF_THREAD; i++) {
        thread_params[i] = i + 1;
        status = pthread_create(&threads[i], NULL, threadfunc, (void *)&thread_params[i]);
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
