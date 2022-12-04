# HelloC
[TOC]

## 1、常见任务

### (1) 检测执行时间

```c
#include <time.h>

clock_t begin = clock();

/* here, do your time-consuming job */

clock_t end = clock();
double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
```

说明

> time(NULL)函数，返回的是Unix时间戳，但是整型，而且单位是秒，精度没有clock函数高



## 2、char *和char[]

TODO

```
- (void)test {    
    char cString1[] = { 'a', '\0' };
    char *cString2 =  { 'a', '\0' };
    printf("%s\n", cString1);
    printf("%s\n", cString2); // crash
}
```



## 3、动态内存分配

C提供下面几种函数，用于动态分配内存[^2]

| 函数        | 签名                                      | 作用                                                         |
| ----------- | ----------------------------------------- | ------------------------------------------------------------ |
| **calloc**  | void * calloc(size_t count, size_t size); | 分配连续多个内存块，个数是count，每个内存块的大小是size bytes |
| **free**    | void free(void *ptr);                     | 释放ptr引用的内存块。如果ptr是NULL，则不做任何操作           |
| **malloc**  | void * malloc(size_t size);               | 分配单个内存块，大小是size bytes                             |
| **realloc** | void * realloc(void *ptr, size_t size);   | 重新分配内存，该内存可以是malloc或者calloc创建的内存块       |
|             |                                           |                                                              |
|             |                                           |                                                              |
|             |                                           |                                                              |

说明

> 1. 在Terminal中使用man malloc可以查询上面函数的文档
> 2. HelloMalloc工程中，可以查看这几个函数的用法



### (1) malloc

malloc用于分配一块内存。

举个例子，如下

```c
- (void)test_malloc_for_char {
    int size = 10;
    char *ptr = (char *)malloc(size * sizeof(char));
    
    for (int i = 0; i < size; ++i) {
        ptr[i] = 'A' + i;
    }
    
    for (int i = 0; i < size; ++i) {
        printf("%c ", ptr[i]);
    }
    printf("\n");
    
    free(ptr);
}
```

使用malloc需要计算整个内存块的大小（按照byte单位）。例如上面需要10个char的内存，则是`size * sizeof(char)`。如果觉得不够直观可以使用`calloc`函数。

说明

> malloc函数分配的内存，它们的值都为未初始化的



除了分配基本类型的内存块，也可以分配struct类型的内存块。举个例子，如下

```objective-c
typedef struct {
    id self;
    Class cls;
    SEL cmd;
    uint64_t index;
} thread_call_record;

- (void)test_malloc_for_struct {
    int size = 3;
    thread_call_record *ptr = (thread_call_record *)malloc(size * sizeof(thread_call_record));
    
    for (int i = 0; i < size; ++i) {
        thread_call_record *record = &ptr[i];
        record->self = self;
        record->cls = [self class];
        record->cmd = _cmd;
        record->index = i;
    }
    
    for (int i = 0; i < size; ++i) {
        thread_call_record record = ptr[i];
        printf("index:%llu, self: %s, cls: %s, cmd: %s\n", record.index, [record.self description].UTF8String, NSStringFromClass(record.cls).UTF8String, sel_getName(record.cmd));
    }
    
    free(ptr);
}
```



### (2) calloc

calloc函数作用和malloc函数一样，只是需要2个参数：内存块个数和每个内存的大小。

```c
void * calloc(size_t count, size_t size);
```

说明

> 1. calloc函数分配多个内存块，它们也是连续的。
>
> 2. calloc函数分配的内存，都会初始化为0。举个例子，如下
>
>    ```objective-c
>    - (void)test_calloc_initialized_with_zero {
>        int count = 10;
>        int *ptr = (int *)calloc(count, sizeof(int));
>                 
>        for (int i = 0; i < count; ++i) {
>            printf("%d ", ptr[i]);
>        }
>        printf("\n");
>                 
>        free(ptr);
>    }
>    ```

calloc函数比较适合分配struct类型的内存块，因为代码容易理解。举个例子，如下

```objective-c
- (void)test_calloc_for_struct {
    int count = 3;
    thread_call_record *ptr = (thread_call_record *)calloc(count, sizeof(thread_call_record));
    
    for (int i = 0; i < count; ++i) {
        thread_call_record *record = &ptr[i];
        record->self = self;
        record->cls = [self class];
        record->cmd = _cmd;
        record->index = i;
    }
    
    for (int i = 0; i < count; ++i) {
        thread_call_record record = ptr[i];
        printf("index:%llu, self: %s, cls: %s, cmd: %s\n", record.index, [record.self description].UTF8String, NSStringFromClass(record.cls).UTF8String, sel_getName(record.cmd));
    }
    
    free(ptr);
}
```



### (3) realloc

