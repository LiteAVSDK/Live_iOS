## 目录结构说明

本目录包含 iOS 版 移动直播 SDK 的 Demo 源代码，主要演示接口如何调用以及最基本的功能。

```
├─ MLVB-API-Example-OC        // MLVB API Example，包括直播推流，直播播放，互动直播
|  ├─ App                     // 程序入口界面
|  ├─ Basic                   // 演示 Live 基础功能示例代码
|  |  ├─ LiveLink             // 演示直播连麦示例代码
|  |  ├─ LivePK               // 演示直播 PK 示例代码
|  |  ├─ LivePlay             // 演示直播播放示例代码
|  |  ├─ LivePushCamera       // 演示摄像头推流示例代码
|  |  ├─ LivePushScreen       // 演示屏幕推流示例代码
|  ├─ Advanced                // 演示直播高级功能示例代码
|  |  ├─ CustomVideoCapture   // 演示自定义视频采集示例代码
|  |  ├─ RTCPushAndPlay       // 演示 RTC 推流和播放示例代码
|  |  ├─ LocalVideoShare      // 演示本地视频分享示例代码
|  |  ├─ ThirdBeauty          // 演示第三方美颜示例代码
|  |  ├─ PictureInPicture     // 演示系统画中画示例代码
|  
├─ SDK 
│  ├─ LiteAVSDK_Smart.framework       // 如果您下载的是 Smart 专用 zip 包，解压后将出现此文件夹
│  ├─ LiteAVSDK_Live.framework       // 如果您下载的是 Live 专用 zip 包，解压后将出现此文件夹
|  ├─ LiteAVSDK_Professional.framework // 如果您下载的是专业版 zip 包，解压后将出现此文件夹
```

## SDK 分类和下载

腾讯云 移动直播 SDK 基于 LiteAVSDK 统一框架设计和实现，该框架包含直播、点播、短视频、RTC、AI美颜在内的多项功能：

- 如果您追求最小化体积增量，可以下载 Smart 版：[TXLiteAVSDK_Smart_Android_latest.zip](https://cloud.tencent.com/document/product/454/7873)
- 如果您还需要 连麦PK 的功能，可以下载 Live 版：[TXLiteAVSDK_Live_Android_latest.zip](https://cloud.tencent.com/document/product/454/7873)
- 如果您需要使用多个功能而不希望打包多个 SDK，可以下载专业版：[TXLiteAVSDK_Professional_Android_latest.zip](https://cloud.tencent.com/document/product/454/7873)


## 相关文档链接

- [SDK 的版本更新历史](https://cloud.tencent.com/document/product/454/7878)
- [SDK 的 API 文档](https://cloud.tencent.com/document/product/454/34753)
- [全功能小直播 App（Demo）源代码](https://cloud.tencent.com/document/product/454/38625)

