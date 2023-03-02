//
//  PictureInPictureViewController.m
//  MLVB-API-Example-OC
//
//  Created by adams on 2022/6/29.
//  Copyright © 2022 Tencent. All rights reserved.
//

#import "PictureInPictureViewController.h"
#import <AVKit/AVKit.h>

/*
 画中画功能（iOS15及以上支持）
 MLVB APP 画中画功能代码示例：
 本文件展示如何通过移动直播SDK实现iOS系统上的画中画功能
 1、开启自定义渲染 API:[self.livePlayer enableObserveVideoFrame:YES pixelFormat:V2TXLivePixelFormatNV12 bufferType:V2TXLiveBufferTypePixelBuffer];
 2、需要开启SDK的后台解码能力 API:[_livePlayer setProperty:@"enableBackgroundDecoding" value:@(YES)];
 3、使用系统 API创建画中画内容源: AVPictureInPictureControllerContentSource *contentSource = [[AVPictureInPictureControllerContentSource alloc] initWithSampleBufferDisplayLayer:self.sampleBufferDisplayLayer playbackDelegate:self];
 4、使用系统 API创建画中画控制器: [[AVPictureInPictureController alloc] initWithContentSource:contentSource];
 5、在SDK回调:- (void)onRenderVideoFrame:(id<V2TXLivePlayer>)player frame:(V2TXLiveVideoFrame *)videoFrame内将pixelBuffer转为SampleBuffer并交给AVSampleBufferDisplayLayer进行渲染;
 6、使用系统 API开启画中画功能：[self.pipViewController startPictureInPicture];
 */

/*
 Picture-in-picture Example (supported by iOS15 and above)
 MLVB APP picture-in-picture function code example:
 This document shows how to implement the picture-in-picture function on the iOS system through the Mobile Live SDK
 1. Enable custom rendering API: [self.livePlayer enableObserveVideoFrame:YES pixelFormat:V2TXLivePixelFormatNV12 bufferType:V2TXLiveBufferTypePixelBuffer];
 2. The background decoding capability of the SDK needs to be enabled API:[_livePlayer setProperty:@"enableBackgroundDecoding" value:@(YES)];
 3. Use the system API to create a PIP content source: AVPictureInPictureControllerContentSource *contentSource = [[AVPictureInPictureControllerContentSource alloc] initWithSampleBufferDisplayLayer:self.sampleBufferDisplayLayer playbackDelegate:self];
 4. Use the system API to create a picture-in-picture controller: [[AVPictureInPictureController alloc] initWithContentSource:contentSource];
 5. In SDK callback:- (void)onRenderVideoFrame:(id<V2TXLivePlayer>)player frame:(V2TXLiveVideoFrame *)videoFrame convert pixelBuffer to SampleBuffer and hand it over to AVSampleBufferDisplayLayer for rendering;
 6. Use the system API to enable the picture-in-picture function: [self.pipViewController startPictureInPicture];
 */

static NSString * const G_DEFAULT_URL = @"http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid.flv";

@interface PictureInPictureViewController ()<
V2TXLivePlayerObserver,
AVPictureInPictureControllerDelegate,
AVPictureInPictureSampleBufferPlaybackDelegate>

@property (nonatomic, strong) V2TXLivePlayer *livePlayer;
@property (nonatomic, strong) AVPictureInPictureController *pipViewController;
@property (nonatomic, strong) AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;
@property (weak, nonatomic) IBOutlet UIButton *pictureInPictureButton;
@property (nonatomic, strong) UIView *playView;
@end

@implementation PictureInPictureViewController

- (V2TXLivePlayer *)livePlayer {
    if (!_livePlayer) {
        _livePlayer = [[V2TXLivePlayer alloc] init];
        [_livePlayer enableObserveVideoFrame:YES pixelFormat:V2TXLivePixelFormatNV12 bufferType:V2TXLiveBufferTypePixelBuffer];
        [_livePlayer setObserver:self];
        [_livePlayer setProperty:@"enableBackgroundDecoding" value:@(YES)];
    }
    return _livePlayer;
}

- (UIView *)playView {
    if (!_playView) {
        _playView = [[UIView alloc] initWithFrame:CGRectZero];
        _playView.backgroundColor = UIColor.redColor;
    }
    return _playView;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.pipViewController = nil;
    [self.sampleBufferDisplayLayer removeFromSuperlayer];
    [self.livePlayer stopPlay];
    self.livePlayer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    
    self.playView.frame = UIApplication.sharedApplication.keyWindow.bounds;
    [self.view insertSubview:self.playView belowSubview:self.pictureInPictureButton];
    
    self.pictureInPictureButton.layer.cornerRadius = 8;
    [self.pictureInPictureButton setTitle:localize(@"MLVB-API-Example.Home.OpenPictureInPicture") forState:UIControlStateNormal];
    
    [self.livePlayer setRenderView:self.playView];
    [self.livePlayer setRenderFillMode:V2TXLiveFillModeFit];
    [self.livePlayer startLivePlay:G_DEFAULT_URL];
    
    if (@available(iOS 15.0, *)) {
        if ([AVPictureInPictureController isPictureInPictureSupported]) {
            NSError *error = nil;
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
            if (error) {
                NSLog(@"%@%@",localize(@"MLVB-API-Example.Home.PermissionFailed"),error);
            }
            [self setupSampleBufferDisplayLayer];
            [self.view.layer addSublayer:self.sampleBufferDisplayLayer];
            AVPictureInPictureControllerContentSource *contentSource = [[AVPictureInPictureControllerContentSource alloc]
                                                                        initWithSampleBufferDisplayLayer:self.sampleBufferDisplayLayer
                                                                        playbackDelegate:self];
            self.pipViewController = [[AVPictureInPictureController alloc] initWithContentSource:contentSource];
            self.pipViewController.delegate = self;
            self.pipViewController.canStartPictureInPictureAutomaticallyFromInline = YES;
        } else {
            NSLog(@"%@",localize(@"MLVB-API-Example.Home.NotSupported"));
        }
    }
}