对于malloc和calloc函数分配的内存，如果不够用，realloc函数可以它们的扩大内存块。

```c
void * realloc(void *ptr, size_t size);
```

* 第一个参数是已经分配的内存地址。如果ptr是NULL，则效果和malloc函数是一样的。
* 第二个参数是需要重新分配的大小

说明

> 1. realloc函数会保证原始数据也会拷贝新的内存上。举个例子，如下
>
>    ```objective-c
>    - (void)test_realloc_for_char {
>        int size = 10;
>        int extraSize = 1024;
>        char *ptr = (char *)malloc(size * sizeof(char));
>        
>        int i = 0;
>        for (; i < size; ++i) {
>            ptr[i] = 'A' + i;
>        }
>        printf("old ptr: %p\n", ptr);
>        
>        // Note: realloc memory with the original pointer
>        ptr = realloc(ptr, size + extraSize);
>        
>        int additionalSize = MIN(extraSize, 5);
>        
>        printf("new ptr: %p\n", ptr);
>        for (; i < size + additionalSize; ++i) {
>            ptr[i] = 'A' + i;
>        }
>        
>        for (int i = 0; i < size + additionalSize; ++i) {
>            printf("%c ", ptr[i]);
>        }
>        printf("\n");
>        
>        free(ptr);
>    }
>    ```
>
>    realloc函数返回的指针有可能和原始指针一样，也可能不一样，总是要采用realloc函数返回的指针。
>
> 2. realloc函数不保证重新分配的内存都初始化为0



## 4、pthread

POSIX thread (后面简称pthread)是一组支持多线程的函数集合。

pthread分为下面几组

* Thread Routines

* Attribute Object Routines
* Mutex Routines
* Condition Variable Routines
* Read/Write Lock Routines
* Per-Thread Context Routines
* Cleanup Routines



### (1) Thread Routines

Thread Routines主要包含一些线程的基本函数，如下

| 函数                   | 函数签名                                                     | 作用                                       |
| ---------------------- | ------------------------------------------------------------ | ------------------------------------------ |
| pthread_create         | int pthread_create(pthread_t *thread, const pthread_attr_t *attr, void *(*start_routine)(void *), void *arg) | 创建一个新线程的执行                       |
| pthread_cancel         | int pthread_cancel(pthread_t thread)                         | 取消线程的执行                             |
| pthread_detach         | int pthread_detach(pthread_t thread)                         | 标记线程删除                               |
| pthread_equal          | int pthread_equal(pthread_t t1, pthread_t t2)                | 比较两个线程的id                           |
| pthread_exit           | void pthread_exit(void *value_ptr)                           | 结束当前calling  thread                    |
| pthread_join           | int pthread_join(pthread_t thread, void **value_ptr)         | 挂起当前calling thread，一直到特定线程结束 |
| pthread_kill           | int pthread_kill(pthread_t thread, int sig)                  | 发送signal给特定线程                       |
| pthread_once           | `int pthread_once(pthread_once_t *once_control, void (*init_routine)(void))` | 调用一个用于初始化的回调函数               |
| pthread_self           | pthread_t pthread_self(void)                                 | 返回当前calling thread对象                 |
| pthread_setcancelstate |                                                              |                                            |
| pthread_setcanceltype  |                                                              |                                            |
| pthread_testcancel     |                                                              |                                            |

说明

> 1. 调用pthread_create函数，就立即开始一个新线程的执行
> 2. calling thread是调用函数的所在线程，比如当执行pthread_exit函数，则该函数会终止calling thread，这个calling thread就是执行pthread_exit函数的线程
> 3. pthread_kill函数，虽然命名有kill，但是它的作用是kill某个线程，而发送signal给某个线程



### (2) Attribute Object Routines

Attribute Object Routines包含操作线程属性相关的函数，如下

| 函数                         | 函数签名                                       | 作用                         |
| ---------------------------- | ---------------------------------------------- | ---------------------------- |
| pthread_attr_destroy         | int pthread_attr_destroy(pthread_attr_t *attr) | 销毁一个线程属性对象         |
| pthread_attr_getinheritsched |                                                |                              |
| pthread_attr_getschedparam   |                                                |                              |
| pthread_attr_getschedpolicy  |                                                |                              |
| pthread_attr_getscope        |                                                |                              |
| pthread_attr_getstacksize    |                                                |                              |
| pthread_attr_getstackaddr    |                                                |                              |
| pthread_attr_getdetachstate  |                                                |                              |
| pthread_attr_init            | int pthread_attr_init(pthread_attr_t *attr)    | 使用默认值初始化一个线程属性 |
| pthread_attr_setinheritsched |                                                |                              |
| pthread_attr_setschedparam   |                                                |                              |
| pthread_attr_setschedpolicy  |                                                |                              |
| pthread_attr_setscope        |                                                |                              |
| pthread_attr_setstacksize    |                                                |                              |
| pthread_attr_setstackaddr    |                                                |                              |
| pthread_attr_setdetachstate  |                                                |                              |



