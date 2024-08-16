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



### (2) 获取静态函数地址

这里介绍如何获取静态C函数地址在内存的地址。由于静态函数并不是外部符号，是不能直接通过函数名调用的，因此能拿到函数地址，则能直接调用静态函数，这个是hook c静态函数的其中一步。

下面示例如何hook c静态函数的，用于演示步骤，实际比这个要复杂得多。

```objective-c
// Note: the original c static function
static int add(int a, int b) {
    return a + b;
}

// Note: the replacement c static function to hook
static int hooked_add(int a, int b) {
    printf("hooked_add() called\n");
    
    // Note: should use address of original function,
    // here use function name for demonstration
    return add(a, b) + 10;
}

@interface Test_hook_static_c_function_pseudo : XCTestCase
@end

@implementation Test_hook_static_c_function_pseudo

- (void)test {
    int (*fp)(int, int);
       
    fp = add;
    printf("add(2,3) = %d\n", fp(2,3));
    
    fp = hooked_add;
    printf("hooked_add(2,3) = %d\n", fp(2,3));
}

@end
```

> 示例代码，见Test_hook_static_c_function_pseudo.m

步骤如下

* 查看源码确定要hook函数的签名，例如add函数。
* 提供hook函数，并在hook函数中获取原始函数的函数地址，用于调用原始函数
* 在内存中，将调用原始函数的目标地址，写成hook函数的地址。例如上面将上面fp的内容换成hooked_add，那么再次调用fp函数，则会跳转到hook函数里面

这里主要介绍如何获取静态C函数地址在内存的地址。

示例代码，如下

```c
static int add(int a, int b) {
    return a + b;
}

__attribute__((constructor))
static int sub(int a, int b) {
    return a - b;
}

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    
    int r = add(1, 2);
    NSLog(@"%d", r);

    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}

```

说明

> 静态C函数，如果没有被调用的话，可能会被编译器优化掉。有两种方式防止被优化掉：
>
> * 调用静态C函数
> * 将静态C函数声明为构造函数

使用nm命令查看`_add`和`_sub`在MachO的地址，如下

```shell
$ nm -m HelloC | grep -e "_add" -e "_sub"
00000001000021a0 (__TEXT,__text) non-external _add
00000001000020c0 (__TEXT,__text) non-external _sub
```

使用otool命令反汇编`__text`段，搜索`_add`和`_sub`的函数地址，如下

```shell
$ otool -tV HelloC | grep -e "_add" -e "_sub" -A1
_sub:
00000001000020c0	pushq	%rbp
--
000000010000214c	callq	_add
0000000100002151	movl	%eax, -0x1c(%rbp)
--
_add:
00000001000021a0	pushq	%rbp
```

可以看出和nm的结果是一样的。

由于函数在内存中的地址，是镜像image的加载地址，加上MachO中的偏移量，那么在lldb中可以算出add函数和sub函数的内存地址。

计算公式是：函数地址 = 镜像image的加载地址  + MachO中的偏移量 

​                                       = 镜像image的加载地址  + 函数在MachO中的地址 - 4GB

说明

> 1. 这里提到的MachO中的偏移量，是指通过nm或otool命令查看函数在MachO的偏移地址
>
> 2. 这里的4GB (0x0000000100000000)是MachO文件的起始地址预留的地址空间，64位的MachO文件总是从4GB开始算地址。

示例如下

```shell
(lldb) image list HelloC
[  0] A2992373-13CE-3BE1-AEB3-6EDC4A720FF9 0x0000000108cc2000 /Users/wesley_chen/Library/Developer/Xcode/DerivedData/HelloC-gclmwhthurqacjadtcsryagjoeib/Build/Products/Debug-iphonesimulator/HelloC.app/HelloC 
(lldb) p/x  (long)4 * 1024 * 1024 * 1024
(long) $11 = 0x0000000100000000
(lldb) p/x 0x0000000108cc2000 + 0x00000001000021a0 - 0x0000000100000000
(long) $12 = 0x0000000108cc41a0
(lldb) image lookup -a 0x0000000108cc41a0
      Address: HelloC[0x00000001000021a0] (HelloC.__TEXT.__text + 784)
      Summary: HelloC`add at main.m:11
