//
//  RTCPushAndPlayAnchorViewController.m
//  MLVB-API-Example-OC
//
//  Created by bluedang on 2021/6/30.
//  Copyright © 2021 Tencent. All rights reserved.
//

/*
 RTC Co-anchoring + Ultra-low-latency Playback View for Anchors
 RTC Co-anchoring + Ultra-low-latency Playback View for Anchors in the MLVB App
 This document shows how to integrate the RTC co-anchoring + ultra-low-latency playback feature.
 1. Turn speaker on: [self.livePusher startMicrophone]
 2. Turn camera on: [self.livePusher startCamera:true]
 3. Start publishing: [self.livePusher startPush:url]
 4. Play the co-anchoring audience’s stream: [self.livePlayer startLivePlay:url]
 Currently only supported in China, other regions are continuing to develop.
 */

#import "RTCPushAndPlayAnchorViewController.h"

@interface RTCPushAndPlayAnchorViewController ()
@property (weak, nonatomic) IBOutlet UILabel *streamIdLabel;
@property (weak, nonatomic) IBOutlet UITextField *streamIdTextField;
@property (weak, nonatomic) IBOutlet UIButton *acceptLinkButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *remoteView;

@property (strong, nonatomic) NSString* streamId;

@property (strong, nonatomic) V2TXLivePusher *livePusher;
@property (strong, nonatomic) V2TXLivePlayer *livePlayer;

@end

@implementation RTCPushAndPlayAnchorViewController

- (instancetype)initWithStreamId:(NSString*)streamId {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    self.streamId = streamId;
    return self;
}

- (V2TXLivePlayer *)livePlayer {
    if (!_livePlayer) {
        _livePlayer = [[V2TXLivePlayer alloc] init];
    }
    return _livePlayer;
}

- (V2TXLivePusher *)livePusher {
    if (!_livePusher) {
        _livePusher = [[V2TXLivePusher alloc] initWithLiveMode:V2TXLiveMode_RTC];
    }
    return _livePusher;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDefaultUIConfig];
    [self addKeyboardObserver];
    
    [self startPush];
}

- (void)setupDefaultUIConfig {
    self.title = self.streamId;
    self.streamIdLabel.text = localize(@"MLVB-API-Example.RTCPushAndPlay.streamIdInput");
    self.streamIdLabel.adjustsFontSizeToFitWidth = true;
    
    self.acceptLinkButton.backgroundColor = [UIColor themeBlueColor];
    [self.acceptLinkButton setTitle:localize(@"MLVB-API-Example.RTCPushAndPlay.startLink") forState:UIControlStateNormal];
    [self.acceptLinkButton setTitle:localize(@"MLVB-API-Example.RTCPushAndPlay.stopLink") forState:UIControlStateSelected];
    self.acceptLinkButton.titleLabel.adjustsFontSizeToFitWidth = true;

}

- (void)dealloc {
    [self removeKeyboardObserver];
}

- (void)startPush {
    [self.livePusher startCamera:true];
    [self.livePusher startMicrophone];
    [self.livePusher setRenderView:self.view];

    NSString *url = [URLUtils generateTRTCPushUrl:self.streamId];
    V2TXLiveCode code = [self.livePusher startPush:url];
    if (code != V2TXLIVE_OK) {
        [self.livePusher stopMicrophone];
        [self.livePusher stopCamera];
    }
}

- (void)stopPush {
    [self.livePusher stopMicrophone];
    [self.livePusher stopCamera];
    [self.livePusher stopPush];
}

- (void)startPlay:(NSString*)streamId {
    NSString *url = [URLUtils generateTRTCPlayUrl:streamId];
    
    [self.livePlayer setRenderView:self.remoteView];
    [self.livePlayer startLivePlay:url];
}

- (void)stopPlay {
    [self.livePlayer stopPlay];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:true];
}

#pragma mark - Actions

- (IBAction)acceptLinkButtonClick:(UIButton*)sender {
    sender.selected = !sender.isSelected;
    if (sender.selected) {
        [self startPlay:self.streamIdTextField.text];
    } else {
        [self stopPlay];
    }
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
