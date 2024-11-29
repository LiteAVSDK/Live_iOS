//
//  TXSpriteImageFetcher.h
//  MLVB-API-Example-OC
//
//  Created by carol on 2024/04/22.
//  Copyright © 2024 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SpriteThumbnailFetchErrCode) {
  SPRITE_THUMBNAIL_FETCH_SUCC = 0,
  SPRITE_THUMBNAIL_FETCH_PARAM_INVALID = -1,
  SPRITE_THUMBNAIL_FETCH_NETWORK_ERR = -2,
  SPRITE_THUMBNAIL_FETCH_SERVER_ERROR = -3
};

@protocol TXSpriteImageFetcherDelegate <NSObject>
- (void)onFetchDone:(SpriteThumbnailFetchErrCode)errCode image:(UIImage *)image;
@end

@interface TXSpriteImageFetcher : NSObject

- (void)init:(NSString *)domain
        path:(NSString *)path
    streamId:(NSString *)streamId
     startTs:(long)startTs
       endTs:(long)endTs;

- (void)setDelegate:(id<TXSpriteImageFetcherDelegate>)delegate;

- (void)getThumbnail:(long)time;

- (void)setCacheSize:(NSInteger)size;

- (void)clear;

@end
