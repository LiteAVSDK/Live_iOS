//
//  PictureInPictureView.m
//  MLVB-API-Example-OC
//
//  Created by adams on 2023/9/18.
//  Copyright © 2023 Tencent. All rights reserved.
//

#import "PictureInPictureView.h"

@implementation PictureInPictureView

+ (Class)layerClass {
  return [AVSampleBufferDisplayLayer class];
}

@end
