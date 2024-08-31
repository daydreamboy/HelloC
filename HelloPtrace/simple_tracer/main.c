//
//  main.c
//  simple_tracer
//
//  Created by wesley_chen on 2024/8/31.
//

#include <stdio.h>
#include <unistd.h> // fork()
#include <sys/types.h> // ptrace()
#include <sys/ptrace.h> // ptrace()
#include <sys/wait.h> // wait()

void run_target(const char* programname);
void run_debugger(pid_t child_pid);

int main(int argc, const char * argv[]) {
    pid_t child_pid;

    if (argc < 2) {
        fprintf(stderr, "Expected a program name as argument\n");
        return -1;
    }

    child_pid = fork();
    if (child_pid == 0)
        run_target(argv[1]);
    else if (child_pid > 0) {
        /* Allow tracing of this process */
        if (ptrace(PT_ATTACHEXC, 0, 0, 0) < 0) {
            perror("ptrace");
            fprintf(stdout, "error2\n");
            return -1;
        }
        run_debugger(child_pid);
    }
    else {
        perror("fork");
        return -1;
    }
    
    return 0;
}

void run_target(const char* programname)
{
    fprintf(stdout, "target started. will run '%s'\n", programname);

    /* Replace this process's image with the given program */
    execl(programname, programname, 0);
}

void run_debugger(pid_t child_pid)
{
    int wait_status;
    unsigned icounter = 0;
    fprintf(stdout, "debugger started\n");

    /* Wait for child to stop on its first instruction */
    wait(&wait_status);

    while (WIFSTOPPED(wait_status)) {
        icounter++;
        /* Make the child execute another instruction */
        if (ptrace(PT_STEP, child_pid, 0, 0) < 0) {
            perror("ptrace");
            return;
        }

        /* Wait for child to stop on its next instruction */
        wait(&wait_status);
    }

    fprintf(stdout, "the child executed %u instructions\n", icounter);
}
