//
//  ViewController.m
//  Test_AVFoundation_Capture
//
//  Created by lidongbo on 4/14/16.
//  Copyright © 2016 lidongbo. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>



#define alertShow(aMessage)   UIAlertView *infoAlert = [[UIAlertView alloc] initWithTitle:@"提示"message:aMessage delegate:self   cancelButtonTitle:@"确认" otherButtonTitles:nil,nil];\
[infoAlert show];


@interface ViewController ()<UIAlertViewDelegate>

@property (nonatomic, strong) AVCaptureDevice * device; //捕捉设备
@property (nonatomic, strong) AVCaptureSession * captureSession; //负责输入输出设备的数据传递
@property (nonatomic, strong) AVCaptureDeviceInput * captureDeviceInput; //负责从avCaptureDevice中获得输入数据.
@property (nonatomic, strong) AVCaptureStillImageOutput *captureStillImageOutput; //照片输出流.
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer; //相机拍摄预览图层.

@property (nonatomic, strong) UIButton * cameraButton;  //拍照按钮

@property (nonatomic, strong) UIButton * flashButton;   //闪光灯

@property (nonatomic, strong) UIButton * switchButton;   //切换摄像头

@property (nonatomic, assign) BOOL isFrontCamera;   //是否前置摄像头


@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置button
    
    self.cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cameraButton.frame = CGRectMake(100, 100, 100, 40);
    [self.cameraButton setTitle:@"拍照" forState:UIControlStateNormal];
    [self.cameraButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    self.cameraButton.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.cameraButton];
    [self.cameraButton addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.flashButton.frame = CGRectMake(100, 100+60, 100, 40);
    [self.flashButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.flashButton setTitle:@"闪光灯打开" forState:UIControlStateNormal];
    [self.flashButton setTitle:@"闪光灯关闭" forState:UIControlStateSelected];
    self.flashButton.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.flashButton];
    [self.flashButton addTarget:self action:@selector(switchFlash:) forControlEvents:UIControlEventTouchUpInside];
    
    self.switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.switchButton.frame = CGRectMake(100, 100+60+60, 100, 40);
    [self.switchButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.switchButton setTitle:@"前置摄像头" forState:UIControlStateNormal];
    [self.switchButton setTitle:@"后置摄像头" forState:UIControlStateSelected];
    self.switchButton.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.switchButton];
    [self.switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    
    //初始化会话
    self.captureSession = [[AVCaptureSession alloc] init];
    
    //将捕捉会话的预设设置为图像.
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    //初始化捕捉设备.
//    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.device = [self backCamera];
    
    //用captureDevice创建输入流
    NSError *error = nil;
    self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:&error];
    
    //输入流加入会话
    if ([self.captureSession canAddInput:self.captureDeviceInput]) {
        [self.captureSession addInput:self.captureDeviceInput];
    }
    
    //创建媒体数据输出流为静态图像
    self.captureStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    
    self.captureStillImageOutput.outputSettings = outputSettings;
    
    //输出到会话中
    
    if ([self.captureSession canAddOutput:self.captureStillImageOutput]) {
        [self.captureSession addOutput:self.captureStillImageOutput];
    }
    
    //通过会话创建预览图层
    self.captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    
    //设置图层填充方式
    self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    self.captureVideoPreviewLayer.frame = self.view.bounds;
    
    [self.view.layer insertSublayer:self.captureVideoPreviewLayer atIndex:0];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startSession];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopSesstion];
}

- (void)switchCamera:(UIButton *)sender {
    sender.selected = !sender.selected;
    AVCaptureDevice * device = nil;
    
    if (self.device.position == AVCaptureDevicePositionFront) {
        device = [self cameraWithPosition:AVCaptureDevicePositionBack];
    }else {
        if ([self.device isTorchActive]) {
            self.flashButton.selected = NO;
        }
        
        device = [self cameraWithPosition:AVCaptureDevicePositionFront];
        
    }
    
    if (!device) {
        return;
    }else {
        self.device = device;
    }
    
    NSError * error = nil;
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (!error) {
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.captureDeviceInput];
        if ([self.captureSession canAddInput:input]) {
            [self.captureSession addInput:input];
            self.captureDeviceInput = input;
            [self.captureSession commitConfiguration];
        }
    }
    
    
}