(lldb) p add
(int (*)(int, int)) $13 = 0x0000000108cc41a0 (HelloC`add at main.m:11)
(lldb) 
```

说明

> 1. 由于lldb不支持十六进制和十进制的混合计算，这里手动先算下4GB的十六进制是0x0000000100000000，而且要转成long，lldb才能计算正确。

这里p/x 0x0000000108cc2000 + 0x00000001000021a0 - 0x0000000100000000是按照上面公式得出add函数在内存的地址。

确认函数地址是否计算正确，有下面几种方式

* 可以使用`image lookup -a`

* 直接打印函数名，例如`p add`

* 代码中打印函数地址，如下

  ```c
  NSLog(@"%p", add);
  ```


说明

> 这里通过nm或者otool找到函数在MachO的偏移量，实际上可以通过实现代码分析MachO文件，找这个偏移量，那么通过代码也可以实现在lldb中的操作，因此即使是C静态函数，没有外部符号，也可以拿到它的函数地址。



#### a. 在Release编译模式下查看静态C函数地址

在Release编译模式下，实际上在lldb中是不能看到add函数，但是可以看到sub函数，如下

```shell
(lldb) p add
error: expression failed to parse:
error: <user expression 0>:1:1: 'add' has unknown type; cast it to its declared type to use it
add
^~~
(lldb) p sub
(int (*)(int, int)) $0 = 0x0000000104cf3320 (HelloC`sub at main.m:16)
```

区分在于两个函数是静态函数和静态构造函数，构造函数需要让静态系统调用，因此符号是对外可见的。

注意

> 在Xcode15.4版本的lldb中，已经可以查看静态函数add的地址，可能调整调试的策略。



由于采用Release模式编译，可执行文件可能重新编译，需要重新查看下`_add`和`_sub`符号的地址，如下

```shell
$ nm -m HelloC | grep -e "_add" -e "_sub"
00000001000023ab (__TEXT,__text) non-external _add
0000000100002315 (__TEXT,__text) non-external _sub
```

在lldb中重新计算，如下

```shell
(lldb) image list HelloC
[  0] 9E660F80-3347-38CD-AFB2-6501E4FD1238 0x0000000102e4c000 /Users/wesley_chen/Library/Developer/Xcode/DerivedData/HelloC-gclmwhthurqacjadtcsryagjoeib/Build/Products/Release-iphonesimulator/HelloC.app/HelloC 
      /Users/wesley_chen/Library/Developer/Xcode/DerivedData/HelloC-gclmwhthurqacjadtcsryagjoeib/Build/Products/Release-iphonesimulator/HelloC.app.dSYM/Contents/Resources/DWARF/HelloC
(lldb) p/x 0x0000000102e4c000 + 0x23ab
(long) $0 = 0x0000000102e4e3ab
```

这个地址和NSLog输出是一样的，说明是正确的。

使用`image lookup -a`查看也是正确的，如下

```shell
(lldb) image lookup -a 0x0000000102e4e3ab
      Address: HelloC[0x00000001000023ab] (HelloC.__TEXT.__text + 353)
      Summary: HelloC`add at main.m:11
```



#### b. lldb中调用静态C函数地址

将函数内存地址强制转成函数指针调用，如下

```shell
(lldb) e ((int (*)(int, int))0x0000000102e4e3ab)(1, 2)
(int) $1 = 3
(lldb) e ((int (*)(int, int))0x0000000102e4e3ab)(2, 3)
(int) $2 = 5
```

实际上在代码中也可以实现这样的操作，这里不再介绍。





### (3) C运行时hook

TODO

http://thomasfinch.me/blog/2015/07/24/Hooking-C-Functions-At-Runtime.html



### (4) char字面常量，存放多个字符

​      char字面常量，存放多个字符。例如'abc'、'abcd'、'abcde'等。根据赋值的数据类型长度和编译器选择little endian或big endian，决定是从前还是从后选择N个字符，赋值到对应类型的变量中[^16]。

举个例子，如下

```c
unsigned value;
char* ptr = (char*)&value;

value = 'ABCD';
printf("'ABCD' = %02x%02x%02x%02x = %08x\n", ptr[0], ptr[1], ptr[2], ptr[3], value);
    
value = 'ABC';
printf("'ABC'  = %02x%02x%02x%02x = %08x\n", ptr[0], ptr[1], ptr[2], ptr[3], value);
```

> unsigned类型，即unsigned int类型，可以存放4个char类型



在MacOS用Xcode编译上面的代码，输出结果，如下

'ABCD' = 44434241 = 41424344    
'ABC'  = 43424100 = 00414243



得出如下规则：

