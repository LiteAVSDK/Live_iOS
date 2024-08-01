//
//  TimeShiftViewController.m
//  MLVB-API-Example-OC
//
//  Created by leiran on 2022/11/4.
//  Copyright © 2022 Tencent. All rights reserved.
//

/*
 time shift function
 MLVB APP time-shift code example:
 This document shows how to implement the time shift function through the mobile live broadcast SDK
 1. First, understand the basic concepts and uses of time shifting on the official website, and enable the time shifting function. https://cloud.tencent.com/document/product/267/32742
 2. Splice the time-shifted playback link according to the document rules NSString *timeShiftUrl = http://[Domain]/timeshift/[AppName]/[StreamName]/timeshift.m3u8?delay=90. (delay, default minimum 90 seconds)
 3. Stop the currently playing live streaming API: [_livePlayer stopPlay];
 4. Start playing time-shift streaming API: [self.livePlayer startLivePlay:timeShiftUrl];

 Resume live stream
 1. Stop the currently playing time-shifted stream API: [_livePlayer stopPlay];
 2. Start playing live streaming API: [self.livePlayer startLivePlay:liveUrl];
 
 */

#import "TimeShiftViewController.h"
#import "TimeShiftHelper.h"

/// Time shift function demonstration, sample streaming address。
static NSString * const G_DEFAULT_URL = @"http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid.flv";
static NSString * const G_DEFAULT_TIME_SHIFT_DOMAIN = @"liteavapp.timeshift.qcloud.com";

// Configurable time shift interval https://cloud.tencent.com/document/product/267/32742
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
        // Whether to clean the last frame when stopping streaming
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

// Return to live broadcast
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
