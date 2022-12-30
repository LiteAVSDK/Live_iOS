//
//  TimeShiftViewController.m
//  MLVB-API-Example-OC
//
//  Created by leiran on 2022/11/4.
//  Copyright © 2022 Tencent. All rights reserved.
//

/*
 时移功能
 MLVB APP 时移代码示例：
 本文件展示如何通过移动直播SDK实现时移功能
 1、首先在官网了解时移基本概念和使用，并开启时移功能。https://cloud.tencent.com/document/product/267/32742
 2、根据文档规则拼接时移的播放链接 NSString *timeShiftUrl = http://[Domain]/timeshift/[AppName]/[StreamName]/timeshift.m3u8?delay=90。(delay ，默认最小90秒)
 3、停止当前正在播放的直播流 API:[_livePlayer stopPlay];
 4、开始播放时移流 API:[self.livePlayer startLivePlay:timeShiftUrl];

 恢复直播流
 1、停止当前正在播放的时移流 API:[_livePlayer stopPlay];
 2、开始播放直播流 API:[self.livePlayer startLivePlay:liveUrl];
 
 */

#import "TimeShiftViewController.h"
#import "TimeShiftHelper.h"

/// 时移功能演示，示例拉流地址。
static NSString * const G_DEFAULT_URL = @"http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid.flv";
static NSString * const G_DEFAULT_TIME_SHIFT_DOMAIN = @"liteavapp.timeshift.qcloud.com";

// 时移区间可配置 https://cloud.tencent.com/document/product/267/32742
static const NSInteger kMaxFallbackSeconds = 600;
static const NSInteger kMinFallbackSeconds = 90;

@interface TimeShiftViewController ()<V2TXLivePlayerObserver> 
@property (nonatomic, strong) V2TXLivePlayer *livePlayer;
@property (nonatomic, strong) TimeShiftHelper *timeShiftHelper;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDateFormatter *outputFormatter;

@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *resumeLiveBtn;

@end

@implementation TimeShiftViewController

- (V2TXLivePlayer *)livePlayer {
    if (!_livePlayer) {
        _livePlayer = [[V2TXLivePlayer alloc] init];
        [_livePlayer setObserver:self];
        // 停止拉流时是否清理最后一帧
        [_livePlayer setProperty:@"clearLastImage" value:@(NO)];
        [_livePlayer setRenderFillMode:V2TXLiveFillModeFit];
        [_livePlayer setRenderView:self.view];
    }
    return _livePlayer;
}

- (TimeShiftHelper *)timeShiftHelper {
    if (!_timeShiftHelper) {
        _timeShiftHelper = [[TimeShiftHelper alloc] initWithDomain:G_DEFAULT_TIME_SHIFT_DOMAIN];
    }
    return _timeShiftHelper;
}

- (NSDateFormatter *)outputFormatter {
    if (!_outputFormatter) {
        _outputFormatter = [[NSDateFormatter alloc] init];
        [_outputFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [_outputFormatter setDateFormat:@"HH:mm:ss"];
    }
    return _outputFormatter;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopTimer];
    [self.livePlayer stopPlay];
    self.livePlayer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = localize(@"MLVB-API-Example.Home.TimeShift");
    self.view.backgroundColor = UIColor.blackColor;
    self.timeLabel.adjustsFontSizeToFitWidth = YES;
    self.timeLabel.textColor = [UIColor whiteColor];
    [self.resumeLiveBtn setTitle:localize(@"MLVB-API-Example.Home.TimeShift.ResumeLive") forState:UIControlStateNormal];
    
    [self.livePlayer startLivePlay:G_DEFAULT_URL];
    
    [self startTimer];
}

- (void)startTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (NSInteger)getCurrentDelay {
    CGFloat delay = 0.0;
    if (self.slider.value < 0.99) {
        delay = kMinFallbackSeconds + (kMaxFallbackSeconds - kMinFallbackSeconds) * (1.0 - self.slider.value);
    }
    return (NSInteger)(delay + 0.5);
}

// 返回直播
- (void)resumeLive {
    NSLog(@"Resmue live");
    self.slider.value = 1.0;
    [self.livePlayer stopPlay];
    [self.livePlayer startLivePlay:G_DEFAULT_URL];
}

- (void)startTimeShift {
    NSString *timeShiftUrl = [self.timeShiftHelper getTimeShiftUrl:G_DEFAULT_URL delay: [self getCurrentDelay]];
    [self.livePlayer stopPlay];
    [self.livePlayer startLivePlay:timeShiftUrl];
    NSLog(@"Start time shift %@", timeShiftUrl);
}

- (void)updateProgress {
    NSInteger delay = [self getCurrentDelay];
    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger timestamps = [zone secondsFromGMTForDate:date];
    NSDate *newDate =  [date dateByAddingTimeInterval:timestamps - delay];
    self.timeLabel.text = [self.outputFormatter stringFromDate:newDate];
}

- (IBAction)sliderTouchUpInSide:(UISlider *)sender {
    if (sender.value > 0.99) {
        [self resumeLive];
    } else {
        [self startTimeShift];
    }
    [self updateProgress];
}

- (IBAction)resumeLiveButtonClick:(id)sender {
    [self resumeLive];
}


@end
