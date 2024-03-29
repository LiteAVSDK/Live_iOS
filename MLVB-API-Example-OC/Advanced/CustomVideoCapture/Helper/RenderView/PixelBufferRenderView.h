//
//  PixelBufferRenderView.h
//  TRTC-API-Example-OC
//
//  Created by luoming on 2021/4/30.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PixelBufferRenderView : UIView

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
