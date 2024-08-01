//
//  ViewController.m
//  MLVB-API-Example-OC
//
//  Created by dangjiahe on 2021/4/10.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "ViewController.h"

#import "HomeTableViewCell.h"
#import <objc/runtime.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *homeTableView;
@property (nonatomic, strong) NSArray *homeData;
@end

@implementation ViewController

- (NSArray *)homeData {
    if (!_homeData) {
        _homeData = @[
            @{@"type":localize(@"MLVB-API-Example.Home.BasicFunctions"),
              @"module":@[
                      @{
                          @"title": localize(@"MLVB-API-Example.Home.LivePushCamera"),
                          @"desc": localize(@"MLVB-API-Example.Home.LivePushCamera.desc"),
                          @"class": @"LivePushCameraEnterViewController"
                      },
                      @{
                          @"title": localize(@"MLVB-API-Example.Home.LivePushScreen"),
                          @"desc": localize(@"MLVB-API-Example.Home.LivePushScreen.desc"),
                          @"class": @"LivePushScreenEnterViewController"
                      },
                      @{
                          @"title": localize(@"MLVB-API-Example.Home.LivePlay"),
                          @"desc": localize(@"MLVB-API-Example.Home.LivePlay.desc"),
                          @"class": @"LivePlayEnterViewController"
                      },
                      @{
                          @"title": localize(@"MLVB-API-Example.Home.LebPlay"),
                          @"desc": @"",
                          @"class": @"LebPlayEnterViewController"
                      },
                      @{
                          @"title": localize(@"MLVB-API-Example.Home.LiveLink"),
                          @"desc": @"",
                          @"class": @"LiveLinkUserInputViewController"
                      },
                      @{
                          @"title": localize(@"MLVB-API-Example.Home.LivePK"),
                          @"desc": @"",
                          @"class": @"LivePkUserInputViewController"
                      }
              ]},
            @{@"type":localize(@"MLVB-API-Example.Home.AdvancedFeatures"),
              @"module":@[
                      @{
                          @"title": localize(@"MLVB-API-Example.Home.CustomCamera"),
                          @"desc": @"",
                          @"class": @"CustomVideoCaptureViewController"
                      },
                      @{
                          @"title": localize(@"MLVB-API-Example.Home.ThirdBeauty"),
                          @"desc": @"",
                          @"class": @"ThirdBeautyEntranceViewController"
                      },
                      @{
                          @"title": localize(@"MLVB-API-Example.Home.RTCPushAndPlay"),
                          @"desc": @"",
                          @"class": @"RTCPushAndPlayEnterViewController"
                      },
                      @{
                          @"title": localize(@"MLVB-API-Example.Home.PictureInPicture"),
                          @"desc": @"",
                          @"class": @"PictureInPictureViewController"
                      },
                      @{
                          @"title": localize(@"MLVB-API-Example.LebAutoBitrate.title"),
                          @"desc": @"",
                          @"class": @"LebAutoBitrateViewController"
                      },
                      @{
                          @"title": localize(@"MLVB-API-Example.HlsAutoBitrate.title"),
                          @"desc": @"",
                          @"class": @"HlsAutoBitrateViewController"
                      },
                      @{
                          @"title": localize(@"MLVB-API-Example.Home.TimeShift"),
                          @"desc": @"",
                          @"class": @"TimeShiftViewController"
                      },
                      @{
                          @"title": localize(@"MLVB-API-Example.Home.NewTimeShiftSprite"),
                          @"desc": @"",
                          @"class": @"NewTimeShiftSpriteViewController"
                      }

              ]}];
    }
    return _homeData;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.interactivePopGestureRecognizer.delegate = (id) self;
    [self setupNaviBarStatus];
    [self setupTableView];
}

- (void)setupNaviBarStatus {
    self.navigationItem.title = localize(@"MLVB-API-Example.Home.Title");
    [self.navigationController setNavigationBarHidden:false animated:false];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

- (void)setupTableView {
    [self.homeTableView registerNib:[UINib nibWithNibName:@"HomeTableViewCell" bundle:nil] forCellReuseIdentifier: gHomeTableViewCellReuseIdentify];
    self.homeTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return  self.homeData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *homeDic = self.homeData[section];
    NSArray *homeArray = [homeDic objectForKey:@"module"];
    return  homeArray.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 40)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, headerView.bounds.size.width, 40)];
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont systemFontOfSize:16];
    NSDictionary *homeDic = self.homeData[section];
    titleLabel.text = [homeDic objectForKey:@"type"];
    [headerView addSubview:titleLabel];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

#pragma mark - UITableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HomeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:gHomeTableViewCellReuseIdentify forIndexPath:indexPath];
    NSDictionary *homeDic = self.homeData[indexPath.section];
    NSArray *homeArray = [homeDic objectForKey:@"module"];
    [cell setHomeDictionary:homeArray[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *homeDic = self.homeData[indexPath.section];
    NSArray *homeArray = [homeDic objectForKey:@"module"];
    NSDictionary *homeFeaturesDic = homeArray[indexPath.row];
    [self pushFeaturesViewController:homeFeaturesDic[@"class"]];
}

- (void)pushFeaturesViewController:(NSString *)className {
    Class class = NSClassFromString(className);
    if (class) {
        id controller = [[class alloc] initWithNibName:className bundle:nil];
        if (controller) {
            [self.navigationController pushViewController:controller animated:true];
        }
    }
}

@end
