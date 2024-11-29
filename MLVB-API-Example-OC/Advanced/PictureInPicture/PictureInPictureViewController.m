//
//  PictureInPictureViewController.m
//  MLVB-API-Example-OC
//
//  Created by adams on 2022/6/29.
//  Copyright © 2022 Tencent. All rights reserved.
//

#import "PictureInPictureViewController.h"
#import <AVKit/AVKit.h>
#import "PictureInPictureView.h"

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
@property (nonatomic, strong) AVSampleBufferDisplayLayer *displayLayer;
@property (nonatomic, strong) PictureInPictureView *displayView;
@property (nonatomic, weak) IBOutlet UIButton *pictureInPictureButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (nonatomic, assign) BOOL videoMuted;
@property (nonatomic, assign) BOOL playbackPaused;
@end

@implementation PictureInPictureViewController

#pragma mark - lazy load
- (V2TXLivePlayer *)livePlayer {
    if (!_livePlayer) {
        _livePlayer = [[V2TXLivePlayer alloc] init];
        [_livePlayer enableObserveVideoFrame:YES pixelFormat:V2TXLivePixelFormatNV12 bufferType:V2TXLiveBufferTypePixelBuffer];
        [_livePlayer setObserver:self];
        [_livePlayer setProperty:@"enableBackgroundDecoding" value:@(YES)];
    }
    return _livePlayer;
}

- (void)setupDisplayView {
    self.displayView = [[PictureInPictureView alloc] initWithFrame:UIApplication.sharedApplication.keyWindow.bounds];
    self.displayView.userInteractionEnabled = NO;
    self.displayLayer = (AVSampleBufferDisplayLayer *)self.displayView.layer;
    self.displayLayer.opaque = YES;
    self.displayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view insertSubview:self.displayView belowSubview:self.pictureInPictureButton];
}

- (void)resetDisplayView {
    [self.displayView removeFromSuperview];
    [self.displayLayer stopRequestingMediaData];
    self.displayView = nil;
}

- (void)setupPipController {
    if (@available(iOS 15.0, *)) {
        if ([AVPictureInPictureController isPictureInPictureSupported]) {
            NSError *error = nil;
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
            if (error) {
                NSLog(@"%@%@",localize(@"MLVB-API-Example.Home.PermissionFailed"),error);
            }
            AVPictureInPictureControllerContentSource *contentSource = [[AVPictureInPictureControllerContentSource alloc]
                                                                        initWithSampleBufferDisplayLayer:self.displayLayer
                                                                        playbackDelegate:self];
            self.pipViewController = [[AVPictureInPictureController alloc] initWithContentSource:contentSource];
            self.pipViewController.delegate = self;
            self.pipViewController.canStartPictureInPictureAutomaticallyFromInline = YES;
            self.pipViewController.requiresLinearPlayback = YES;
            // Set whether there are fast forward and rewind buttons in the small picture-in-picture window
        } else {
            NSLog(@"%@",localize(@"MLVB-API-Example.Home.NotSupported"));
        }
    }
}

