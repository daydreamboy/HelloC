# HelloPtrace

[TOC]



## 1、介绍ptrace

ptrace函数是Linux、BSD等操作系统上提供一个系统调用。在MacOS的man文档描述，如下

> **ptrace**() provides tracing and debugging facilities. It allows one process (the tracing process) to control another (the traced process). Most of the time, the traced process runs normally, but when it receives a signal (see sigaction(2)), it stops. The tracing process is expected to notice this via wait(2) or the delivery of a SIGCHLD signal, examine the state of the stopped process, and cause it to terminate or continue as appropriate. **ptrace**() is the mechanism by which all this happens.

简单理解上面这段话的含义：

* ptrace提供跟踪和调试的能力，允许一个进程（tracing process）来控制另外一个进程（traced process）
* traced process大部分时间都是正常运行，除了它收到信号，它会停下来。tracing process通过wait函数或者发送SIGCHLD信号，检查已暂停进程的状态，并允许traced process终止或者继续运行。

[这篇文章](https://www.linuxjournal.com/article/6100?page=0,1)提到一些调试工具，都使用ptrace函数，如下图

<img src="images/01_ptrace_usage.png" style="zoom:100%; float:left;" />

### (1) ptrace函数签名

MacOS的man文档给出的ptrace函数签名，如下

```c
#include <sys/types.h>
#include <sys/ptrace.h>

int
ptrace(int request, pid_t pid, caddr_t addr, int data);
```

第一个参数request，代表操作类型，在`<sys/ptrace.h>`定义有下面一些类型，如下

```c
#define PT_TRACE_ME     0       /* child declares it's being traced */
#define PT_READ_I       1       /* read word in child's I space */
#define PT_READ_D       2       /* read word in child's D space */
#define PT_READ_U       3       /* read word in child's user structure */
#define PT_WRITE_I      4       /* write word in child's I space */
#define PT_WRITE_D      5       /* write word in child's D space */
#define PT_WRITE_U      6       /* write word in child's user structure */
#define PT_CONTINUE     7       /* continue the child */
#define PT_KILL         8       /* kill the child process */
#define PT_STEP         9       /* single step the child */
#define PT_ATTACH       ePtAttachDeprecated     /* trace some running process */
#define PT_DETACH       11      /* stop tracing a process */
#define PT_SIGEXC       12      /* signals as exceptions for current_proc */
#define PT_THUPDATE     13      /* signal for thread# */
#define PT_ATTACHEXC    14      /* attach to running process with signal exception */

#define PT_FORCEQUOTA   30      /* Enforce quota for root */
#define PT_DENY_ATTACH  31

#define PT_FIRSTMACH    32      /* for machine-specific requests */
```

第二个参数pid，代表需要traced process的pid。

第三个参数addr，参考[这篇文章](https://www.linuxjournal.com/article/6100?page=0,1)的示例

> `ptrace(PTRACE_PEEKTEXT, PID, addr, NULL)` - return a *WORD* read from the address `addr`, from the memory of the process `PID` (the tracee).

用于获取traced proccess内存中特定addr的值，WORD大小

第四个参数data，参考[这篇文章](https://www.linuxjournal.com/article/6100?page=0,1)的示例

> `ptrace(PTRACE_GETREGS, pid, NULL, &regs)` - copy a snapsot of the CPU’s registers running the tracee (when it stopped), into a `user_regs_struct` structure (defined in `sys/user.h)`.

用于获取traced proccess暂停时的寄存器数据。



### (2) MacOS/iOS上的ptrace

参考[这篇文章](https://www.oreilly.com/library/view/the-mac-hackers/9781118080337/9781118080337c04.xhtml)的说法，如下

> In Mac OS X, there is indeed a ptrace() system call, but it is not fully functional. It allows for attaching and detaching a process, stepping, and continuing, but does not allow for memory or registers to be read or written. Obviously a debugger without these functions would be useless.

MacOS上的ptrace功能不完整，只能连接进程、断开进程、单步、继续，但是不能查看内存或者寄存器，显然ptrace在MacOS上用处不是很大。

这里有个[gist代码](https://gist.github.com/camillobruni/6602939)，提供一个非常简单示例，如下

```c
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/ptrace.h>
#include <unistd.h>

// Usage:
// $ trace_pid <running_pid>
int main(int argc, const char * argv[]) {
    int target_pid;
    long ret;
    
    target_pid = atoi(argv[1]);
    printf("attach to PID:%i \n", target_pid);
    
    ret = ptrace(PT_ATTACHEXC, target_pid, NULL, 0);
    printf("attach %lu \n", ret);
    
    sleep(5);
    
    ret = ptrace(PT_CONTINUE, target_pid, NULL, 0);
    printf("continue %lu \n", ret);

    sleep(5);
    
    ret = ptrace(PT_DETACH, target_pid, NULL, 0);
    printf("detach %lu \n", ret);
    
    return 0;
}
```

上面简单完成三个调试操作：attach process、continue、deattach process

> 示例代码，见HelloPtrace/trace_pid



参考[这篇文章](https://www.linuxjournal.com/article/6100?page=0,1)，在iOS没有暴露ptrace函数的话，可以使用dlsym获取ptrace函数地址，如下

```c
#import <sys/types.h>
#import typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);
void functionWithPtrace() {
    ptrace_ptr_t ptrace_ptr = (ptrace_ptr_t)dlsym(RTLD_SELF, "ptrace");
    ptrace_ptr(31, 0, 0, 0); // example call PT_DENY_ATTACH
}
```



TODO:

https://www.spaceflint.com/?p=150
