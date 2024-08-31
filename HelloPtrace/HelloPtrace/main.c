//
//  main.c
//  HelloPtrace
//
//  Created by wesley_chen on 2024/8/31.
//

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/ptrace.h>
#include <unistd.h>

// Example from https://gist.github.com/camillobruni/6602939
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
