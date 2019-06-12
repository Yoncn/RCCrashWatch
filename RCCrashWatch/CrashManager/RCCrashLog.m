//
//  RCCrashLog.m
//  GHistory
//
//  Created by rong on 2019/5/7.
//  Copyright © 2019 perfect. All rights reserved.
//

#import "RCCrashLog.h"

#define CrashLogDirectory @"CrashLog"
#define CrashLogFileName @"crashLog.log"

@implementation RCCrashLog

+ (void)collectCrashInfoWithException:(NSException *)exception exceptionStackInfo:(NSString *)exceptionStackInfo viewControllerStackInfo:(NSString *)viewControllerStackInfo {
    NSMutableDictionary *crashInfoDic = [NSMutableDictionary dictionary];

//require
    NSString *dateStr = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    [crashInfoDic setObject:dateStr forKey:@"date"];
    [crashInfoDic setObject:exception.name forKey:@"type"];
    [crashInfoDic setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] forKey:@"version"];
    //exception log info
    NSMutableDictionary *exceptionInfoDic = [NSMutableDictionary dictionary];
    [exceptionInfoDic setObject:exception.name forKey:@"exception_name"];
    [exceptionInfoDic setObject:exception.reason forKey:@"exception_reason"];
    [exceptionInfoDic setObject:exceptionStackInfo forKey:@"exception_stackInfo"];
    NSData *exceptionInfoData = [NSJSONSerialization dataWithJSONObject:exceptionInfoDic options:NSJSONWritingPrettyPrinted error:nil];
    [crashInfoDic setObject:[[NSString alloc] initWithData:exceptionInfoData encoding:NSUTF8StringEncoding] forKey:@"log"];
    
//optional
#ifdef DEBUG
    [crashInfoDic setObject:@"DEBUG" forKey:@"environment"];
#else
    [crashInfoDic setObject:@"RELEASE" forKey:@"environment"];
#endif
    [crashInfoDic setObject:viewControllerStackInfo forKey:@"track"];
    
    //read
    NSData *oldCrashData = [NSData dataWithContentsOfFile:[RCCrashLog getCrashLogSavePath]];
    NSMutableArray *oldCrashArray;
    if (oldCrashData.length == 0) {
        oldCrashArray = [NSMutableArray array];
    } else {
        oldCrashArray = [NSJSONSerialization JSONObjectWithData:oldCrashData options:NSJSONReadingMutableContainers error:nil];
    }
    [oldCrashArray addObject:crashInfoDic];
    
    //write
    NSData *newCrashData = [NSJSONSerialization dataWithJSONObject:oldCrashArray options:NSJSONWritingPrettyPrinted error:nil];
    [newCrashData writeToFile:[RCCrashLog getCrashLogSavePath] atomically:YES];
}


+ (NSString *)getCrashLogSavePath {
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    NSString *crashLogDir = [documentPath stringByAppendingPathComponent:CrashLogDirectory];
    BOOL isDir = NO;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:crashLogDir isDirectory:&isDir];
    if (!isExist || !isDir) {
        BOOL isSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:crashLogDir withIntermediateDirectories:YES attributes:nil error:nil];
        if (!isSuccess) {
            NSLog(@"******文件夹创建失败*******");
            return nil;
        }
    }
    
    NSString *crashLogPath = [crashLogDir stringByAppendingPathComponent:CrashLogFileName];
    isDir = NO;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:crashLogPath isDirectory:&isDir];
    if (!isExist || isDir) {
        BOOL isSuccess = [[NSFileManager defaultManager] createFileAtPath:crashLogPath contents:nil attributes:nil];
        if (!isSuccess) {
            NSLog(@"******文件创建失败*******");
            return nil;
        }
    }
    
    return crashLogPath;
}


+ (void)removeCrashLog {
    NSLog(@"delete crash log success");
    [[NSFileManager defaultManager] removeItemAtPath:[RCCrashLog getCrashLogSavePath] error:nil];
}



+ (void)uploadCrashLogToServer {
    NSData *logData = [NSData dataWithContentsOfFile:[RCCrashLog getCrashLogSavePath]];
    NSArray *log = [NSJSONSerialization JSONObjectWithData:logData options:NSJSONReadingMutableLeaves error:nil];
    if (log.count == 0) {
        return;
    }
    //upload
}



@end
