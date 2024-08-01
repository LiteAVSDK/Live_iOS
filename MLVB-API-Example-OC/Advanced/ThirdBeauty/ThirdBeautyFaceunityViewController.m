//
//  ThirdBeautyViewController.m
//  MLVB-API-Example-OC
//
//  Created by adams on 2021/4/22.
//  Copyright © 2021 Tencent. All rights reserved.
//

/*
 Third-Party Beauty Filter Example
 The MLVB app supports third-party beauty filters.
 This document shows how to integrate third-party beauty filters.
 1. Turn speaker on: [self.livePusher startMicrophone]
 2. Turn camera on: [self.livePusher startCamera:true]
 3. Start publishing: [self.livePusher startPush:url]
 4. Enable custom video processing: [self.livePusher enableCustomVideoProcess:true pixelFormat:V2TXLivePixelFormatNV12 bufferType:V2TXLiveBufferTypePixelBuffer]
 5. Use a third-party beauty filter SDK (FaceUnity is used in the demo): [[FUManager shareManager] renderItemsToPixelBuffer:srcFrame.pixelBuffer]

 Documentation: https://cloud.tencent.com/document/product/647/34066
 Third-party beauty filter: https://github.com/Faceunity/FUTRTCDemo
 */

#import "ThirdBeautyFaceunityViewController.h"
//#import "FUManager.h"

@interface ThirdBeautyFaceunityViewController () <V2TXLivePusherObserver>
@property (weak, nonatomic) IBOutlet UILabel *setBeautyLabel;
@property (weak, nonatomic) IBOutlet UILabel *beautyNumLabel;
@property (weak, nonatomic) IBOutlet UISlider *setBeautySlider;

@property (weak, nonatomic) IBOutlet UILabel *streamIdLabel;
@property (weak, nonatomic) IBOutlet UITextField *streamIdTextField;

@property (weak, nonatomic) IBOutlet UIButton *startPushStreamButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@property (strong, nonatomic) V2TXLivePusher *livePusher;
//@property (strong, nonatomic) FUBeautyParam *beautyParam;

@end

@implementation ThirdBeautyFaceunityViewController

//- (FUBeautyParam *)beautyParam {
//    if (!_beautyParam) {
//        _beautyParam = [[FUBeautyParam alloc] init];
//        _beautyParam.type = FUDataTypeBeautify;
//        _beautyParam.mParam = @"blur_level";
//    }
//    return _beautyParam;
//}

- (V2TXLivePusher *)livePusher {
    if (!_livePusher) {
        _livePusher = [[V2TXLivePusher alloc] initWithLiveMode:V2TXLiveMode_RTMP];
        [_livePusher setObserver:self];
    }
    return _livePusher;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDefaultUIConfig];
    [self addKeyboardObserver];
}

- (void)viewDidAppear:(BOOL)animated {
    [self setupBeautySDK];
}

- (void)setupDefaultUIConfig {
    self.streamIdTextField.text = [NSString generateRandomStreamId];
    
    self.streamIdLabel.text = localize(@"MLVB-API-Example.ThirdBeauty.streamIdInput");
    self.streamIdLabel.adjustsFontSizeToFitWidth = true;
    
    self.startPushStreamButton.backgroundColor = [UIColor themeBlueColor];
    [self.startPushStreamButton setTitle:localize(@"MLVB-API-Example.ThirdBeauty.startPush") forState:UIControlStateNormal];
    [self.startPushStreamButton setTitle:localize(@"MLVB-API-Example.ThirdBeauty.stopPush") forState:UIControlStateSelected];

    self.setBeautyLabel.text = localize(@"MLVB-API-Example.ThirdBeauty.beautyLevel");
    NSInteger value = self.setBeautySlider.value * 6;
    self.beautyNumLabel.text = [NSString stringWithFormat:@"%ld",value];
}

- (void)setupBeautySDK {
//    [[FUManager shareManager] loadFilter];
//    [FUManager shareManager].isRender = YES;
//    [FUManager shareManager].flipx = YES;
//    [FUManager shareManager].trackFlipx = YES;
}

- (void)startPush:(NSString*)streamId {
    self.title = streamId;
    [self.livePusher setRenderView:self.view];
    [self.livePusher startCamera:true];
    [self.livePusher startMicrophone];
    
    [self.livePusher enableCustomVideoProcess:true pixelFormat:V2TXLivePixelFormatNV12 bufferType:V2TXLiveBufferTypePixelBuffer];
    
    [self.livePusher startPush:[URLUtils generateRtmpPushUrl:streamId]];
}

- (void)stopPush {
    [self.livePusher stopCamera];
    [self.livePusher stopMicrophone];
    [self.livePusher stopPush];
}

#pragma mark - IBActions
- (IBAction)onPushStreamClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self startPush:self.streamIdTextField.text];
    } else {
        [self stopPush];
    }
}

#pragma mark - Slider ValueChange
- (IBAction)setBeautySliderValueChange:(UISlider *)sender {
//    self.beautyParam.mValue = sender.value;
//    [[FUManager shareManager] filterValueChange:self.beautyParam];
    NSInteger value = sender.value * 6;
    self.beautyNumLabel.text = [NSString stringWithFormat:@"%ld",value];
}

#pragma mark - V2TXLivePusherObserver
- (void)onProcessVideoFrame:(V2TXLiveVideoFrame *)srcFrame dstFrame:(V2TXLiveVideoFrame *)dstFrame {
//    [[FUManager shareManager] renderItemsToPixelBuffer:srcFrame.pixelBuffer];
    dstFrame.bufferType = V2TXLiveBufferTypePixelBuffer;
    dstFrame.pixelFormat = V2TXLivePixelFormatNV12;
    dstFrame.pixelBuffer = srcFrame.pixelBuffer;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:true];
}

- (void)dealloc {
//    [[FUManager shareManager] destoryItems];
    [self removeKeyboardObserver];
}

#pragma mark - Notification
- (void)addKeyboardObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeKeyboardObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)keyboardWillShow:(NSNotification *)noti {
    CGFloat animationDuration = [[[noti userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardBounds = [[[noti userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [UIView animateWithDuration:animationDuration animations:^{
        self.bottomConstraint.constant = keyboardBounds.size.height;
    }];
    return YES;
}

- (BOOL)keyboardWillHide:(NSNotification *)noti {
     CGFloat animationDuration = [[[noti userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
     [UIView animateWithDuration:animationDuration animations:^{
         self.bottomConstraint.constant = 25;
     }];
     return YES;
}


@end
