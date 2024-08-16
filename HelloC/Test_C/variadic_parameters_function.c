//
//  variadic_parameters_function.c
//  Test_C
//
//  Created by wesley_chen on 2024/8/16.
//

#include "variadic_parameters_function.h"

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

int variadic_func1 (int count, ...) {
    printf("variadic_func1 called\n");
    
    int arg;
    int sum = 0;

    va_list ap;
    va_start(ap, count);
    for (int i = 0; i < count; ++i) {
        arg = va_arg(ap, int);
        sum += arg;
    }
    va_end(ap);

    return sum;
}

// Caller should free returned pointer
char * variadic_func2 (char *format, ...) {
    printf("variadic_func2 called\n");
    
    // Example modified from https://en.cppreference.com/w/c/io/vfprintf
    va_list args1;
    va_start(args1, format);
    va_list args2;
    va_copy(args2, args1);
    
    // Note: make one more byte for '\0'
    size_t bufferSize = 1 + vsnprintf(NULL, 0, format, args1);
    char *buffer = (char *)malloc(bufferSize);
    va_end(args1);
    vsnprintf(buffer, bufferSize, format, args2);
    va_end(args2);
    
    return buffer;
}

void printValues(const char *format, int length, ...)
{
    va_list args;
    va_start(args, length);
    
    while (*format != '\0') {
        if (*format == 'd') {
            int i = va_arg(args, int);
            printf("%d\n", i);
        }
        else if (*format == 'c') {
            int c = va_arg(args, int);
            printf("%c\n", c);
        }
        else if (*format == 'f') {
            double d = va_arg(args, double);
            printf("%f\n", d);
        }
        ++format;
    }
    
    va_end(args);
}


