//
//  CreateCodeViewController.m
//  QrCode
//
//  Created by lvdl on 16/9/20.
//  Copyright © 2016年 www.palcw.com. All rights reserved.
//

#define Height [UIScreen mainScreen].bounds.size.height
#define Width [UIScreen mainScreen].bounds.size.width
#define XCenter self.view.center.x
#define YCenter self.view.center.y

#define SHeight 20

#define SWidth (XCenter+30)

#import "CreateCodeViewController.h"

@interface CreateCodeViewController ()

@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) UIImageView *imgView;

@end

@implementation CreateCodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIView *bgView = [[UIView alloc] init];
    [self.view addSubview:bgView];
    bgView.frame = self.view.frame;
    bgView.backgroundColor = [UIColor colorWithRed:51 / 255.0 green:51 / 255.0 blue:51 / 255.0 alpha:0.5];
    
    // 输入框
    [self addTextFieldInput];
    
    // 制作二维码 图片
    [self addMakeButton];
    
    // 保存 二维码 图片
    [self addSaveImageButton];
    
    // 显示 二维码 图片
    [self myImageView];
}

//添加文本框
- (void)addTextFieldInput
{
    _textField = [[UITextField alloc]init];
    [self.view addSubview:_textField];
    _textField.frame = CGRectMake((Width - 280) * 0.5, 80, 280, 40);
    _textField.backgroundColor = [UIColor whiteColor];
    [_textField resignFirstResponder];
    _textField.placeholder = @"请输入二维码内容";
}

//添加制作按钮
- (void)addMakeButton
{
    UIButton *makeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    makeButton.frame = CGRectMake(60, 130, 80, 40);
    makeButton.backgroundColor = [UIColor orangeColor];
    [makeButton addTarget:self action:@selector(createQrCode) forControlEvents:UIControlEventTouchUpInside];
    [makeButton setTitle:@"制作" forState:UIControlStateNormal];
    [self.view addSubview:makeButton];
}

//添加保存二维码图片的按钮
- (void)addSaveImageButton
{
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveButton.frame = CGRectMake(180, 130, 80, 40);
    saveButton.backgroundColor = [UIColor orangeColor];
    [saveButton setTitle:@"保存" forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveImageToPhotoLib) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveButton];
}

- (void)myImageView
{
    _imgView = [[UIImageView alloc] initWithFrame:CGRectMake((Width-SWidth)/2, (Height-SWidth)/2, SWidth, SWidth)];
    
    [self.view addSubview:_imgView];
    
    _imgView.layer.borderColor = [UIColor purpleColor].CGColor;
    _imgView.layer.borderWidth = 1.0f;
}


#pragma mark - click event
- (void)createQrCode
{
    //键盘下落
    [self.view endEditing:YES];
    
    
    // 1.创建过滤器
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    // 2.恢复默认
    [filter setDefaults];
    
    // 3.给过滤器添加数据(正则表达式/账号和密码)
    NSData *data = [_textField.text dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKeyPath:@"inputMessage"];
    
    // 4.获取输出的二维码
    CIImage *outputImage = [filter outputImage];
    
    //因为生成的二维码模糊，所以通过createNonInterpolatedUIImageFormCIImage:outputImage来获得高清的二维码图片
    
    // 5.显示二维码
    _imgView.image = [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:260];
}

/**
 *  根据CIImage生成指定大小的UIImage
 *
 *  @param image CIImage
 *  @param size  图片宽度
 */
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

#pragma mark - 将二维码图片保存到相册
- (void)saveImageToPhotoLib
{
    UIImageWriteToSavedPhotosAlbum(_imgView.image, self, @selector(saveImage:didFinishSavingWithError:contextInfo:), nil);
}

- (void)saveImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error == nil) {
        [self showAlertViewWithTitle:@"保存图片" withMessage:@"成功"];
    }
    else
    {
        [self showAlertViewWithTitle:@"保存图片" withMessage:@"失败"];
    }
}

#pragma mark - 添加提示框
//提示框alert
- (void)showAlertViewWithTitle:(NSString *)title withMessage:(NSString *)message
{

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

    }]];
    [self presentViewController:alert animated:true completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
