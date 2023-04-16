//
//  main.m
//  HelloC
//
//  Created by wesley_chen on 2022/10/23.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

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
    NSLog(@"%p", add);

    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}