- (BOOL)isFrontCamera {
    if (self.device.position == AVCaptureDevicePositionFront) {
        return YES;
    }else{
        return NO;
    }
}


- (void)switchFlash:(UIButton *)sender {
    
//    //拍照时闪光灯才会闪烁.
//    sender.selected = !sender.selected;
//    if ([self.device isFlashActive]) {
//        [self setFlashMode:AVCaptureFlashModeOff];
//    }else {
//        [self setFlashMode:AVCaptureFlashModeOn];
//    }
    
    if (self.isFrontCamera == YES) {
        alertShow(@"前置摄像头不支持闪光灯");
        
        return;
    }
    
    
    
    //这种用在摄像的时候,闪光灯常亮
    sender.selected = !sender.selected;
    
    if ([self.device isTorchActive]) {
        [self setTorchMode:AVCaptureTorchModeOff];
    }else{
        [self setTorchMode:AVCaptureTorchModeOn];
    }
    
}

- (void)setTorchMode:(AVCaptureTorchMode)mode {
    if ([self.device isTorchModeSupported:mode]) {
        NSError * error = nil;
        if ([self.device  lockForConfiguration:&error]) {
            [self.device setTorchMode:mode];
            [self.device unlockForConfiguration];
        }else{
            NSLog(@"%@",error);
        }
    }
}


//- (void)setFlashMode:(AVCaptureFlashMode)mode {
//    if ([self.device isFlashModeSupported:mode]) {
//        NSError * error = nil;
//        if ([self.device lockForConfiguration:&error]) {
//            [self.device setFlashMode:mode];
//            [self.device unlockForConfiguration];
//        }else{
//            NSLog(@"%@",error);
//        }
//    }
//}

- (void)startSession {
    if (![self.captureSession isRunning]) {
        [self.captureSession startRunning];
    }
}

- (void)stopSesstion {
    if ([self.captureSession isRunning]) {
        [self.captureSession stopRunning];
    }
}


//根据位置返回摄像头.
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return  device;
        }
    }
    
    return nil;
}

- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (void)takePhoto:(id)sender {
    [self captureStillImage];
}

- (void)captureStillImage {
    AVCaptureConnection * videoConnection = [self.captureStillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    
//    videoConnection.videoOrientation = self.captureVideoPreviewLayer.connection.videoOrientation;
    
    
//    AVCaptureConnection *videoConnection = nil;
//    for (AVCaptureConnection *connection in self.captureStillImageOutput.connections) {
//        for (AVCaptureInputPort *port in [connection inputPorts]) {
//            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
//                videoConnection = connection;
//                break;
//            }
//        }
//        if (videoConnection) { break; }
//    }
    if (!videoConnection) {
        NSLog(@"take photo failed");
        return;
    }
    
    [self.captureStillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (!imageDataSampleBuffer) {
            return ;
        }
        if (error) {
            NSLog(@"%@",error);
            return;
        }
        
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage * image = [UIImage imageWithData:imageData];
        
        UIImage * smallImage = [self scaleImage:image toScale:0.5];
        
        UIImageWriteToSavedPhotosAlbum(smallImage, nil, nil, nil);
        
    }];
    
}


- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize{
    
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
    
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    
    UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;
    
}


