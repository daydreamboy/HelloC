//
//  WCFileTool.h
//  Test_C
//
//  Created by wesley_chen on 2022/12/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WCFileTool : NSObject

@end

@interface WCFileTool ()
+ (BOOL)createNewFileAtPath:(NSString *)path overwrite:(BOOL)overwrite error:(NSError * _Nullable * _Nullable)error;
@end

NS_ASSUME_NONNULL_END
