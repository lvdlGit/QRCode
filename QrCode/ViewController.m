//
//  ViewController.m
//  QrCode
//
//  Created by lvdl on 16/6/30.
//  Copyright © 2016年 www.palcw.com. All rights reserved.
//

#import "ViewController.h"
#import "CreateCodeViewController.h"
#import "QRCodeViewController.h"

@interface ViewController ()



@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    

    [self configInit];
}


- (void)configInit
{
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    button1.frame = CGRectMake(100, 220, 100, 40);
    button1.backgroundColor = [UIColor orangeColor];
    [button1 setTitle:@"扫描二维码" forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(showScaning)forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    button2.frame = CGRectMake(100, 320, 100, 40);
    button2.backgroundColor = [UIColor orangeColor];
    [button2 setTitle:@"生成二维码" forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(createCoder)forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
}

- (void)showScaning
{
    QRCodeViewController  *qrCodeVC = [[QRCodeViewController alloc]init];
    qrCodeVC.hidesBottomBarWhenPushed = YES;
    
    [self.navigationController pushViewController:qrCodeVC animated:YES];
}

- (void)createCoder
{
    CreateCodeViewController  *qrCodeVC = [[CreateCodeViewController alloc]init];
//    qrCodeVC.hidesBottomBarWhenPushed = YES;
    
    [self.navigationController pushViewController:qrCodeVC animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
