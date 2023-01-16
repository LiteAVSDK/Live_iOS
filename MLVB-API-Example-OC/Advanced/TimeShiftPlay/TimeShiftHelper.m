//
//  TimeShiftHelper.m
//  TXLiteAVSDK
//
//  Created by annidyfeng on 2018/8/10.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "TimeShiftHelper.h"

@implementation TimeShiftHelper {
    NSString *_stream;
    NSString *_domain;
    NSString *_appName;
}

- (instancetype)initWithDomain:(NSString *)domain {
    if (self = [super init]) {
        _domain = domain;
    }
    return self;
}

- (BOOL)parseUrl:(NSString *)liveUrl {
    NSURL *tmpUrl = [NSURL URLWithString:liveUrl];
    if (!tmpUrl)
        return NO;
    NSArray* path = tmpUrl.pathComponents;
    if (path.count > 2) {
        _appName = [path objectAtIndex:path.count - 2];
    } else {
        _appName = @"live";
    }
    
    _stream = tmpUrl.pathComponents.lastObject;
    if ([_stream containsString:@"."]) {
        NSArray *substrings = [_stream componentsSeparatedByString:@"."];
        _stream = substrings.count > 0 ? substrings[0] : _stream;
    }
    return YES;
}

- (NSString *)getTimeShiftUrl:(NSString *)liveUrl delay:(NSInteger)delay {
    if (![self parseUrl:liveUrl]) {
        return @"";
    }
    NSString *url = [NSString stringWithFormat:@"http://%@/timeshift/%@/%@/timeshift.m3u8?delay=%ld", _domain, _appName, _stream, MAX(delay, 90)];
    return url;
}

@end
