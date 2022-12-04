//
//  WCPthreadTool.h
//  HelloPthread
//
//  Created by wesley_chen on 2022/12/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WCPthreadTool : NSObject

@end

/**
 Get current calling thread ID
 
 @return the thread ID
 
 @see https://stackoverflow.com/questions/8995650/what-does-the-prefix-in-nslog-mean
 */
__uint64_t WCGetCurrentPthreadID(void);

NS_ASSUME_NONNULL_END
