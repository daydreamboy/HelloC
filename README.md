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









## References

[^1]:https://stackoverflow.com/a/5249150



