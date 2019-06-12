//
//  ViewController.m
//  RCCrashWatch
//
//  Created by rong on 2019/6/12.
//  Copyright © 2019 rong. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

typedef struct Test
{
    int a;
    int b;
}Test;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    
    UIButton *crashExcButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 44, self.view.bounds.size.width, 50)];
    crashExcButton.backgroundColor = [UIColor redColor];
    [crashExcButton setTitle:@"Exception" forState:UIControlStateNormal];
    [crashExcButton addTarget:self action:@selector(crashExcClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:crashExcButton];
    
    UIButton *crashSignalEGVButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 60+44, self.view.bounds.size.width, 50)];
    crashSignalEGVButton.backgroundColor = [UIColor redColor];
    [crashSignalEGVButton setTitle:@"Signal(EGV)" forState:UIControlStateNormal];
    [crashSignalEGVButton addTarget:self action:@selector(crashSignalEGVClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:crashSignalEGVButton];
    
    UIButton *crashSignalBRTButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 120+44, self.view.bounds.size.width, 50)];
    crashSignalBRTButton.backgroundColor = [UIColor redColor];
    [crashSignalBRTButton setTitle:@"Signal(ABRT)" forState:UIControlStateNormal];
    [crashSignalBRTButton addTarget:self action:@selector(crashSignalBRTClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:crashSignalBRTButton];
    
    UIButton *crashSignalBUSButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 180+44, self.view.bounds.size.width, 50)];
    crashSignalBUSButton.backgroundColor = [UIColor redColor];
    [crashSignalBUSButton setTitle:@"Signal(BUS)" forState:UIControlStateNormal];
    [crashSignalBUSButton addTarget:self action:@selector(crashSignalBUSClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:crashSignalBUSButton];
}

- (void)crashSignalEGVClick {
    UIView *view = [[UIView alloc] init];
    [view performSelector:NSSelectorFromString(@"release")];//导致SIGSEGV的错误，一般会导致进程流产
    view.backgroundColor = [UIColor whiteColor];
}

- (void)crashSignalBRTClick {
    Test *pTest = {1,2};
    free(pTest);//导致SIGABRT的错误，因为内存中根本就没有这个空间，哪来的free，就在栈中的对象而已
    pTest->a = 5;
}

- (void)crashSignalBUSClick {
    //SIGBUS，内存地址未对齐
    //EXC_BAD_ACCESS(code=1,address=0x1000dba58)
    char *s = "hello world";
    *s = 'H';
}

- (void)crashExcClick {
    [self performSelector:@selector(aaaa)];
}


@end