### (3) Mutex Routines

Mutex Routines主要包含线程可能会使用到的互斥锁mutex相关函数，如下

| 函数 | 函数签名 | 作用 |
| ---- | -------- | ---- |
|      |          |      |



### (4) Condition Variable Routines

Condition Variable Routines主要包含线条件变量相关函数，如下

| 函数 | 函数签名 | 作用 |
| ---- | -------- | ---- |
|      |          |      |



### (5) Read/Write Lock Routines

Read/Write Lock Routines主要包含读写锁相关的函数，如下

| 函数                          | 函数签名                                                     | 作用                                     |
| ----------------------------- | ------------------------------------------------------------ | ---------------------------------------- |
| pthread_rwlock_destroy        | int pthread_rwlock_destroy(pthread_rwlock_t *lock)           | 销毁一个读写锁对象                       |
| pthread_rwlock_init           | int pthread_rwlock_init(pthread_rwlock_t *lock, const pthread_rwlockattr_t *attr) | 初始化一个读写锁对象                     |
| pthread_rwlock_rdlock         | int pthread_rwlock_rdlock(pthread_rwlock_t *lock)            | 为读操作，加锁                           |
| pthread_rwlock_tryrdlock      | int pthread_rwlock_tryrdlock(pthread_rwlock_t *lock)         | 为读操作，尝试加锁。如果锁不可用，则无效 |
| pthread_rwlock_trywrlock      | int pthread_rwlock_trywrlock(pthread_rwlock_t *lock)         | 为写操作，尝试加锁。如果锁不可用，则无效 |
| pthread_rwlock_unlock         | int pthread_rwlock_unlock(pthread_rwlock_t *lock)            | 读写锁解锁                               |
| pthread_rwlock_wrlock         | int pthread_rwlock_wrlock(pthread_rwlock_t *lock)            | 为写操作，加锁                           |
| pthread_rwlockattr_destroy    | int pthread_rwlockattr_destroy(pthread_rwlockattr_t *attr)   | 销毁一个读写锁的属性                     |
| pthread_rwlockattr_getpshared |                                                              |                                          |
| pthread_rwlockattr_init       | int pthread_rwlockattr_init(pthread_rwlockattr_t *attr)      | 初始化一个读写锁的属性                   |
| pthread_rwlockattr_setpshared |                                                              |                                          |



### (6) Per-Thread Context Routines

Per-Thread Context Routines主要包含线程各自上下文的操作函数，如下

| 函数                | 函数签名                                                     | 作用                               |
| ------------------- | ------------------------------------------------------------ | ---------------------------------- |
| pthread_key_create  | `int pthread_key_create(pthread_key_t *key, void (*routine)(void *))` | 创建线程特定的数据key              |
| pthread_key_delete  | int pthread_key_delete(pthread_key_t key)                    | 删除线程特定的数据key              |
| pthread_getspecific | void * pthread_getspecific(pthread_key_t key)                | 根据特定的key，获取线程特定的value |
| pthread_setspecific | int pthread_setspecific(pthread_key_t key, const void *value_ptr) | 给定特定的key，设置线程特定的value |



#### a. pthread_create

pthread_create函数的签名，如下

```c
int pthread_create(pthread_t *thread, const pthread_attr_t *attr, void *(*start_routine)(void *), void *arg);
```

* thread参数。pthread_t的指针
* pthread_attr_t参数。pthread_t的属性。传入NULL，则使用默认属性
* start_routine参数。线程的入口函数
* arg参数。该参数是传入线程的入口函数的参数。

返回值是0，表示该函数创建线程成功。

举个例子，如下

```objective-c
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
```





#### b. pthread_getspecific

```c
void *pthread_getspecific(pthread_key_t key);
```



#### c. pthread_key_create

pthread_key_create函数的签名，如下

```c
int pthread_key_create(pthread_key_t *key, void (*destructor)(void *));
```

* key参数，是pthread_key_t类型的指针，用于出参。当返回值是0时，key是一个有效的数据。
  * 这个key对于所有线程是共享的，但是不同线程用这个key可以设置自己的线程数据
* destructor参数，是可选的，指定一个回调函数。当key用于设置某个线程的特定数据时，在该线程退出时，会调用destructor对应的回调函数。
  * 回调函数有一个参数，它对应key设置value的value参数。

说明

> 1. 如果只创建key，但是并没有使用key去设置线程特定的value，则destructor回调函数不会被调用。
> 2. 如果所有线程，例如N个线程，都共用一个key，那么destructor回调函数，会被回调N次。示例代码，见CreateThreadKeyWithPthreadViewController
> 3. 如果所有线程，例如N个线程，都共用M个key，而且这M个key，都设置同一个destructor回调函数，那么destructor回调函数会被回调M*N次。示例代码，见CreateMultipleThreadKeyWithPthreadViewController



