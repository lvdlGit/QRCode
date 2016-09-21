//
//  QRCodeViewController.m
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

#import "QRCodeViewController.h"

@interface QRCodeViewController () <AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

//输入输出的中间桥梁
@property (nonatomic, strong) AVCaptureSession *session;
//
@property (nonatomic,strong) AVCaptureDevice *device;
//
@property (nonatomic, strong) AVCaptureDeviceInput *input;
//
@property (nonatomic, strong) AVCaptureMetadataOutput *output;
//
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;

//扫描结果
@property (nonatomic, strong) NSString *scannedResult;

//扫描框
@property (nonatomic, strong) UIImageView *imageView;

//扫描线
@property (nonatomic, strong) UIImageView *line;

//添加输入文本框
@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) BOOL isLightOpenOrClose;  // 闪光灯开关

@property (nonatomic, assign) NSInteger num;

@property (nonatomic, assign) BOOL upOrDown;

@end

@implementation QRCodeViewController

- (void)viewDidDisappear:(BOOL)animated
{
    //视图退出，关闭扫描
    [self.session stopRunning];
    
    //关闭定时器
    [_timer setFireDate:[NSDate distantFuture]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //1 判断是否存在相机
    if (self.device == nil) {
        [self showAlertViewWithTitle:nil withMessage:@"未检测到相机"];
        
        return;
    }
    self.view.backgroundColor = [UIColor whiteColor];
    
    //打开定时器，开始扫描
    [self addTimer];
    
    //界面初始化
    [self interfaceSetup];
    
    //初始化扫描
    [self scanSetup];
    
}

- (void)addTimer
{
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.008 target:self selector:@selector(timerMethod) userInfo:nil repeats:YES];
}

#pragma mark - 界面初始化
- (void)interfaceSetup
{
    //1 添加扫描框
    [self addImageView];
    
    //添加模糊效果
    [self setOverView];
    
    //添加开始扫描按钮
    [self addStartButton];
    
    //添加选择照片二维码按钮
    [self addChooseImageButton];
    
    //添加闪光灯
    [self addLightButton];
}

#pragma mark - 初始化扫描配置
- (void)scanSetup
{
    //2 添加预览图层
    self.preview.frame = self.view.bounds;
    self.preview.videoGravity = AVLayerVideoGravityResize;
    [self.view.layer insertSublayer:self.preview atIndex:0];
    
    //3 设置输出能够解析的数据类型
    //注意:设置数据类型一定要在输出对象添加到回话之后才能设置
    [self.output setMetadataObjectTypes:@[AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeQRCode]];
    
    //高质量采集率
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    
    //4 开始扫描
    [self.session startRunning];
    
}

//添加扫描框
- (void)addImageView
{
    _imageView = [[UIImageView alloc]initWithFrame:CGRectMake((Width-SWidth)/2, (Height-SWidth)/2, SWidth, SWidth)];
    //显示扫描框
    _imageView.image = [UIImage imageNamed:@"scanscanBg.png"];
    [self.view addSubview:_imageView];
    _line = [[UIImageView alloc]initWithFrame:CGRectMake(CGRectGetMinX(_imageView.frame)+5, CGRectGetMinY(_imageView.frame)+5, CGRectGetWidth(_imageView.frame), 3)];
    _line.image = [UIImage imageNamed:@"scanLine@2x.png"];
    [self.view addSubview:_line];
}

// 添加模糊效果
- (void)setOverView {
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight(self.view.frame);
    
    CGFloat x = CGRectGetMinX(_imageView.frame);
    CGFloat y = CGRectGetMinY(_imageView.frame);
    CGFloat w = CGRectGetWidth(_imageView.frame);
    CGFloat h = CGRectGetHeight(_imageView.frame);
    
    [self creatView:CGRectMake(0, 0, width, y)];
    [self creatView:CGRectMake(0, y, x, h)];
    [self creatView:CGRectMake(0, y + h, width, height - y - h)];
    [self creatView:CGRectMake(x + w, y, width - x - w, h)];
}

