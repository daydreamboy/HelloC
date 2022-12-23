//
//  main.m
//  HelloC
//
//  Created by wesley_chen on 2022/10/23.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

#import <pthread/pthread.h>

static void *handleSignalEvent(void *param);

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    
    pthread_t thread;
    pthread_create(&thread, NULL, handleSignalEvent, NULL);

    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}

static void *handleSignalEvent(void *param)
{
    
    /* A single kqueue */
    int kq = kqueue();
    /* Two kevent structs */
    int count = 1;
    struct kevent *ke = malloc(sizeof(struct kevent) * count);

    /* Initialise one struct for the file descriptor, and one for SIGINT */
//    int fd = open(argv[1], O_RDONLY);
//    EV_SET(ke, fd, EVFILT_VNODE, EV_ADD | EV_CLEAR, NOTE_DELETE | NOTE_RENAME, 0, NULL);
    signal(SIGINT, SIG_IGN);
    EV_SET(ke/* + 1*/, SIGINT, EVFILT_SIGNAL, EV_ADD, 0, 0, NULL);

    /* Register for the events */
    if(kevent(kq, ke, count, NULL, 0, NULL) < 0)
        perror("kevent");

    while(1) {
        memset(ke, 0x00, sizeof(struct kevent));
        if(kevent(kq, NULL, 0, ke, 1, NULL) < 0)
            perror("kevent");

        switch(ke->filter)
        {
            /* File descriptor event: let's examine what happened to the file */
            case EVFILT_VNODE:
                printf("Events %d on file descriptor %d\n", ke->fflags, (int) ke->ident);

                if(ke->fflags & NOTE_DELETE)
                    printf("The unlink() system call was called on the file referenced by the descriptor.\n");
                if(ke->fflags & NOTE_WRITE)
                    printf("A write occurred on the file referenced by the descriptor.\n");
                if(ke->fflags & NOTE_EXTEND)
                    printf("The file referenced by the descriptor was extended.\n");
                if(ke->fflags & NOTE_ATTRIB)
                    printf("The file referenced by the descriptor had its attributes changed.\n");
                if(ke->fflags & NOTE_LINK)
                    printf("The link count on the file changed.\n");
                if(ke->fflags & NOTE_RENAME)
                    printf("The file referenced by the descriptor was renamed.\n");
                if(ke->fflags & NOTE_REVOKE)
                    printf("Access to the file was revoked via revoke(2) or the underlying fileystem was unmounted.");
                break;

            /* Signal event */
            case EVFILT_SIGNAL:
                printf("Received %s\n", strsignal(ke->ident));
//                exit(42);
                break;

            /* This should never happen */
            default:
                printf("Unknown filter\n");
        }
    }
    
    return NULL;
}