pthread_key_create函数，主要配合pthread_setspecific和pthread_getspecific函数使用。举个例子[^3]，如下

```objective-c
#define NUM_OF_THREAD 3
#define BUFFSIZE  1
static pthread_key_t   key;

static void *thread_entry_func(void *parm)
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

static void destructor_func(void *param)
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
```

上面创建3个线程，但是它们都共用key，然后用这个key设置自己的线程数据。这个数据通过malloc分配并初始化为线程的序号，然后在destructor回调函数中，释放这个内存。

说明

> 1. 上面示例中，通过pthread_getspecific再次获取value，并对value做了检查，可以没有这个步骤
> 2. 上面的全局变量key和函数thread_entry_func、destructor_func，都采用static，是为了避免外部符号冲突
> 3. 示例代码，见CreateThreadKeyWithPthreadViewController



##### pthread_key_create用于GCD线程和NSThread

GCD线程和NSThread的底层也是创建pthread线程，因此pthread_key_create函数创建的key，也可以用于它们。

举个GCD线程的例子，如下

```objective-c
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _userQueue = dispatch_queue_create("com.wc.thread1", DISPATCH_QUEUE_SERIAL);
    dispatch_async(_userQueue, ^{
        [self test_pthread_getspecific];
    });
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
```

> 示例代码，见CreateThreadKeyWithGCDThreadViewController和CreateThreadKeyWithNSThreadViewController





### (7) Cleanup Routines

Cleanup Routines主要包含清理相关函数，如下

| 函数 | 函数签名 | 作用 |
| ---- | -------- | ---- |
|      |          |      |



### (8) 其他np函数

在macOS和iOS上还有一些以pthread开头，但是以np为后缀的pthread函数，这些函数不是POSIX定义的函数，代表不是跨平台的C API。如下

| 函数                   | 函数签名                                                     | 作用                                        |
| ---------------------- | ------------------------------------------------------------ | ------------------------------------------- |
| pthread_mach_thread_np |                                                              | 获取线程id，在iOS8之后不再是这个用途        |
| pthread_main_np        | int pthread_main_np(void)                                    | 判断当前线程是否主线程，返回非0表示是主线程 |
| pthread_setname_np     | int pthread_setname_np(const char*)                          | 设置线程的名字[^5]                          |
| pthread_threadid_np    | int pthread_threadid_np(pthread_t _Nullable,__uint64_t* _Nullable) | 获取线程id                                  |
| pthread_getname_np     | int pthread_getname_np(pthread_t,char*,size_t)               | 获取线程的名字                              |

说明

> np，是Non-Portable的缩写[^4]



#### a. pthread_setname_np/pthread_getname_np

pthread_setname_np和pthread_getname_np，用于设置和获取线程的名字。它们的函数签名，如下

```c
int pthread_setname_np(const char*)
int pthread_getname_np(pthread_t,char*,size_t)
```

举个例子，如下

```objective-c
static void * thread_entry_point2(void *parm)
{
    int rc;
    rc = pthread_setname_np("THREADFOO");
    if (rc != 0)
        NSLog(@"pthread_setname_np failed");
    
    sleep(5);          // allow main program to set the thread name
    return NULL;
}

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
```



#### b. pthread_threadid_np

pthread_threadid_np用于获取线程id[^6]，举个例子，如下

```objective-c
- (void)test_pthread_threadid_np {
    __uint64_t threadId;
    if (pthread_threadid_np(0, &threadId)) {
        threadId = pthread_mach_thread_np(pthread_self());
    }
    NSLog(@"current threadId is: %llu\n", threadId);
}
```

说明

> 在早期的MacOS或者iOS上，可以使用pthread_mach_thread_np获取线程id，但是iOS 8之后要换成使用pthread_threadid_np[^6]





## 5、Linux man手册

macOS上有关pthread函数的文档，如果在man中没有查询到，可以在下面这个Linux man手册尝试查询

https://man7.org/linux/man-pages/index.html





## References

[^1]:https://stackoverflow.com/a/5249150

[^2]:https://www.javatpoint.com/dynamic-memory-allocation-in-c

[^3]:https://www.ibm.com/docs/en/zos/2.1.0?topic=lf-pthread-key-create-create-thread-specific-data-key

[^4]:https://stackoverflow.com/questions/2238564/pthread-functions-np-suffix
[^5]:https://man7.org/linux/man-pages/man3/pthread_setname_np.3.html
[^6]:https://stackoverflow.com/questions/8995650/what-does-the-prefix-in-nslog-mean

