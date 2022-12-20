//
//  Test_uuid.m
//  Test_C
//
//  Created by wesley_chen on 2022/12/20.
//

#import <XCTest/XCTest.h>

@interface Test_uuid : XCTestCase

@end

@implementation Test_uuid

- (void)test_create_uuid {
    static char sPrimaryEventID[37];
    create_uuid(sPrimaryEventID);
    NSLog(@"%s", sPrimaryEventID);
}

static void create_uuid(char* destinationBuffer37Bytes)
{
    uuid_t uuid;
    uuid_generate(uuid);
    // Note: 16 * 2 + 4 + 1(null terminator) = 37
    sprintf(destinationBuffer37Bytes,
            "%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
            (unsigned)uuid[0],
            (unsigned)uuid[1],
            (unsigned)uuid[2],
            (unsigned)uuid[3],
            (unsigned)uuid[4],
            (unsigned)uuid[5],
            (unsigned)uuid[6],
            (unsigned)uuid[7],
            (unsigned)uuid[8],
            (unsigned)uuid[9],
            (unsigned)uuid[10],
            (unsigned)uuid[11],
            (unsigned)uuid[12],
            (unsigned)uuid[13],
            (unsigned)uuid[14],
            (unsigned)uuid[15]
            );
}

@end