由于是little endian，低地址的字节放在word（4个字节）的低位，总是从后到前取最后4个字节的数据，如果不满足4个字节，填充0x00。



### (5) 实现带可变参数列表的函数

* 参数类型一致
* 参数类型不一致
* 传递可变参数列表到其他函数（C、Objective-C等）

举个例子，如下

```c
#include <stdarg.h>

// 参数类型一致
int variadic_func1 (int count, ...) {
    printf("variadic_func1 called\n");
    
    int arg;
    int sum = 0;

    va_list ap;
    va_start(ap, count);
    for (int i = 0; i < count; ++i) {
        arg = va_arg(ap, int);
        sum += arg;
    }
    va_end(ap);

    return sum;
}

// 参数类型不一致
void printValues(const char *format, int length, ...)
{
    va_list args;
    va_start(args, length);
    
    while (*format != '\0') {
        if (*format == 'd') {
            int i = va_arg(args, int);
            printf("%d\n", i);
        }
        else if (*format == 'c') {
            int c = va_arg(args, int);
            printf("%c\n", c);
        }
        else if (*format == 'f') {
            double d = va_arg(args, double);
            printf("%f\n", d);
        }
        ++format;
    }
    
    va_end(args);
}

// 传递可变参数列表到其他函数
char * variadic_func2 (char *format, ...) {
    printf("variadic_func2 called\n");
    
    va_list args1;
    va_start(args1, format);
    va_list args2;
    va_copy(args2, args1);
    
    // Note: make one more byte for '\0'
    size_t bufferSize = 1 + vsnprintf(NULL, 0, format, args1);
    char *buffer = (char *)malloc(bufferSize);
    va_end(args1);
    vsnprintf(buffer, bufferSize, format, args2);
    va_end(args2);
    
    return buffer;
}
```



传递可变参数列表到Objective-C方法，如下

```objective-c
static NSString * variadic_func3 (NSString *format, ...) {
    printf("variadic_func3 called\n");
    
    va_list ap;
    va_start(ap, format);
    NSString *logMessage = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);
    
    return logMessage;
}
```







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

说明

> macOS上有关pthread函数的文档，如果在man中没有查询到，可以在下面这个Linux man手册尝试查询
>
> https://man7.org/linux/man-pages/index.html



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
> 3. pthread_kill函数，虽然命名有kill，但是它的作用不是kill某个线程，而发送signal给某个线程



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



## 5、snprintf和sprintf

sprintf和snprintf是printf系列的函数，不同于printf和fprintf，它们将字符串格式化后输出特定buffer中。



### (1) snprintf函数

snprintf函数的签名，如下

```c
int snprintf(char *restrict buffer, size_t bufsz, const char *restrict format, ... );
```

snprintf函数一共有4个参数，如下

* buffer，char类型的buffer数组
* bufsz，buffer大小。注意：这个大小需要预留一个byte，snprintf函数总是会写入一个`\0`在buffer末尾
* format，格式化字符串
* ...，可变参数列表

返回值是int类型，表示完成格式化后的字符串长度，但不包含`\0`

举个例子，如下

```c
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
```

由于是格式化后的字符串，所以无法在代码中写死bufsz的值，可以通过调用snprintf函数，传入空指针的buffer，用于计算格式化后的字符串长度，然后用这个返回值，分配length+1的buffer，这样精确创建指定大小的buffer。

注意

> snprintf函数的返回值，总是完成格式化后的字符串长度length，不包含`\0`。如果bufsz比length+1要小，填充的buffer也总是bufsz。
>
> 举个例子，如下
>
> ```c
> - (void)test_snprintf_2 {
>     const char fmt[] = "sqrt(2) = %f";
>     // Note: sizeof("<string>") will include the '\0'
>     int sz = sizeof("sqrt"); // sz is 5
>     
>     // Note: make one more byte for terminating null
>     char buf[sz + 1];
>     int length = snprintf(buf, sizeof buf, fmt, sqrt(2));
>     // Note: it's safe use %s, which buf is terminated by '\0'
>     printf("%s\n", buf);
>     printf("length: %d\n", length);
> }
> ```
>
> 输出结果，如下
>
> ```
> sqrt(
> length: 18
> ```
>
> 这里sizeof操作符，将`\0`长度也算在内，所以sz的值是5。



再举个例子，如下

```c
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
```

这里buf内容是"sqr"，不是预期的"sqrt"，是因为最后一个byte，被snprintf写入一个`\0`



### (2) sprintf函数

