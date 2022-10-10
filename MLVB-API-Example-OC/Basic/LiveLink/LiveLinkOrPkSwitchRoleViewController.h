// Copyright (c) 2020 Tencent. All rights reserved.

#import "ViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface LiveLinkOrPkSwitchRoleViewController : ViewController

@property(nonatomic, copy)void (^didClickNextBlock)(NSString *userId, BOOL isAnchor);
- (instancetype)initWithUserId:(NSString *)userId title:(NSString *)title;
@end
NS_ASSUME_NONNULL_END
