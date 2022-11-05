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
    char enc[] = WCEncryptedCString("hello world!", 12);
    char dec[] = WCDecryptedCString(enc, 12);
    
    for (NSInteger i = 0; i < strlen(dec); ++i) {
        XCTAssertTrue("hello world!"[i] == dec[i]);
    }
}

- (void)test_use_in_library {
    {
        MySecretStaticLibrary *object = [MySecretStaticLibrary new];
        [object doSomething];
    }
}

@end