sprintf函数的签名，如下

```c
int sprintf( char *restrict buffer, const char *restrict format, ... );
```

sprintf函数一共有3个参数，如下

* buffer，char类型的buffer数组
* format，格式化字符串
* ...，可变参数列表

返回值是int类型，表示完成格式化后的字符串长度，但不包含`\0`

举个例子，如下

```c
- (void)test_sprintf {
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
```

和snprintf函数相比，少了一个设置buffer大小的参数bufsz，因此有些不安全，例如buffer分配的太小，sprintf函数格式化后的字符串，可能超过这个buffer大小，导致写到不可预期的内存地址。

说明

> 建议使用snprintf函数



## 6、文件操作

### (1) 判断文件/文件夹是否存在

使用access函数。

举个例子[^7]，如下

```objective-c
- (void)test_check_file_or_folder_exists {
    NSError *error;
    NSString *filePath = [[WCApplicationTool appDocumentsDirectory] stringByAppendingPathComponent:@"test.txt"];
    [WCFileTool createNewFileAtPath:filePath overwrite:YES error:&error];
    
    XCTAssertNil(error);
    
    // Case 1: check file exists
    // @see https://stackoverflow.com/questions/230062/whats-the-best-way-to-check-if-a-file-exists-in-c
    if (access(filePath.UTF8String, F_OK) == 0) {
        // file exists
        XCTAssertTrue(YES);
        NSLog(@"file exists at %@", filePath);
    }
    else {
        // file doesn't exist
        XCTAssertFalse(YES);
        NSLog(@"file not exists at %@", filePath);
    }
    
    // Case 2: check folder exists
    NSString *folderPath = [WCApplicationTool appDocumentsDirectory];
    if (access(folderPath.UTF8String, F_OK) == 0) {
        // folder exists
        XCTAssertTrue(YES);
        NSLog(@"folder exists at %@", folderPath);
    }
    else {
        // folder doesn't exist
        XCTAssertFalse(YES);
        NSLog(@"folder not exists at %@", folderPath);
    }
}

```



## 7、perror、erromsg、errono、err

TODO



## 8、kqueue

kqueue是一个系统通知机制，它由BSD系统提供，它允许程序监听许多系统事件，例如signal、文件事件等。

kqueue相关系统函数，有

* kqueue函数
* kevent函数
* EV_SET宏

其中，kqueue函数创建一个kqueue的fd，而kevent函数用于设置监听和获取事件，EV_SET宏用于便利设置kevent结构体。

说明

> kqueue，对应kernel queue的缩写。而kevent，对应kernel event的缩写。

苹果官方文档对kqueue函数的描述[^9]，如下

> The kqueue() system call provides a generic method of notifying the user when an kernel event (kevent) happens or a condition holds, based on the results of small pieces of kernel code termed filters. 



在iOS上的示例代码，如下

```objective-c
- (void)installSignalEventHandler {
    // Note: create a thread to listen signal event for kqueue
    pthread_t thread;
    pthread_create(&thread, NULL, handleSignalEvent, NULL);
}

static void *handleSignalEvent(void *param)
{
    // Note: must let signal/sigaction ignore SIGINT, because the kqueue has a lower precedence
    struct sigaction action = { 0 };
    action.sa_handler = SIG_IGN;
    sigaction(SIGINT, &action, NULL);
    
    int fd = kqueue();
    struct kevent eventToRegister = {
        SIGINT,
        EVFILT_SIGNAL,
        EV_ADD,
        0,
        0
    };
    
    WCLog(@"install event handler fd: %d\n", fd);
    
    // Note: register the listening kevent
    if (kevent(fd, &eventToRegister, 1, NULL, 0, NULL) < 0) {
        perror("kevent");
    }
    
    WCLog(@"kqueque signal event handler listening...\n");
    
    for (;;) {
        struct kevent eventToGet = { 0 };
        
        // Note: listen the signal kevent
        if (kevent(fd, NULL, 0, &eventToGet, 1, NULL) < 0) {
            perror("kevent");
        }
        
        if (eventToGet.filter == EVFILT_SIGNAL) {
            WCLog(@"got signal %d\n", (int)eventToGet.ident);
            
            NSString *crashLogContent = [WCSignalTool reportableStringWithSignal:(int)eventToGet.ident];
            
            WCLog(@"CrashLog: %@", crashLogContent);
           
            NSString *filePath = SignalLogFilePath;
            [crashLogContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }

    return NULL;
}
```

