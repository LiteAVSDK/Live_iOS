// Copyright (c) 2020 Tencent. All rights reserved.

#import "LiveInputBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface LiveLinkOrPkStreamInputViewController : LiveInputBaseViewController

@property(nonatomic, copy)void (^didClickNextBlock)(NSString *streamId,
                                                    NSString *userId,
                                                    BOOL isAnchor);
- (instancetype)initWithUserId:(NSString *)userId
                      isAnchor:(BOOL)isAnchor
                         title:(NSString *)title;
@end

NS_ASSUME_NONNULL_END
