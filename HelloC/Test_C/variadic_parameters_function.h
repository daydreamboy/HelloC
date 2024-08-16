//
//  variadic_parameters_function.h
//  Test_C
//
//  Created by wesley_chen on 2024/8/16.
//

#ifndef variadic_parameters_function_h
#define variadic_parameters_function_h


int variadic_func1 (int count, ...);
char * variadic_func2 (char *format, ...);

/**
 A simple print values function, just for demo
 
 - Parameters:
 - format: the format string, like printf
 - length: the length of format string
 - ...: the variadic list
 */
void printValues(const char *format, int length, ...);


#endif /* variadic_parameters_function_h */
