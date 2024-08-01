//
//  LivePushScreenViewController.m
//  MLVB-API-Example-OC
//
//  Created by bluedang on 2021/6/28.
//  Copyright © 2021 Tencent. All rights reserved.
//

/*
 Publishing from Screen
  Publishing from Screen in MLVB App
  This document shows how to integrate the feature of publishing from the screen.
  1. Turn speaker on: [self.livePusher startMicrophone]
  2. Capture streams from the screen: [self.livePusher startScreenCapture:@"group.com.tencent.liteav.RPLiveStreamShare"]
  3. Start publishing: [self.livePusher startPush:url]
  Documentation: https://cloud.tencent.com/document/product/454/56591
  RTC Push Currently only supported in China, other regions are continuing to develop.
 */


#import "LivePushScreenViewController.h"
#import "TRTCBroadcastExtensionLauncher.h"

@interface LivePushScreenViewController () <V2TXLivePusherObserver>
@property (weak, nonatomic) IBOutlet UIButton *startButton;

@property (strong, nonatomic) V2TXLivePusher *livePusher;
@property (strong, nonatomic) NSString *streamId;
@property (assign, nonatomic) V2TXLiveMode liveMode;
@property (assign, nonatomic) V2TXLiveAudioQuality audioQulity;
@end

@implementation LivePushScreenViewController

- (instancetype)initWithStreamId:(NSString*)streamId isRTCPush:(BOOL)value audioQulity:(V2TXLiveAudioQuality)quality {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];

    self.streamId = streamId;
    self.audioQulity = quality;
    self.liveMode = value ? V2TXLiveMode_RTC : V2TXLiveMode_RTMP;
    self.livePusher = [[V2TXLivePusher alloc] initWithLiveMode:self.liveMode];
    [self.livePusher setObserver:self];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDefalutUIConfig];
}

- (void)setupDefalutUIConfig {
    self.title = self.streamId;
    
    [self.startButton setBackgroundColor:[UIColor themeBlueColor]];
    [self.startButton setTitle:localize(@"MLVB-API-Example.LivePushScreen.start")
                      forState:UIControlStateNormal];
    [self.startButton setTitle:localize(@"MLVB-API-Example.LivePushScreen.stop")
                      forState:UIControlStateSelected];
    self.startButton.titleLabel.adjustsFontSizeToFitWidth = true;
}

- (void)dealloc {
    [self.livePusher stopScreenCapture];
    [self.livePusher stopMicrophone];
    [self.livePusher stopPush];
}

- (void)startPush {
    if (!self.livePusher) {
        return;
    }
    
    [TRTCBroadcastExtensionLauncher launch];
    
    if (self.livePusher.isPushing) { return; }

    [self.livePusher setAudioQuality:self.audioQulity];
    [self.livePusher startScreenCapture:@"group.com.tencent.liteav.RPLiveStreamShare"];
    [self.livePusher startMicrophone];
    
    NSString *url;
    if (self.liveMode == V2TXLiveMode_RTC) {
        url = [URLUtils generateTRTCPushUrl:self.streamId];
    } else {
        url = [URLUtils generateRtmpPushUrl:self.streamId];
    }

    V2TXLiveCode code = [self.livePusher startPush:url];
    if (code != V2TXLIVE_OK) {
        [self.livePusher stopMicrophone];
        [self.livePusher stopScreenCapture];
    }
}

- (void)stopPush {
    [self.livePusher stopScreenCapture];
    [self.livePusher stopPush];
    self.startButton.selected = false;
}

#pragma mark - Actions

- (IBAction)onStartButtonClick:(UIButton*)sender {
    if (sender.isSelected) {
        [self stopPush];
    } else {
        [self startPush];
    }
}

- (void)onCaptureFirstVideoFrame {
    self.startButton.selected = true;
}


@end
