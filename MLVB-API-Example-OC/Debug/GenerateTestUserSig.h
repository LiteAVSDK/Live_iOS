//  Copyright © 2021 Tencent. All rights reserved.

/*
 * Module:   GenerateTestUserSig
 *
 * Description: generates UserSig for testing. UserSig is a security signature designed by Tencent Cloud for its cloud services.
 *           It is calculated based on `SDKAppID`, `UserID`, and `EXPIRETIME` using the HMAC-SHA256 encryption algorithm.
 *
 * Attention: do not use the code below in your commercial app. This is because:
 *
 *            The code may be able to calculate UserSig correctly, but it is only for quick testing of the SDK’s basic features, not for commercial apps.
 *            `SDKSECRETKEY` in client code can be easily decompiled and reversed, especially on web.
 *             Once your key is disclosed, attackers will be able to steal your Tencent Cloud traffic.
 *
 *            The correct method is to deploy the `UserSig` calculation code and encryption key on your project server so that your app can request from your server a `UserSig` that is calculated whenever one is needed.
 *           Given that it is more difficult to hack a server than a client app, server-end calculation can better protect your key.
 *
 * Reference: https://cloud.tencent.com/document/product/647/17275#Server
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Configure push address
 * Tencent Cloud domain name management page: https://console.cloud.tencent.com/live/domainmanage
 */
static NSString * const PUSH_DOMAIN = @"";

/**
 * Configure the streaming address
 * Tencent Cloud domain name management page: https://console.cloud.tencent.com/live/domainmanage
 */
static NSString * const PLAY_DOMAIN = @"";

/**
 * URL authentication key
 */
static NSString * const LIVE_URL_KEY = @"";

/**
 * Tencent Cloud License management page (https://console.cloud.tencent.com/live/license)
 * Currently applied License LicenseUrl
 *
 * License Management View (https://console.cloud.tencent.com/live/license)
 * License URL of your application
 */
static NSString * const LICENSEURL = @"";

/**
 * Tencent Cloud License management page (https://console.cloud.tencent.com/live/license)
 * Currently applied License Key
 *
 * License Management View (https://console.cloud.tencent.com/live/license)
 * License key of your application
 */
static NSString * const LICENSEURLKEY = @"";

/**
 * Tencent Cloud `SDKAppID`. Set it to the `SDKAppID` of your account.
 *
 * You can view your `SDKAppID` after creating an application in the [TRTC console](https://console.cloud.tencent.com/rav).
 * `SDKAppID` uniquely identifies a Tencent Cloud account.
 */
static const int SDKAppID = 0;

/**
 * Signature validity period, which should not be set too short
 * <p>
 * Unit: second
 * Default value: 604800 (7 days)
 */
static const int EXPIRETIME = 0;


/**
 * Follow the steps below to obtain the key required for UserSig calculation.
 *
 * Step 1. Log in to the [TRTC console](https://console.cloud.tencent.com/rav), and create an application if you don’t have one.
 * Step 2. Find your application, click “Application Info”, and click the “Quick Start” tab.
 * Step 3. Copy and paste the key to the code, as shown below.
 *
 * Note: this method is for testing only. Before commercial launch, please migrate the UserSig calculation code and key to your backend server to prevent key disclosure and traffic stealing.
 * Reference: https://cloud.tencent.com/document/product/647/17275#Server
 */
static NSString * const SDKSECRETKEY = @"";


@interface GenerateTestUserSig : NSObject

/**
 * Calculating UserSig
 *
 * The asymmetric encryption algorithm HMAC-SHA256 is used in the function to calculate UserSig based on `SDKAppID`, `UserID`, and `EXPIRETIME`.
 *
 * @note: do not use the code below in your commercial app. This is because:
 *
 * The code may be able to calculate UserSig correctly, but it is only for quick testing of the SDK’s basic features, not for commercial apps.
 * `SDKSECRETKEY` in client code can be easily decompiled and reversed, especially on web.
 * Once your key is disclosed, attackers will be able to steal your Tencent Cloud traffic.
 *
 * The correct method is to deploy the `UserSig` calculation code on your project server so that your app can request from your server a `UserSig` that is calculated whenever one is needed.
 * Given that it is more difficult to hack a server than a client app, server-end calculation can better protect your key.
 *
 * Reference: https://cloud.tencent.com/document/product/647/17275#Server
 */
+ (NSString *)genTestUserSig:(NSString *)identifier;
@end

NS_ASSUME_NONNULL_END
