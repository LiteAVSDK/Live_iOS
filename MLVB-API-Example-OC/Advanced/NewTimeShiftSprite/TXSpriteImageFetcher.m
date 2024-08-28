//
//  TXSpriteImageFetcher.m
//  MLVB-API-Example-OC
//
//  Created by carol on 2024/04/22.
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "TXSpriteImageFetcher.h"

static NSString *const CONFIG_URL_FORMAT =
    @"http://%@/%@/%@.json?txTimeshift=on&tsFormat=unix&tsSpritemode=1&tsStart=%ld&tsEnd=%ld";
static NSString *const BIG_IMAGE_URL_FORMAT = @"http://%@%@%ld.jpg?txTimeshift=on";

@interface TXSpriteConfigData : NSObject

@property(nonatomic, assign) long startTime;
@property(nonatomic, assign) long endTime;
@property(nonatomic, assign) double duration;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, assign) int cols;
@property(nonatomic, assign) int rows;
@property(nonatomic, assign) int intervalS;
@property(nonatomic, assign) int height;
@property(nonatomic, assign) int width;

@end

@implementation TXSpriteConfigData

- (instancetype)initWithData:(NSDictionary *)data {
  self.startTime = [data[@"start_time"] longValue];
  self.endTime = [data[@"end_time"] longValue];
  self.duration = [data[@"duration"] doubleValue];
  self.path = data[@"path"];
  self.cols = [data[@"cols"] intValue];
  self.rows = [data[@"rows"] intValue];
  self.intervalS = [data[@"interval"] intValue];
  self.height = [data[@"height"] intValue];
  self.width = [data[@"width"] intValue];

  return self;
}

- (BOOL)isValid {
  return (self.path && self.startTime && self.endTime && self.cols && self.rows && self.intervalS &&
          self.width && self.height);
}

@end

@interface TXSpriteImageFetcher ()

@property(atomic, assign) BOOL isFetchingSpriteConfig;
@property(nonatomic, strong) NSMutableArray<NSString *> *downloadingImageUrls;
@property(nonatomic, strong) NSArray<TXSpriteConfigData *> *spriteConfigArray;
@property(nonatomic, strong) NSCache *bigImgCache;
@property(nonatomic, strong) NSCache *smallImgCache;

@property(nonatomic, copy) NSString *domain;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, copy) NSString *streamId;
@property(nonatomic, assign) long startTs;
@property(nonatomic, assign) long endTs;

@property(atomic, assign) long fetchingTime;
@property(weak, nonatomic) id<TXSpriteImageFetcherDelegate> delegate;

@end

@implementation TXSpriteImageFetcher

- (void)init:(NSString *)domain
        path:(NSString *)path
    streamId:(NSString *)streamId
     startTs:(long)startTs
       endTs:(long)endTs {
  self.domain = domain;
  self.path = path;
  self.streamId = streamId;
  self.startTs = startTs;
  self.endTs = endTs;

  self.spriteConfigArray = [[NSMutableArray alloc] init];
  self.bigImgCache = [[NSCache alloc] init];
  self.smallImgCache = [[NSCache alloc] init];

  self.isFetchingSpriteConfig = NO;
  [self setCacheSize:30];
}

- (void)setDelegate:(id<TXSpriteImageFetcherDelegate>)delegate {
  @synchronized(_delegate) {
    _delegate = delegate;
  }
}

- (void)getThumbnail:(long)time {
  _fetchingTime = time;

  UIImage *smallImage = [self getThumbnailFromSmallImageCache:time];
  if (smallImage != nil) {
    [self notifyFetchThumbnailResult:SPRITE_THUMBNAIL_FETCH_SUCC image:smallImage];
    return;
  }

  smallImage = [self getThumbnailFromBigImageCache:time];
  if (smallImage != nil) {
    [self.smallImgCache setObject:smallImage forKey:@(time)];
    [self notifyFetchThumbnailResult:SPRITE_THUMBNAIL_FETCH_SUCC image:smallImage];
    return;
  }

  if (![self isSpriteConfigDataExist:time]) {
    [self fetchSpriteConfig];
    return;
  }

  NSString *bigImageUrl = [self getBigImageUrl:time];
  if (bigImageUrl.length > 0) {
    [self fetchBigImage:bigImageUrl];
  } else {
    [self notifyFetchThumbnailResult:SPRITE_THUMBNAIL_FETCH_PARAM_INVALID image:nil];
  }
}

- (void)setCacheSize:(NSInteger)size {
  [self.smallImgCache setCountLimit:size];
  [self.bigImgCache setCountLimit:size];
}

- (void)clear {
  self.domain = nil;
  self.path = nil;
  self.streamId = nil;
  self.startTs = 0;
  self.endTs = 0;

  self.isFetchingSpriteConfig = NO;
  self.spriteConfigArray = nil;

  [self.bigImgCache removeAllObjects];
  [self.smallImgCache removeAllObjects];
  [self.downloadingImageUrls removeAllObjects];
  _fetchingTime = 0;
}

