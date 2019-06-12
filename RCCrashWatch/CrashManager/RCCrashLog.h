//
//  RCCrashLog.h
//  GHistory
//
//  Created by rong on 2019/5/7.
//  Copyright © 2019 perfect. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCCrashLog : NSObject
+ (void)collectCrashInfoWithException:(NSException *)exception exceptionStackInfo:(NSString *)exceptionStackInfo viewControllerStackInfo:(NSString *)viewControllerStackInfo;
+ (void)uploadCrashLogToServer;
@end

NS_ASSUME_NONNULL_END
