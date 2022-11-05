//
//  MySecretStaticLibrary.m
//  MySecretStaticLibrary
//
//  Created by wesley_chen on 2022/10/23.
//

#import "MySecretStaticLibrary.h"
#import "WCMacoCKit.h"

@implementation MySecretStaticLibrary

- (void)doSomething {
//    //NSString *string =  @"\\x18\\x35\\x3c\\x3c\\x3f";
//
    
//    char *cString =  cString1;
//    printf("%s\n", cString1);
//    printf("%s\n", cString);
    
    printf("%s\n", __TIME__);
    
    {
        char cString[] = WCEncryptedCString("hello world!", 12);
        size_t len = strlen(cString);
        //                   "hello world!"
        size_t len2 = strlen("abcdefghijkl");
        assert(len == len2);
        for (NSInteger i = 0; i < len; ++i) {
            printf("%02X ", cString[i]);
        }
        printf("\n");

        char dec[] = WCDecryptedCString(cString, 12);
        printf("%s\n", dec);
    }
}

@end