- (void)resetPipController {
    if (@available(iOS 15.0, *)) {
        [self.pipViewController stopPictureInPicture];
        [self.pipViewController invalidatePlaybackState];
        self.pipViewController = nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self resetPipController];
    [self resetDisplayView];
    [self.livePlayer stopPlay];
    self.livePlayer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.pictureInPictureButton.layer.cornerRadius = 8;
    [self.pictureInPictureButton setTitle:localize(@"MLVB-API-Example.Home.OpenPictureInPicture") forState:UIControlStateNormal];
    [self.pauseButton setTitle:localize(@"MLVB-API-Example.Home.pause") forState:UIControlStateNormal];
    
    [self.livePlayer setRenderFillMode:V2TXLiveFillModeFit];
    [self.livePlayer startLivePlay:G_DEFAULT_URL];
    self.videoMuted = NO;
    self.playbackPaused = NO;
    [self setupDisplayView];
    [self setupPipController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (IBAction)onPictureInPictureButtonClick:(id)sender {
    if (self.pipViewController.isPictureInPictureActive) {
        [self.pipViewController stopPictureInPicture];
    } else {
        [self.pipViewController startPictureInPicture];
    }
}

- (IBAction)pauseButtonClick:(id)sender {
    if (self.videoMuted) {
        [self.livePlayer resumeVideo];
        [self.livePlayer resumeAudio];
        self.videoMuted = NO;
        [self.pauseButton setTitle:localize(@"MLVB-API-Example.Home.pause") forState:UIControlStateNormal];
    } else {
        [self.livePlayer pauseVideo];
        [self.livePlayer pauseAudio];
        self.videoMuted = YES;
        [self.pauseButton setTitle:localize(@"MLVB-API-Example.Home.resume") forState:UIControlStateNormal];
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
    [self enqueueSampleBuffer:sampleBuffer toLayer:self.displayLayer];
    CFRelease(sampleBuffer);
}

- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer toLayer:(AVSampleBufferDisplayLayer*)layer {
    if (!sampleBuffer || !layer.readyForMoreMediaData) {
        NSLog(@"%@",localize(@"MLVB-API-Example.Home.Ignorenullsamplebuffer"));
        return;
    }
    if (@available(iOS 16.0, *)) {
        if (layer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            NSLog(@"%@%@",localize(@"MLVB-API-Example.Home.Errormessage"),layer.error);
            [layer flush];
        }
    } else {
        // Memory overflow occurs in oss running iOS16 or later, and you must forcibly flush the memory
        [layer flush];
    }
    [layer enqueueSampleBuffer:sampleBuffer];
}

- (void)refreshPlaybackState {
    if (@available(iOS 15.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"refreshPlaybackState");
            [self.pipViewController invalidatePlaybackState];
        });
    }
}

- (void)muteVideo:(BOOL)mute {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.videoMuted = mute;
        [self refreshPlaybackState];
    });
}

#pragma mark - AppState Event
- (void)onAppBecomeActive:(id)sender {
    if (@available(iOS 15.0, *)) {
        if (!self.pipViewController) {
            return;
        }
        self.playbackPaused = NO;
        [self.pipViewController stopPictureInPicture];
        [self.pipViewController invalidatePlaybackState];
        NSLog(@"onAppBecomeActive");
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
    self.playbackPaused = NO;
}

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    [self.pictureInPictureButton setTitle:localize(@"MLVB-API-Example.Home.ClosePictureInPicture") forState:UIControlStateNormal];
    NSLog(@"pictureInPictureControllerDidStartPictureInPicture");
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
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    [self.pictureInPictureButton setTitle:localize(@"MLVB-API-Example.Home.OpenPictureInPicture") forState:UIControlStateNormal];
    NSLog(@"pictureInPictureControllerDidStopPictureInPicture");
}


#pragma mark - AVPictureInPictureSampleBufferPlaybackDelegate
- (BOOL)pictureInPictureControllerIsPlaybackPaused:(nonnull AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"pictureInPictureControllerIsPlaybackPaused");
    if (self.videoMuted || self.playbackPaused) {
        return YES;
    }
    return NO;
}

- (CMTimeRange)pictureInPictureControllerTimeRangeForPlayback:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"pictureInPictureControllerTimeRangeForPlayback");
    // Fix CPU spikes
    return CMTimeRangeMake(kCMTimeZero, CMTimeMake(315360000000LL, 1000));
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController
         didTransitionToRenderSize:(CMVideoDimensions)newRenderSize {
    NSLog(@"didTransitionToRenderSize");
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController setPlaying:(BOOL)playing {
    NSLog(@"setPlaying");
    if (playing) {
        [self.livePlayer resumeAudio];
        [self.livePlayer resumeVideo];
        [self.pauseButton setTitle:localize(@"MLVB-API-Example.Home.pause") forState:UIControlStateNormal];
    } else {
        [self.livePlayer pauseAudio];
        [self.livePlayer pauseVideo];
        [self.pauseButton setTitle:localize(@"MLVB-API-Example.Home.resume") forState:UIControlStateNormal];
    }
    self.playbackPaused = !playing;
    if (@available(iOS 15.0, *)) {
        [self.pipViewController invalidatePlaybackState];
    }
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController
                    skipByInterval:(CMTime)skipInterval
                 completionHandler:(void (^)(void))completionHandler {
    NSLog(@"skipByInterval");
}

@end
