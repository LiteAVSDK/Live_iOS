//
//  NewTimeShiftSpriteViewController.m
//  MLVB-API-Example-OC
//
//  Created by carol on 2024/04/22.
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "NewTimeShiftSpriteViewController.h"
#import "TXSpriteImageFetcher.h"

static NSString *const G_NEW_TIME_SHIFT_DOMAIN = @"5000.liveplay.myqcloud.com";
static NSString *const G_NEW_TIME_SHIFT_PATH = @"live";
static NSString *const G_NEW_TIME_SHIFT_STREAMID = @"5000_testsprite";

@interface NewTimeShiftSpriteViewController () <UITextFieldDelegate, TXSpriteImageFetcherDelegate>

@property(weak, nonatomic) IBOutlet UITextField *playDomain;
@property(weak, nonatomic) IBOutlet UITextField *playPath;
@property(weak, nonatomic) IBOutlet UITextField *streamId;
@property(weak, nonatomic) IBOutlet UIDatePicker *startTimePick;
@property(weak, nonatomic) IBOutlet UIDatePicker *endTimePick;
@property(weak, nonatomic) IBOutlet UITextField *playOffsetHh;
@property(weak, nonatomic) IBOutlet UITextField *playOffsetMm;
@property(weak, nonatomic) IBOutlet UITextField *playOffsetSs;
@property(weak, nonatomic) IBOutlet UIButton *btnShowSprite;
@property(weak, nonatomic) IBOutlet UIImageView *spriteImage;

@property(nonatomic, strong) TXSpriteImageFetcher *spriteImageFetcher;

@end

@implementation NewTimeShiftSpriteViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = localize(@"MLVB-API-Example.Home.NewTimeShiftSprite");
  self.view.backgroundColor = UIColor.blackColor;
  [self initView];
  [self addKeyboardObserver];
}

- (void)initView {
  self.playDomain.text = G_NEW_TIME_SHIFT_DOMAIN;
  self.playPath.text = G_NEW_TIME_SHIFT_PATH;
  self.streamId.text = G_NEW_TIME_SHIFT_STREAMID;
  NSDate *currentDate = [NSDate date];
  NSDate *oneHourLater = [currentDate dateByAddingTimeInterval:3600];  // 3600秒表示一小时
  [self.startTimePick setDate:currentDate];
  [self.endTimePick setDate:oneHourLater];
}

- (void)dealloc {
  [self removeKeyboardObserver];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [self.view endEditing:true];
}

- (IBAction)onBtnShowSpriteClick:(id)sender {
  [self.spriteImage setImage:nil];
  if (self.spriteImageFetcher == nil) {
    self.spriteImageFetcher = [[TXSpriteImageFetcher alloc] init];
    [self.spriteImageFetcher setDelegate:self];
    [self.spriteImageFetcher setCacheSize:10];
    [self.spriteImageFetcher init:self.playDomain.text
                             path:self.playPath.text
                         streamId:self.streamId.text
                          startTs:(long)[self.startTimePick.date timeIntervalSince1970]
                            endTs:(long)[self.endTimePick.date timeIntervalSince1970]];
  }
  long time = 3600 * [self.playOffsetHh.text intValue] + 60 * [self.playOffsetMm.text intValue] +
      [self.playOffsetSs.text intValue];
  [self.spriteImageFetcher getThumbnail:time];
}

#pragma mark - TXSpriteImageFetcherDelegate
- (void)onFetchDone:(SpriteThumbnailFetchErrCode)errCode image:(UIImage *)image {
  if (errCode != SPRITE_THUMBNAIL_FETCH_SUCC) {
    NSString *msg = [NSString stringWithFormat:@"onFetchDone errCode is %ld", (long)errCode];
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"提示"
                                            message:msg
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    // 弹出提示框
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    [self.spriteImage setImage:image];
  }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string {
  return YES;
}

#pragma mark - Notification

- (void)addKeyboardObserver {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

- (void)removeKeyboardObserver {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardWillShowNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardWillHideNotification
                                                object:nil];
}

- (BOOL)keyboardWillShow:(NSNotification *)noti {
  return YES;
}

- (BOOL)keyboardWillHide:(NSNotification *)noti {
  return YES;
}

@end
