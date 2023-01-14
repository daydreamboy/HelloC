//
//  main.c
//  HelloKqueue
//
//  Created by wesley_chen on 2023/1/14.
//

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

// Example code from https://stackoverflow.com/questions/15843147/use-kqueue-to-respond-to-more-than-one-event-type
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