//- (void)viewDidLoad {
//    [super viewDidLoad];
//    // Do any additional setup after loading the view, typically from a nib.
//    
//    
//    //1 建立Session
//    self.captureSession = [[AVCaptureSession alloc] init];
//    
//    [_captureSession startRunning];
//    
//    
//    //会话的预先调整
//    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
//        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
//    }
//    
//    /*//重新调整session
//     [_captureSession beginConfiguration];
//     //1 移除现存的capture device
//     //2 添加新的capture device
//     //3 重置preset
//     [_captureSession commitConfiguration];
//     */
//    
//    
//    
//    //2 添加input
//    
//        //2.1 配置device (查找前后摄像头)
//    
//    /*
//    NSArray * devices = [AVCaptureDevice devices];
//    for (AVCaptureDevice * device in devices) {
//        NSLog(@"Device Nmae : %@",device.localizedName);
//        if ([device hasMediaType:AVMediaTypeVideo]) {
//            if (device.position == AVCaptureDevicePositionBack) {
//                NSLog(@"Devcie position : back");
//            } else {
//                NSLog(@"Devcie position : front");
//            }
//        }
//    }
//     */
//    
//        //2.2 设备的前后切换
//        /*
//            [_captureSession beginConfiguration];
//            [_captureSession removeInput:frontFacingCameraDeviceInput];
//            [_captureSession addInput:backFacingCameraDeviceInput];
//            [_captureSession commitConfiguration];
//         */
//    
//    NSError * error;
//    
//    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    
//    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
//    
//    if (!input) {
//        //Handle the error
//    }
//    
//    if ([_captureSession canAddInput:input]) {
//        [_captureSession addInput:input];
//    }else{
//        //handle the failure
//    }
//    
//    
//    
//    //3 添加outPut
//    
//        //输出设备到session的类型
//            /*
//             AVCaptureMovieFileOutput   视频文件
//             AVCaptureVideoDataOutput   视频采集数据
//             AVCaptureAudioDataOutput   音频
//             AVCaptureStillImageOutput   图片
//             */
//    AVCaptureStillImageOutput * output = [[AVCaptureStillImageOutput alloc] init];
//    NSDictionary * outputSetting = @{AVVideoCodecKey:AVVideoCodecJPEG};
//    [_captureStillImageOutput setOutputSettings:outputSetting];
//    
//    if ([_captureSession canAddOutput:output]) {
//        [_captureSession addOutput:output];
//    }
//    
//    
//    
//    //4 开始捕捉
//    
//        //捕捉图片
//    AVCaptureConnection * videoConnection = nil;
//    
//    for (AVCaptureConnection * connection in _captureStillImageOutput.connections) {
//        for (AVCaptureInputPort * port in [connection inputPorts]) {
//            if ([port.mediaType isEqual:AVMediaTypeVideo]) {
//                videoConnection = connection;
//                break;
//            }
//        }
//        
//        if (videoConnection) {
//            break;
//        }
//    }
//    
//    [_captureStillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
//        
//        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
//        UIImage * image = [UIImage imageWithData:imageData];
//        
////        NSString * tempDir = NSTemporaryDirectory();
////        NSString * tempFile = [NSString stringWithFormat:@"%@/TempHB.png",tempDir];
////        
////        [UIImagePNGRepresentation(image) writeToFile:tempFile atomically:YES];
//        
//        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
//    }];
//    
//    
//    
//    //5 为用户显示当前录制状态
//    
//    //6 捕捉
//    
//    //7 结束捕捉
//    
//    //8 参考
//    
//    
//    
//    //设置预览图层,通过会话
//    _captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
//    
//    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    _captureVideoPreviewLayer.frame = self.view.layer.bounds;
//    
//    [self.view.layer insertSublayer:_captureVideoPreviewLayer atIndex:0];
//    
//    
//    
////    NSArray * devices = [AVCaptureDevice devices];
////    
////    for (AVCaptureDevice * device in devices) {
////        NSLog(@"%@",device.localizedName);
////        if ([device hasMediaType:AVMediaTypeVideo]) {
////            if (device.position == AVCaptureDevicePositionBack) {
////                NSLog(@"Device position: back");
////            } else if(device.position == AVCaptureDevicePositionFront){
////                NSLog(@"Device position: front");
////            } else{
////                NSLog(@"Device position: Unspecified");
////            }
////        }
////        
////    }
//    
//    
//    
//    
//}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
