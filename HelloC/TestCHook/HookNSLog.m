//
//  HookNSLog.m
//  TestCHook
//
//  Created by wesley_chen on 2023/5/5.
//

#import <Foundation/Foundation.h>

void NSLog(NSString *format, ...)
{
    va_list ap;
    va_start(ap, format);
    format = [NSString stringWithFormat:@"[Hooked]%@", format];
    NSLogv(format, ap);
    va_end(ap);
}
