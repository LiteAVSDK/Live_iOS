// Copyright (c) 2021 Tencent. All rights reserved.

#import "LiveInputBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface LivePkFindPkUserController : LiveInputBaseViewController
@property(nonatomic, copy)void (^didClickNextBlock)(NSString *streamId);
@end

NS_ASSUME_NONNULL_END
