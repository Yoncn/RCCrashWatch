//
//  RCCrashManager.m
//  GHistory
//
//  Created by rong on 2019/5/5.
//  Copyright © 2019 perfect. All rights reserved.
//

#import "RCCrashManager.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import "RCCrashLog.h"
#import "AppDelegate.h"

@interface RCCrashManager ()
@property (nonatomic, assign) BOOL dismissed;
@end

NSUncaughtExceptionHandler *OldHandler = nil;
//void (*OldAbrtSignalHandler)(int, struct __siginfo *, void *);

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

const NSInteger UncaughtExceptionHandlerReportAddressCount = 20;//指明获取多少条调用堆栈信息

@implementation RCCrashManager

+ (NSArray *)backtrace {
    void *callStack[128];//堆栈方法数组
    int frames = backtrace(callStack, 128);//获取错误堆栈方法指针数组，返回数目
    char **strs = backtrace_symbols(callStack, frames);//符号化
    
    NSMutableArray *symbolsBackTrace=[NSMutableArray arrayWithCapacity:frames];
    
    unsigned long count = UncaughtExceptionHandlerReportAddressCount < frames ? UncaughtExceptionHandlerReportAddressCount : frames;
    for (int i = 0; i < count; i++) {
        [symbolsBackTrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    return symbolsBackTrace;
}

- (void)handleException:(NSException *)exception{
    NSString *stackInfo = [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey];
    
    
#ifdef DEBUG
    NSString *message = [NSString stringWithFormat:@"抱歉，APP发生了异常，请与开发人员联系，点击屏幕继续并自动复制错误信息到剪切板。\n\n异常报告:\n异常名称：%@\n异常原因：%@\n堆栈信息：%@\n", [exception name], [exception reason], stackInfo];
    NSLog(@"%@",message);
    [self showCrashToastWithMessage:message];

    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    while (!self.dismissed) {
        for (NSString *mode in (__bridge NSArray *)allModes) {
            //为阻止线程退出，使用 CFRunLoopRunInMode(model, 0.001, false)等待系统消息，false表示RunLoop没有超时时间
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }
    CFRelease(allModes);


#endif
    
    [RCCrashLog collectCrashInfoWithException:exception exceptionStackInfo:stackInfo viewControllerStackInfo:[self getCurrentViewControllerStackInfo]];
    
    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGHUP, SIG_DFL);
    signal(SIGINT, SIG_DFL);
    signal(SIGQUIT, SIG_DFL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    
    NSLog(@"%@",[exception name]);
    if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName]) {
        kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    } else {
        [exception raise];
    }
    
}

- (void)showCrashToastWithMessage:(NSString *)message {
    UILabel *crashLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 64, [UIApplication sharedApplication].keyWindow.bounds.size.width, [UIApplication sharedApplication].keyWindow.bounds.size.height - 64)];
    crashLabel.textColor = [UIColor redColor];
    crashLabel.font = [UIFont systemFontOfSize:15];
    crashLabel.text = message;
    crashLabel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    crashLabel.numberOfLines = 0;
    [[UIApplication sharedApplication].keyWindow addSubview:crashLabel];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(crashToastTapAction:)];
    crashLabel.userInteractionEnabled = YES;
    [crashLabel addGestureRecognizer:tap];
}

- (void)crashToastTapAction:(UITapGestureRecognizer *)tap {
    UILabel *crashLabel = (UILabel *)tap.view;
    [UIPasteboard generalPasteboard].string = crashLabel.text;
    self.dismissed = YES;
}

- (NSString *)getCurrentViewControllerStackInfo {
    NSMutableString *stackInfo = [NSMutableString stringWithString:@""];
    AppDelegate *appdelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIViewController *rootVC = appdelegate.window.rootViewController;
    [stackInfo appendString:NSStringFromClass([rootVC class])];
    
    //这里根据自己的页面结构追加stack信息
    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *currentNav = (UINavigationController *)rootVC;
        for (UIViewController *VC in currentNav.viewControllers) {
            [stackInfo appendFormat:@"-%@", NSStringFromClass([VC class])];
        }
    }
    
    return stackInfo;
}
@end




//oc exception
void MyExceptionHandler(NSException *exception) {
    NSArray *callStack = exception.callStackSymbols;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];

    [[[RCCrashManager alloc] init] performSelectorOnMainThread:@selector(handleException:) withObject:[NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:userInfo] waitUntilDone:YES];
    
    // 调用之前已经注册的handler
    if (OldHandler) {
        OldHandler(exception);
    }
}

void RegisterExceptionHandler(void) {
    if (NSGetUncaughtExceptionHandler() != MyExceptionHandler) {
        OldHandler = NSGetUncaughtExceptionHandler();
    }
    NSSetUncaughtExceptionHandler(&MyExceptionHandler);
}


//signal
void SignalHandler(int signal) {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:UncaughtExceptionHandlerSignalKey];
    NSArray *callBack = [RCCrashManager backtrace];
    [userInfo setObject:callBack forKey:UncaughtExceptionHandlerAddressesKey];
    
    NSException *signalException = [NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName reason:[NSString stringWithFormat:@"Signal %d was raised.",signal] userInfo:userInfo];
    [[[RCCrashManager alloc] init] performSelectorOnMainThread:@selector(handleException:) withObject:signalException waitUntilDone:YES];
}

static void MySignalHandler(int signal, siginfo_t* info, void* context) {
    SignalHandler(signal);
    
    // 处理前者注册的 handler
//    if (signal == SIGABRT) {
//        if (OldAbrtSignalHandler) {
//            OldAbrtSignalHandler(signal, info, context);
//        }
//    }
}

void RegisterSignalHandler(void) {
//    struct sigaction old_action;
//    sigaction(SIGABRT, NULL, &old_action);
//    if (old_action.sa_flags & SA_SIGINFO) {
//        if (old_action.sa_sigaction != MySignalHandler) {
//            OldAbrtSignalHandler = old_action.sa_sigaction;
//        }
//    }
//
//    struct sigaction action;
//    action.sa_sigaction = MySignalHandler;
//    action.sa_flags = SA_NODEFER | SA_SIGINFO;
//    sigemptyset(&action.sa_mask);
//    sigaction(SIGABRT, &action, 0);
    
    signal(SIGHUP, SignalHandler);
    signal(SIGINT, SignalHandler);
    signal(SIGQUIT, SignalHandler);
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
    signal(SIGPIPE, SignalHandler);
}

//public
void RegisterCrashHandler(void) {    
    RegisterExceptionHandler();
    RegisterSignalHandler();
}