- (BOOL)isSpriteConfigDataExist:(long)time {
  TXSpriteConfigData *configData = [self getSpriteConfig:time];
  if (configData == nil || ![configData isValid]) {
    return NO;
  }
  return YES;
}

- (UIImage *)getThumbnailFromSmallImageCache:(long)time {
  return [self.smallImgCache objectForKey:@(time)];
}

- (UIImage *)getBigImageFromCache:(long)time {
  NSString *bigImageUrl = [self getBigImageUrl:time];
  return [self.bigImgCache objectForKey:bigImageUrl];
}

- (UIImage *)getThumbnailFromBigImageCache:(long)time {
  UIImage *bigImage = [self getBigImageFromCache:time];
  if (bigImage == nil) {
    return nil;
  }

  TXSpriteConfigData *configData = [self getSpriteConfig:time];
  if (configData == nil || ![configData isValid]) {
    return nil;
  }

  long relativeOffset = [self getRelativeOffset:time configData:configData];
  if (relativeOffset < 0) {
    NSLog(@"getThumbnailFromBigImageCache time[%ld] is invalid, relativeOffset is %ld.",
          time,
          relativeOffset);
    return nil;
  }

  CGRect smallImageRect = [self getSmallImageRect:relativeOffset configData:configData];
  UIImage *smallImage = [self cropImg:bigImage smallImageRect:smallImageRect];

  return smallImage;
}

- (NSString *)getBigImageUrl:(long)time {
  TXSpriteConfigData *configData = [self getSpriteConfig:time];
  if (configData == nil || ![configData isValid]) {
    return @"";
  }

  long relativeOffset = [self getRelativeOffset:time configData:configData];
  if (relativeOffset < 0) {
    NSLog(@"getThumbnail time[%ld] is invalid, relativeOffset is %ld.", time, relativeOffset);
    return @"";
  }

  long picNo = (relativeOffset / (configData.intervalS * configData.cols * configData.rows));
  return [NSString stringWithFormat:BIG_IMAGE_URL_FORMAT, self.domain, configData.path, picNo];
}

- (void)fetchSpriteConfig {
  if (_isFetchingSpriteConfig) {
    return;
  }
  _isFetchingSpriteConfig = YES;

  __weak TXSpriteImageFetcher *weak_self = self;
  NSString *strUrl = [NSString stringWithFormat:CONFIG_URL_FORMAT,
                                                self.domain,
                                                self.path,
                                                self.streamId,
                                                self.startTs,
                                                self.endTs];
  NSLog(@"fetchSpriteConfig url is %@", strUrl);
  NSURL *url = [NSURL URLWithString:strUrl];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"GET"];
  NSURLSession *session = [NSURLSession sharedSession];
  NSURLSessionDataTask *dataTask =
      [session dataTaskWithRequest:request
                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                   __strong TXSpriteImageFetcher *strongSelf = weak_self;
                   [strongSelf handleFetchSpriteConfigResponse:data response:response error:error];
                 }];
  [dataTask resume];
}

- (void)handleFetchSpriteConfigResponse:(NSData *)data
                               response:(NSURLResponse *)response
                                  error:(NSError *)error {
  _isFetchingSpriteConfig = NO;
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
  if (error) {
    NSLog(@"fetchSpriteConfig failed %@", error.localizedDescription);
    [self notifyFetchThumbnailResult:SPRITE_THUMBNAIL_FETCH_NETWORK_ERR image:nil];
    return;
  }
  NSLog(@"fetchSpriteConfig response code %ld", httpResponse.statusCode);
  if (httpResponse.statusCode != 200 || data == nil) {
    [self notifyFetchThumbnailResult:SPRITE_THUMBNAIL_FETCH_SERVER_ERROR image:nil];
    return;
  }
  [self handleFetchSpriteConfigData:data];
}

- (void)handleFetchSpriteConfigData:(NSData *)data {
  NSError *jsonError;
  NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data
                                                       options:NSJSONReadingMutableContainers
                                                         error:&jsonError];
  if (jsonError) {
    NSLog(@"fetchSpriteConfig response json 解析失败: %@", jsonError.localizedDescription);
    [self notifyFetchThumbnailResult:SPRITE_THUMBNAIL_FETCH_SERVER_ERROR image:nil];
    return;
  }

  NSMutableArray *retArray = [[NSMutableArray alloc] init];
  NSLog(@"fetchSpriteConfig response data:%@", jsonArray);
  for (NSDictionary *json in jsonArray) {
    TXSpriteConfigData *configData = [[TXSpriteConfigData alloc] initWithData:json];
    [retArray addObject:configData];
  }
  self.spriteConfigArray = retArray;

  TXSpriteConfigData *configData = [self getSpriteConfig:_fetchingTime];
  if (configData == nil || ![configData isValid]) {
    [self notifyFetchThumbnailResult:SPRITE_THUMBNAIL_FETCH_SERVER_ERROR image:nil];
    return;
  }

  NSString *bigImageUrl = [self getBigImageUrl:_fetchingTime];
  if (bigImageUrl.length > 0) {
    [self fetchBigImage:bigImageUrl];
  } else {
    [self notifyFetchThumbnailResult:SPRITE_THUMBNAIL_FETCH_PARAM_INVALID image:nil];
  }
}

