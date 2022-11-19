//
//  Test.m
//  Test
//
//  Created by wesley_chen on 2022/11/6.
//

#import <XCTest/XCTest.h>

typedef struct {
    id self;
    Class cls;
    SEL cmd;
    uint64_t index;
} thread_call_record;

@interface Test : XCTestCase

@end

@implementation Test

- (void)test_malloc_for_int {
    int size = 10;
    int *ptr = (int *)malloc(size * sizeof(int));
    
    for (int i = 0; i < size; ++i) {
        ptr[i] = i + 1;
    }
    
    for (int i = 0; i < size; ++i) {
        printf("%d ", ptr[i]);
    }
    printf("\n");
    
    free(ptr);
}

- (void)test_malloc_for_char {
    int size = 10;
    char *ptr = (char *)malloc(size * sizeof(char));
    
    for (int i = 0; i < size; ++i) {
        ptr[i] = 'A' + i;
    }
    
    for (int i = 0; i < size; ++i) {
        printf("%c ", ptr[i]);
    }
    printf("\n");
    
    free(ptr);
}

- (void)test_malloc_for_struct {
    int size = 3;
    thread_call_record *ptr = (thread_call_record *)malloc(size * sizeof(thread_call_record));
    
    for (int i = 0; i < size; ++i) {
        thread_call_record *record = &ptr[i];
        record->self = self;
        record->cls = [self class];
        record->cmd = _cmd;
        record->index = i;
    }
    
    for (int i = 0; i < size; ++i) {
        thread_call_record record = ptr[i];
        printf("index:%llu, self: %s, cls: %s, cmd: %s\n", record.index, [record.self description].UTF8String, NSStringFromClass(record.cls).UTF8String, sel_getName(record.cmd));
    }
    
    free(ptr);
}

- (void)test_calloc_initialized_with_zero {
    int count = 10;
    int *ptr = (int *)calloc(count, sizeof(int));
    
    for (int i = 0; i < count; ++i) {
        printf("%d ", ptr[i]);
    }
    printf("\n");
    
    free(ptr);
}

- (void)test_calloc_for_char {
    int count = 10;
    char *ptr = (char *)calloc(count, sizeof(char));
    
    for (int i = 0; i < count; ++i) {
        ptr[i] = 'A' + i;
    }
    
    for (int i = 0; i < count; ++i) {
        printf("%c ", ptr[i]);
    }
    printf("\n");
    
    free(ptr);
}

- (void)test_calloc_for_struct {
    int count = 3;
    thread_call_record *ptr = (thread_call_record *)calloc(count, sizeof(thread_call_record));
    
    for (int i = 0; i < count; ++i) {
        thread_call_record *record = &ptr[i];
        record->self = self;
        record->cls = [self class];
        record->cmd = _cmd;
        record->index = i;
    }
    
    for (int i = 0; i < count; ++i) {
        thread_call_record record = ptr[i];
        printf("index:%llu, self: %s, cls: %s, cmd: %s\n", record.index, [record.self description].UTF8String, NSStringFromClass(record.cls).UTF8String, sel_getName(record.cmd));
    }
    
    free(ptr);
}

- (void)test_realloc_for_char {
    int size = 10;
    int extraSize = 1024;
    char *ptr = (char *)malloc(size * sizeof(char));
    
    int i = 0;
    for (; i < size; ++i) {
        ptr[i] = 'A' + i;
    }
    printf("old ptr: %p\n", ptr);
    
    // Note: realloc memory with the original pointer
    ptr = realloc(ptr, size + extraSize);
    
    int additionalSize = MIN(extraSize, 5);
    
    printf("new ptr: %p\n", ptr);
    for (; i < size + additionalSize; ++i) {
        ptr[i] = 'A' + i;
    }
    
    for (int i = 0; i < size + additionalSize; ++i) {
        printf("%c ", ptr[i]);
    }
    printf("\n");
    
    free(ptr);
}

@end