> 示例代码，见HelloNSException的UseKqueueViewController

有几点需要说明

* 使用kqueue监听signal事件，和signal函数、sigaction函数相比，它的优先级低。

  苹果官方文档提到这一点[^9]，如下

  > This coexists with the signal() and sigaction() facilities, and has a lower precedence.

  因此，需要让signal函数、sigaction函数忽略特定信号，这样kqueue监听signal事件才能监听信息。上面代码让sigaction函数忽略SIGINT信号

* 上面两次调用kevent函数，用途是不一样的，第一次调用是注册监听的kevent，第二次调用是监听kevent，由于会监听到其他类型的kevent，需要使用event.filter == EVFILT_SIGNAL来找处理SIGNAL类型的kevent。

* 创建一个独立的线程用于监听signal，是因为for循环中的kevent函数会一直等待事件，必须需要新开线程，不能用于主线程中



关于kqueue函数和kevent函数，以及相关参数，用法比较复杂。这里参考苹果官方文档[^9]，以监听signal类型的kevent，做简单介绍。

kqueue函数和kevent函数的签名如下

```c
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

int kqueue(void);

int kevent(int kq, const struct kevent *changelist, int nchanges, struct kevent *eventlist, int nevents, const struct timespec *timeout);

EV_SET(&kev, ident, filter, flags, fflags, data, udata);
```

kqueue函数，每次调用都创建新的kqueue，并返回一个新fd

> The kqueue() system call creates a new kernel event queue and returns a descriptor.  The queue is not inherited by a child created with fork(2).



kevent函数，有2个作用：注册监听的kevent到kqueue，和从kqueue中获取kevent

> The kevent() system call is used to register events with the queue, and return any pending events to the user. 



kevent函数有6个参数，实际上可以分为4部分

* kq参数，是kqueue函数返回的值，用于指定哪个kqueue

* changelist和nchanges参数，是一对参数，分别是kevent结构体类型的数组指针，和该数组的大小。使用changelist参数，用于向kqueue注册监听的kevent。

  > The changelist argument is a pointer to an array of kevent structures, as defined in <sys/event.h>. All changes contained in the changelist are applied before any pending events are read from the queue.  The nchanges argument gives the size of  changelist.

* eventlist和nevents参数，是一对参数，分别是kevent结构体类型的数组指针，和该数组的大小。使用eventlist参数，用于从kqueue中获取kevent。一般方式都是在for循环中，每次获取一个kevent。例如上面的示例代码。

* timeout参数，是timespec结构体指针类型，用于设置监听的超时时间。如果设置NULL，则一直等待监听。

  >If timeout is a non-NULL pointer, it specifies a maximum interval to wait for an event, which will be interpreted as a struct timespec.  If timeout is a NULL pointer, kevent() waits indefinitely.



EV_SET宏，用于初始化kevent结构体。在上面示例代码，没有使用EV_SET宏，而是直接赋值kevent结构体。

> The EV_SET() macro is provided for ease of initializing a kevent structure.



### a. 监听多个kevent事件

在上面介绍kevent函数时，看到可以注册多个kevent，从而同时监听多个事件。这里参考SO上代码[^11]，示例如下