- (TXSpriteConfigData *)getSpriteConfig:(long)time {
  for (TXSpriteConfigData *data in self.spriteConfigArray) {
    if (self.startTs + time >= data.startTime && self.startTs + time < data.endTime) {
      return data;
    }
  }
  return nil;
}

- (long)getRelativeOffset:(long)time configData:(TXSpriteConfigData *)configData {
  // 计算出相对场次的偏移时间
  long relativeOffset = time;
  if (self.startTs < configData.startTime) {
    relativeOffset -= (configData.startTime - self.startTs);
  } else {
    relativeOffset += (self.startTs - configData.startTime);
  }
  return relativeOffset;
}

- (void)fetchBigImage:(NSString *)bigImageUrl {
  @synchronized(_downloadingImageUrls) {
    if ([_downloadingImageUrls containsObject:bigImageUrl]) {
      return;
    }
    [_downloadingImageUrls addObject:bigImageUrl];
  }

  NSLog(@"fetchBigImage url:%@", bigImageUrl);

  __weak TXSpriteImageFetcher *weak_self = self;
  NSURLSession *session = [NSURLSession sharedSession];
  NSURL *url = [NSURL URLWithString:bigImageUrl];
  NSURLRequest *imageUrlRequest = [NSURLRequest requestWithURL:url];
  NSURLSessionDataTask *imgTask = [session
      dataTaskWithRequest:imageUrlRequest
        completionHandler:^(
            NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
          __strong TXSpriteImageFetcher *strongSelf = weak_self;
          [strongSelf handleFetchBigImageResponse:bigImageUrl
                                             data:data
                                         response:response
                                            error:error];
        }];
  // 开始下载
  [imgTask resume];
}

- (void)handleFetchBigImageResponse:(NSString *)bigImageUrl
                               data:(NSData *)data
                           response:(NSURLResponse *)response
                              error:(NSError *)error {
  @synchronized(_downloadingImageUrls) {
    [_downloadingImageUrls removeObject:bigImageUrl];
  }
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
  if (error) {
    NSLog(@"fetchBigImage failed %@", error.localizedDescription);
    [self notifyFetchThumbnailResult:SPRITE_THUMBNAIL_FETCH_NETWORK_ERR image:nil];
    return;
  }
  NSLog(@"fetchBigImage response code %ld", httpResponse.statusCode);
  if (httpResponse.statusCode != 200 || data == nil) {
    [self notifyFetchThumbnailResult:SPRITE_THUMBNAIL_FETCH_SERVER_ERROR image:nil];
    return;
  }

  UIImage *img = [UIImage imageWithData:data];
  [self.bigImgCache setObject:img forKey:bigImageUrl];
  UIImage *smallImage = [self getThumbnailFromBigImageCache:_fetchingTime];
  [self notifyFetchThumbnailResult:smallImage == nil ? SPRITE_THUMBNAIL_FETCH_SERVER_ERROR :
                                                       SPRITE_THUMBNAIL_FETCH_SUCC
                             image:smallImage];
}

- (CGRect)getSmallImageRect:(long)time configData:(TXSpriteConfigData *)configData {
  int picOffset =
      time % (configData.intervalS * configData.rows * configData.cols) / configData.intervalS;
  CGRect rect = CGRectZero;
  rect.origin.x = (picOffset % configData.cols) * configData.width;
  rect.origin.y = (picOffset / configData.cols) * configData.height;
  rect.size.width = configData.width;
  rect.size.height = configData.height;
  return rect;
}

- (UIImage *)cropImg:(UIImage *)bigImg smallImageRect:(CGRect)smallImageRect {
  if (!bigImg) {
    return nil;
  }

  CGRect rect = CGRectMake(smallImageRect.origin.x * bigImg.scale,
                           smallImageRect.origin.y * bigImg.scale,
                           smallImageRect.size.width * bigImg.scale,
                           smallImageRect.size.height * bigImg.scale);

  CGImageRef imageRef = CGImageCreateWithImageInRect([bigImg CGImage], rect);
  UIImage *result = [UIImage imageWithCGImage:imageRef
                                        scale:bigImg.scale
                                  orientation:bigImg.imageOrientation];
  CGImageRelease(imageRef);
  return result;
}

- (void)notifyFetchThumbnailResult:(SpriteThumbnailFetchErrCode)code image:(UIImage *)image {
  NSLog(@"notifyFetchThumbnailResult errCode is %ld", code);
  @synchronized(self) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self->_delegate != nil &&
          [self->_delegate respondsToSelector:@selector(onFetchDone:image:)]) {
        [self->_delegate onFetchDone:code image:image];
      }
    });
  }
}

@end