- (IBAction)onPictureInPictureButtonClick:(id)sender {
    if (self.pipViewController.isPictureInPictureActive) {
        [self.pipViewController stopPictureInPicture];
    } else {
        [self.pipViewController startPictureInPicture];
    }
}

- (void)dispatchPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer) {
        return;
    }
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    NSParameterAssert(result == 0 && videoInfo != NULL);
    
    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);
    NSParameterAssert(result == 0 && sampleBuffer != NULL);
    CFRelease(videoInfo);
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    [self enqueueSampleBuffer:sampleBuffer toLayer:self.sampleBufferDisplayLayer];
    CFRelease(sampleBuffer);
}

- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer toLayer:(AVSampleBufferDisplayLayer*)layer {
    if (sampleBuffer) {
        CFRetain(sampleBuffer);
        [layer enqueueSampleBuffer:sampleBuffer];
        CFRelease(sampleBuffer);
        if (layer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            NSLog(@"%@%@",localize(@"MLVB-API-Example.Home.Errormessage"),layer.error);
            [layer flush];
            if (-11847 == layer.error.code) {
                [self rebuildSampleBufferDisplayLayer];
            }
        }
    } else {
        NSLog(@"%@",localize(@"MLVB-API-Example.Home.Ignorenullsamplebuffer"));
    }
}

- (void)rebuildSampleBufferDisplayLayer {
    @synchronized(self) {
        [self teardownSampleBufferDisplayLayer];
        [self setupSampleBufferDisplayLayer];
    }
}
  
- (void)teardownSampleBufferDisplayLayer {
    if (self.sampleBufferDisplayLayer) {
        [self.sampleBufferDisplayLayer stopRequestingMediaData];
        [self.sampleBufferDisplayLayer removeFromSuperlayer];
        self.sampleBufferDisplayLayer = nil;
    }
}
  
- (void)setupSampleBufferDisplayLayer {
    if (!self.sampleBufferDisplayLayer) {
        self.sampleBufferDisplayLayer = [[AVSampleBufferDisplayLayer alloc] init];
        self.sampleBufferDisplayLayer.frame = self.playView.bounds;
        self.sampleBufferDisplayLayer.position = CGPointMake(CGRectGetMidX(self.sampleBufferDisplayLayer.bounds),
                                                             CGRectGetMidY(self.sampleBufferDisplayLayer.bounds));
        self.sampleBufferDisplayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.sampleBufferDisplayLayer.opaque = YES;
        self.sampleBufferDisplayLayer.opacity = 0;
        [self.view.layer addSublayer:self.sampleBufferDisplayLayer];
    }
}

#pragma mark - V2TXLivePlayerObserver
- (void)onRenderVideoFrame:(id<V2TXLivePlayer>)player frame:(V2TXLiveVideoFrame *)videoFrame {
    if (videoFrame.bufferType != V2TXLiveBufferTypeTexture && videoFrame.pixelFormat != V2TXLivePixelFormatTexture2D) {
        [self dispatchPixelBuffer:videoFrame.pixelBuffer];
    }
}

#pragma mark - AVPictureInPictureControllerDelegate
- (void)pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"pictureInPictureControllerWillStartPictureInPicture");
    self.playView.alpha = 0;
}

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    [self.pictureInPictureButton setTitle:localize(@"MLVB-API-Example.Home.ClosePictureInPicture") forState:UIControlStateNormal];
    NSLog(@"pictureInPictureControllerDidStartPictureInPicture");
    self.sampleBufferDisplayLayer.opacity = 1;
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController
failedToStartPictureInPictureWithError:(NSError *)error {
    NSLog(@"failedToStartPictureInPictureWithError");
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController
restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler {
    NSLog(@"restoreUserInterfaceForPictureInPictureStopWithCompletionHandler");
    completionHandler(true);
}

- (void)pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"pictureInPictureControllerWillStopPictureInPicture");
    self.sampleBufferDisplayLayer.opacity = 0;
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    [self.pictureInPictureButton setTitle:localize(@"MLVB-API-Example.Home.OpenPictureInPicture") forState:UIControlStateNormal];
    NSLog(@"pictureInPictureControllerDidStopPictureInPicture");
    self.playView.alpha = 1;
}


#pragma mark - AVPictureInPictureSampleBufferPlaybackDelegate
- (BOOL)pictureInPictureControllerIsPlaybackPaused:(nonnull AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"pictureInPictureControllerIsPlaybackPaused");
    return NO;
}

- (CMTimeRange)pictureInPictureControllerTimeRangeForPlayback:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"pictureInPictureControllerTimeRangeForPlayback");
    return  CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity); // for live streaming
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController
         didTransitionToRenderSize:(CMVideoDimensions)newRenderSize {
    NSLog(@"didTransitionToRenderSize");
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController setPlaying:(BOOL)playing {
    NSLog(@"setPlaying");
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController
                    skipByInterval:(CMTime)skipInterval
                 completionHandler:(void (^)(void))completionHandler {
    NSLog(@"skipByInterval");
}

@end
