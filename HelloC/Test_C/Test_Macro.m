//
//  Test_Macro.m
//  Test_C
//
//  Created by wesley_chen on 2022/10/23.
//

#import <XCTest/XCTest.h>
#import "WCMacoCKit.h"
#import "MySecretStaticLibrary.h"

@interface Test_Macro : XCTestCase

@end

@implementation Test_Macro

- (void)test_WCEncryptedCString {
    printf("%s\n", __TIME__);
    
    {
        char cString[] = WCEncryptedCString("hello world!");
        size_t len = strlen(cString);
        //                   "hello world!"
        size_t len2 = strlen("abcdefghijkl");
        assert(len == len2);
        for (NSInteger i = 0; i < len; ++i) {
            printf("%02X ", cString[i]);
        }
        printf("\n");
        
        // Note: the encrpted string can be displayed on console
        NSLog(@"nsstring: %@\n", [NSString stringWithUTF8String:cString]);

        char decrptedString[] = WCDecryptedCString(cString);
        printf("%s\n", decrptedString);
        //XCTAssertTrue(strcmp("hello world!", decrptedString) == 0);
    }
    
    {
        MySecretStaticLibrary *object = [MySecretStaticLibrary new];
        [object doSomething];
    }
}

@end