```c
int main(int argc, const char * argv[]) {
    
    if (argc != 2) {
        fprintf(stdout, "Usage: ./executable file_to_path\n");
        return 0;
    }
    
    /* A single kqueue */
    int kq = kqueue();
    /* Two kevent structs */
    int count = 2;
    struct kevent *ke = malloc(sizeof(struct kevent) * count);

    // Note: ignore signal SIGINT
    signal(SIGINT, SIG_IGN);
    
    /* Initialise one struct for the file descriptor, and one for SIGINT */
    int fd = open(argv[1], O_RDONLY);
    EV_SET(ke, fd, EVFILT_VNODE, EV_ADD | EV_CLEAR, NOTE_DELETE | NOTE_RENAME, 0, NULL);
    EV_SET(ke + 1, SIGINT, EVFILT_SIGNAL, EV_ADD, 0, 0, NULL);

    /* Register for the events */
    if (kevent(kq, ke, count, NULL, 0, NULL) < 0) {
        perror("kevent");
    }

    printf("Listening kevent...\n");
    
    while (1) {
        // Note: reset previous ke, and use it to get kevent
        memset(ke, 0x00, sizeof(struct kevent));
        if (kevent(kq, NULL, 0, ke, 1, NULL) < 0) {
            perror("kevent");
            continue;
        }

        switch (ke->filter)
        {
            /* File descriptor event: let's examine what happened to the file */
            case EVFILT_VNODE: {
                printf("Events %d on file descriptor %d\n", ke->fflags, (int) ke->ident);
                
                /*
                if (ke->fflags & NOTE_DELETE)
                    printf("The unlink() system call was called on the file referenced by the descriptor.\n");
                 */
                if (ke->fflags & NOTE_WRITE)
                    printf("A write occurred on the file referenced by the descriptor.\n");
                if (ke->fflags & NOTE_EXTEND)
                    printf("The file referenced by the descriptor was extended.\n");
                if (ke->fflags & NOTE_ATTRIB)
                    printf("The file referenced by the descriptor had its attributes changed.\n");
                /*
                if (ke->fflags & NOTE_LINK)
                    printf("The link count on the file changed.\n");
                 */
                if (ke->fflags & NOTE_RENAME)
                    printf("The file referenced by the descriptor was renamed.\n");
                if (ke->fflags & NOTE_REVOKE)
                    printf("Access to the file was revoked via revoke(2) or the underlying fileystem was unmounted.");
                break;
            }
            /* Signal event */
            case EVFILT_SIGNAL: {
                printf("Received Sigal: %s\n", strsignal((int)(ke->ident)));
                break;
            }
            /* This should never happen */
            default:
                printf("Unknown filter\n");
        }
    }
    
    return 0;
}
```

> 示例代码，见HelloKqueue的ListenMultipleEvent

上面创建两个kevent，分别监听文件变更事件，和SIGINT信号。struct kevent *ke指针指向包含两个kevent的数组，使用EV_SET宏分别设置kevent结构体。然后使用kevent函数注册这两个kevent结构体。



* 在Xcode中设置Arguments Passed On Launch，设置需要监听的文件路径。当运行程序，修改对应的文件名。
* 在Terminal中执行kill命令，`kill -s INT 18327`（18327是应用程序的PID），向程序的进程发送SIGINT信号



示例输出，如下

```
Listening kevent...
Events 32 on file descriptor 4
The file referenced by the descriptor was renamed.
Events 32 on file descriptor 4
The file referenced by the descriptor was renamed.
Received Sigal: Interrupt: 2
Received Sigal: Interrupt: 2
```







TODO

https://gist.github.com/daydreamboy/5b9b961fd4e4174cf4ae957c4fa49b1e







## 9、时间格式化 (strftime函数)

strftime函数的签名，如下

```c
size_t strftime(char *str, size_t count, const char *format, const struct tm *time);
```

有4个参数，如下

* str，char数组类型，用于存放格式化后的字符串
* count，最大可以写入str数组的byte个数
* format，格式化字符串。具体conversion specifier可以参考C manual。
* time，struct tm的指针

举个例子，如下

```c
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
}
```

strftime函数的conversion specifier，仅支持秒级别，不支持更低的时间单位。

需要自己处理秒以下的时间，举个例子[^8]，如下

```c
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
```





## 附录

### (1) 常用C函数简表

| C函数     | 签名                                     | 作用                                             |
| --------- | ---------------------------------------- | ------------------------------------------------ |
| ftruncate | int ftruncate(int fildes, off_t length); | 截取文件内容到指定长度，不足长度则填充到指定长度 |







## References

[^1]:https://stackoverflow.com/a/5249150

[^2]:https://www.javatpoint.com/dynamic-memory-allocation-in-c

[^3]:https://www.ibm.com/docs/en/zos/2.1.0?topic=lf-pthread-key-create-create-thread-specific-data-key

[^4]:https://stackoverflow.com/questions/2238564/pthread-functions-np-suffix
[^5]:https://man7.org/linux/man-pages/man3/pthread_setname_np.3.html
[^6]:https://stackoverflow.com/questions/8995650/what-does-the-prefix-in-nslog-mean

[^7]:https://stackoverflow.com/questions/230062/whats-the-best-way-to-check-if-a-file-exists-in-c

[^8]:https://stackoverflow.com/questions/1551597/using-strftime-in-c-how-can-i-format-time-exactly-like-a-unix-timestamp

[^9]: https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/kqueue.2.html
[^10]:https://www.mikeash.com/pyblog/friday-qa-2011-04-01-signal-handling.html
[^11]:https://stackoverflow.com/questions/15843147/use-kqueue-to-respond-to-more-than-one-event-type

