//
//  TimeShiftHelper.h
//  TXLiteAVSDK
//
//  Created by annidyfeng on 2018/8/10.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeShiftHelper : NSObject

- (instancetype)initWithDomain:(NSString *)domain;
- (NSString *)getTimeShiftUrl:(NSString *)liveUrl delay:(NSInteger)delay;

@end