//添加开始扫描按钮
- (void)addStartButton
{
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    startButton.frame = CGRectMake(60, 420, 80, 40);
    startButton.backgroundColor = [UIColor orangeColor];
    [startButton addTarget:self action:@selector(startButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [startButton setTitle:@"扫描" forState:UIControlStateNormal];
    [self.view addSubview:startButton];
}

//添加选项按钮
- (void)addChooseImageButton
{
    UIButton *chooseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    chooseButton.frame = CGRectMake(0, 0, 60, 44);
    [chooseButton setTitle:@"相册" forState:UIControlStateNormal];
    [chooseButton addTarget:self action:@selector(chooseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:chooseButton];
    //解决自定义leftBarbuttonItem左滑返回手势失效的问题
    //    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
}

//添加闪光灯控制开关
- (void)addLightButton
{
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    startButton.frame = CGRectMake(180, 420, 80, 40);
    startButton.backgroundColor = [UIColor orangeColor];
    [startButton addTarget:self action:@selector(lightButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [startButton setTitle:@"灯光" forState:UIControlStateNormal];
    [self.view addSubview:startButton];
}



#pragma mark -懒加载 
//session
- (AVCaptureSession *)session
{
    if (_session == nil) {
        //session
        _session = [[AVCaptureSession alloc]init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        if ([_session canAddInput:self.input]) {
            [_session addInput:self.input];
        }
        if ([_session canAddOutput:self.output]) {
            [_session addOutput:self.output];
        }
    }
    return _session;
}

//device
- (AVCaptureDevice *)device
{
    if (_device == nil) {
        //AVMediaTypeVideo是打开相机
        //AVMediaTypeAudio是打开麦克风
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _device;
}

//input
- (AVCaptureDeviceInput *)input
{
    if (_input == nil) {
        _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    }
    return _input;
}

//output  --- output如果不打开就无法输出扫描得到的信息
// 设置输出对象解析数据时感兴趣的范围
// 默认值是 CGRect(x: 0, y: 0, width: 1, height: 1)
// 通过对这个值的观察, 我们发现传入的是比例
// 注意: 参照是以横屏的左上角作为, 而不是以竖屏
//        out.rectOfInterest = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
- (AVCaptureMetadataOutput *)output
{
    if (_output == nil) {
        _output = [[AVCaptureMetadataOutput alloc]init];
        [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        //限制扫描区域(上下左右)
        [_output setRectOfInterest:[self rectOfInterestByScanViewRect:_imageView.frame]];
    }
    return _output;
}

//preview
- (AVCaptureVideoPreviewLayer *)preview
{
    if (_preview == nil) {
        _preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    }
    return _preview;
}

#pragma mark - 计算 扫描 区域
- (CGRect)rectOfInterestByScanViewRect:(CGRect)rect {
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight(self.view.frame);
    
    CGFloat x = (height - CGRectGetHeight(rect)) / 2 / height;
    CGFloat y = (width - CGRectGetWidth(rect)) / 2 / width;
    
    CGFloat w = CGRectGetHeight(rect) / height;
    CGFloat h = CGRectGetWidth(rect) / width;
    
    return CGRectMake(x, y, w, h);
}




#pragma mark - UIImagePickerControllerDelegate 从相册中选取照片&读取相册二维码信息
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    //1 获取选择的图片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    //初始化一个监听器
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
    [picker dismissViewControllerAnimated:YES completion:^{
        //监测到的结果数组
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        if (features.count >= 1) {
            //结果对象
            CIQRCodeFeature *feature = [features objectAtIndex:0];
            NSString *scannedResult = feature.messageString;
            [self showAlertViewWithTitle:@"读取相册二维码" withMessage:scannedResult];
        }
        else {
            [self showAlertViewWithTitle:@"读取相册二维码" withMessage:@"读取失败"];
        }
    }];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate 扫描的代理方法
//得到扫描结果
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if ([metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        if ([metadataObject isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            NSString *stringValue = [metadataObject stringValue];
            if (stringValue != nil) {
                [self.session stopRunning];
                //扫描结果
                self.scannedResult = stringValue;
                NSLog(@"%@",stringValue);
                [self showAlertViewWithTitle:nil withMessage:stringValue];
            }
        }
    }
}


#pragma mark - click / timer event

#pragma mark - 添加扫描线动画效果
//控制扫描线上下滚动
- (void)timerMethod
{
    if (_upOrDown == NO) {
        _num ++;
        _line.frame = CGRectMake(CGRectGetMinX(_imageView.frame)+5, CGRectGetMinY(_imageView.frame)+5+_num, CGRectGetWidth(_imageView.frame)-10, 3);
        if (_num == (int)(CGRectGetHeight(_imageView.frame)-10)) {
            _upOrDown = YES;
        }
    }
    else
    {
        _num --;
        _line.frame = CGRectMake(CGRectGetMinX(_imageView.frame)+5, CGRectGetMinY(_imageView.frame)+5+_num, CGRectGetWidth(_imageView.frame)-10, 3);
        if (_num == 0) {
            _upOrDown = NO;
        }
    }
}

#pragma mark - 开始扫描
- (void)startButtonClick
{
    //清除imageView上的图片
    self.imageView.image = [UIImage imageNamed:@""];
    //开始扫描
    [self starScan];
}

- (void)starScan
{
    //开始扫描
    [self.session startRunning];
    //打开定时器
    [_timer setFireDate:[NSDate distantPast]];
    //显示扫描线
    _line.hidden = NO;
}

#pragma mark - 从相册读取二维码并扫描

//打开系统相册
- (void)chooseButtonClick
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        //关闭扫描
        [self stopScan];
        
        //1 弹出系统相册
        UIImagePickerController *pickVC = [[UIImagePickerController alloc]init];
        //2 设置照片来源
        /**
         UIImagePickerControllerSourceTypePhotoLibrary,相册
         UIImagePickerControllerSourceTypeCamera,相机
         UIImagePickerControllerSourceTypeSavedPhotosAlbum,照片库
         */
        
        pickVC.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        //3 设置代理
        pickVC.delegate = self;
        //4.随便给他一个转场动画
        self.modalTransitionStyle=UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:pickVC animated:YES completion:nil];
    }
    else {
        
        [self showAlertViewWithTitle:@"打开失败" withMessage:@"相册打开失败。设备不支持访问相册，请在设置->隐私->照片中进行设置！"];
    }
}

#pragma mark - 停止扫描
- (void)stopScan
{
    //弹出提示框后，关闭扫描
    [self.session stopRunning];
    //弹出alert，关闭定时器
    [_timer setFireDate:[NSDate distantFuture]];
    //隐藏扫描线
    _line.hidden = YES;
}

#pragma mark - 重启扫描 & 闪光灯

- (void)lightButtonClick
{
    _isLightOpenOrClose = !_isLightOpenOrClose;
    //开启闪光灯
    [self systemLightSwitch:_isLightOpenOrClose];
}

#pragma mark - 开启闪光灯
- (void)systemLightSwitch:(BOOL)open
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        if (open) {
            [device setTorchMode:AVCaptureTorchModeOn];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}

#pragma mark - custom method

- (void)creatView:(CGRect)rect
{
    CGFloat alpha = 0.5;
    UIColor *backColor = [UIColor blueColor];
    UIView *view = [[UIView alloc] initWithFrame:rect];
    view.backgroundColor = backColor;
    view.alpha = alpha;
    [self.view addSubview:view];
}

#pragma mark - 添加提示框
//提示框alert
- (void)showAlertViewWithTitle:(NSString *)title withMessage:(NSString *)message
{
    
    //弹出提示框后，关闭扫描
    [self.session stopRunning];
    //弹出alert，关闭定时器
    [_timer setFireDate:[NSDate distantFuture]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //点击alert，开始扫描
        [self.session startRunning];
        //开启定时器
        [_timer setFireDate:[NSDate distantPast]];
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
