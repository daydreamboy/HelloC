//
//  Test_File.m
//  Test_C
//
//  Created by wesley_chen on 2022/12/20.
//

#import <XCTest/XCTest.h>
#import "WCFileTool.h"
#import "WCApplicationTool.h"

#import <unistd.h>

@interface Test_File : XCTestCase

@end

@implementation Test_File

- (void)test_check_file_or_folder_exists {
    NSError *error;
    NSString *filePath = [[WCApplicationTool appDocumentsDirectory] stringByAppendingPathComponent:@"test.txt"];
    [WCFileTool createNewFileAtPath:filePath overwrite:YES error:&error];
    
    XCTAssertNil(error);
    
    // Case 1: check file exists
    // @see https://stackoverflow.com/questions/230062/whats-the-best-way-to-check-if-a-file-exists-in-c
    if (access(filePath.UTF8String, F_OK) == 0) {
        // file exists
        XCTAssertTrue(YES);
        NSLog(@"file exists at %@", filePath);
    }
    else {
        // file doesn't exist
        XCTAssertFalse(YES);
        NSLog(@"file not exists at %@", filePath);
    }
    
    // Case 2: check folder exists
    NSString *folderPath = [WCApplicationTool appDocumentsDirectory];
    if (access(folderPath.UTF8String, F_OK) == 0) {
        // folder exists
        XCTAssertTrue(YES);
        NSLog(@"folder exists at %@", folderPath);
    }
    else {
        // folder doesn't exist
        XCTAssertFalse(YES);
        NSLog(@"folder not exists at %@", folderPath);
    }
}

@end
