//
//  CreateThreadKeyWithNSThreadViewController.m
//  HelloPthread
//
//  Created by wesley_chen on 2022/11/20.
//

#import "CreateThreadKeyWithNSThreadViewController.h"
#include <pthread.h>

static pthread_key_t s_thread_key;

static void release_thread_call_stack(void *ptr) {
    char *newPtr = ptr;
    NSLog(@"release_thread_call_stack: %c", newPtr[0]);
    free(ptr);
}

@interface CreateThreadKeyWithNSThreadViewController ()
@property (nonatomic, strong) dispatch_queue_t userQueue;
@end

@implementation CreateThreadKeyWithNSThreadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadEntry:) object:nil];
    [thread start];
    NSLog(@"thread: %@", thread);
}

- (void)test_pthread_getspecific {
    int status = pthread_key_create(&s_thread_key, &release_thread_call_stack);
    if (status == 0) {
        NSLog(@"create key successfully");
    }
    
    char *ptr = malloc(1);
    ptr[0] = 'A';
    pthread_setspecific(s_thread_key, ptr);
}

- (void)threadEntry:(id)sender {
    NSLog(@"thread started");
    [self test_pthread_getspecific];
}

@end
