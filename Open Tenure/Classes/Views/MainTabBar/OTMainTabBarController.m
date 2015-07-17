/**
 * ******************************************************************************************
 * Copyright (C) 2014 - Food and Agriculture Organization of the United Nations (FAO).
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice,this list
 *       of conditions and the following disclaimer.
 *    2. Redistributions in binary form must reproduce the above copyright notice,this list
 *       of conditions and the following disclaimer in the documentation and/or other
 *       materials provided with the distribution.
 *    3. Neither the name of FAO nor the names of its contributors may be used to endorse or
 *       promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,STRICT LIABILITY,OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * *********************************************************************************************
 */
#import "OTMainTabBarController.h"
#import <MapKit/MapKit.h>
#import "CommunityServerAPI.h"
#import "OTNewsViewController.h"
#import "OTMapViewController.h"
#import "OTClaimsViewController.h"

#define newsTabIndex 0
#define communityMapTabIndex 1
#define listOfClaimsTabIndex 2

@interface OTMainTabBarController () <ViewPagerDataSource, ViewPagerDelegate> {
    NSInteger currentTabIndex;
    BOOL firstRun;
}

@property (nonatomic) NSUInteger numberOfTabs;
@property (nonatomic) NSArray *views;

@property (nonatomic) UIBarButtonItem *flexibleSpace;
@property (nonatomic) UIBarButtonItem *fixedSpace;
@property (nonatomic) MKUserTrackingBarButtonItem *myLocation;
@property (nonatomic) UIBarButtonItem *downloadClaims;
@property (nonatomic) UIBarButtonItem *addPerson;
@property (nonatomic) UIBarButtonItem *addClaim;
@property (nonatomic) UIBarButtonItem *import;
@property (nonatomic) UIBarButtonItem *login;
@property (nonatomic) UIBarButtonItem *logout;
@property (nonatomic) UIBarButtonItem *menu;
@property (nonatomic) UIBarButtonItem *done;
@property (nonatomic) UIBarButtonItem *zoomToCommunityArea;
@property (nonatomic) UIBarButtonItem *initialization;
@property (nonatomic) UIBarButtonItem *downloadMapTiles;

@property (nonatomic) NSInteger mapZoomLevel;

@property (nonatomic) UILabel *newsLabel;
@property (nonatomic) UILabel *mapLabel;
@property (nonatomic) UILabel *claimsLabel;

@end

@implementation OTMainTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    self.dataSource = self;
    self.delegate = self;
    
    firstRun = YES;
    
    // Keeps tab bar below navigation bar on iOS 7.0+
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // Setup views
    NSArray *storyboardIdentifiers = @[@"News", @"Map", @"Claims"];
    id news = [self.storyboard instantiateViewControllerWithIdentifier:storyboardIdentifiers[0]];
    id map = [self.storyboard instantiateViewControllerWithIdentifier:storyboardIdentifiers[1]];
    id claims = [self.storyboard instantiateViewControllerWithIdentifier:storyboardIdentifiers[2]];
    _views = @[news, map, claims];
    
    [self createBarButtonItems];
    self.navigationController.toolbar.tintColor = [UIColor otDarkBlue];
    
    [self performSelector:@selector(loadContent) withObject:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationChanged:) name:kLoginSuccessNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationChanged:) name:kLogoutSuccessNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initializationChanged:) name:kInitializedNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapZoomLevelChanged:) name:kMapZoomLevelNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setTabBarIndex:) name:kSetMainTabBarIndexNotificationName object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma loginActionSuccessful notification

- (void)authenticationChanged:(NSNotification *)notification {
    [self setBarButtonItemsForTabBarIndex:currentTabIndex];
}

- (void)initializationChanged:(NSNotification *)notification {
    [self setBarButtonItemsForTabBarIndex:newsTabIndex];
    [_views[communityMapTabIndex] configureCommunityArea];
}

- (void)mapZoomLevelChanged:(NSNotification *)notification {
    _mapZoomLevel = [notification.object integerValue];
    [self setBarButtonItemsForTabBarIndex:currentTabIndex];
}

- (void)setTabBarIndex:(NSNotification *)notification {
    NSInteger index = [notification.object integerValue];
    [self selectTabAtIndex:index];
    if (notification.userInfo != nil) {
        if ([[notification.userInfo objectForKey:@"action"] isEqualToString:@"close"]) {
            NSArray *items0 = @[@{@"type":[NSNumber numberWithInt:0],
                                  @"target":_newsLabel,
                                  @"title":@"",
                                  @"detail":NSLocalizedStringFromTable(@"showcase_actionAlert1_message", @"Showcase", nil)},
                                @{@"type":[NSNumber numberWithInt:0],
                                  @"target":[OT findBarButtonItem:_initialization fromNavBar:self.navigationController.navigationBar],
                                  @"title":@"",
                                  @"detail":NSLocalizedStringFromTable(@"showcase_actionAlert_message", @"Showcase", nil)}];
            [_views[newsTabIndex] setShowcaseTargetList:items0];
            [_views[index] defaultShowcase:notification.userInfo];
        } else {
            [_views[index] defaultShowcase:nil];
        }
    }
}

#pragma mark - Setters

- (void)setNumberOfTabs:(NSUInteger)numberOfTabs {
    _numberOfTabs = numberOfTabs;
    [self reloadData];
}

#pragma mark - Helpers

- (void)loadContent {
    self.numberOfTabs = _views.count;
}

#pragma mark - Interface Orientation Changes

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self performSelector:@selector(setNeedsReloadOptions) withObject:nil];
}

#pragma mark - ViewPagerDataSource

- (NSUInteger)numberOfTabsForViewPager:(ViewPagerController *)viewPager {
    return self.numberOfTabs;
}

- (UIView *)viewPager:(ViewPagerController *)viewPager viewForTabAtIndex:(NSUInteger)index {
    NSArray *titles = @[NSLocalizedString(@"title_news", @"News"), NSLocalizedString(@"title_map", @"Map"), NSLocalizedString(@"title_claims", @"Claims")];
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:14.0];
    label.text = [titles[index] uppercaseString];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    [label sizeToFit];

    switch (index) {
        case 0:
            _newsLabel = label;
            break;
        case 1:
            _mapLabel = label;
            break;
        case 2:
            _claimsLabel = label;
            break;
    }
    return label;
}

- (UIViewController *)viewPager:(ViewPagerController *)viewPager contentViewControllerForTabAtIndex:(NSUInteger)index {
    id cvc = _views[index];
    return cvc;
}

- (void)viewPager:(ViewPagerController *)viewPager didChangeTabToIndex:(NSUInteger)index {
    currentTabIndex = index;
    [self setBarButtonItemsForTabBarIndex:index];
}

- (CGFloat)viewPager:(ViewPagerController *)viewPager valueForOption:(ViewPagerOption)option withDefault:(CGFloat)value {
    switch (option) {
        case ViewPagerOptionStartFromSecondTab:
            if ([OT getInitialized])
                return 1.0;
            else
                return 0.0;
        case ViewPagerOptionCenterCurrentTab:
            return 0.0;
        case ViewPagerOptionTabLocation:
            return 1.0;
        case ViewPagerOptionTabHeight:
            return 49.0;
        case ViewPagerOptionTabOffset:
            return 36.0;
        case ViewPagerOptionTabWidth:
            return UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? 128.0 : 96.0;
        case ViewPagerOptionFixFormerTabsPositions:
            return 0.0;
        case ViewPagerOptionFixLatterTabsPositions:
            return 0.0;//1.0 cuộn
        default:
            return value;
    }
}

#pragma Bar Button Items

/*!
 Create bar button items
 @result
 myLocation, downloadClaims, menu
 */

- (void)createBarButtonItems {
    
    _flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    _fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    _fixedSpace.width = 22;
    
    OTMapViewController *mapViewController = (OTMapViewController *)_views[1];
    _myLocation = [[MKUserTrackingBarButtonItem alloc] initWithMapView:mapViewController.mapView];
    
    _downloadClaims = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_download"] style:UIBarButtonItemStylePlain target:_views[communityMapTabIndex] action:@selector(downloadClaims:)];
    
    _addClaim = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_add_claim"] style:UIBarButtonItemStylePlain target:_views[listOfClaimsTabIndex] action:@selector(addClaim:)];
    
    _import = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_import"] style:UIBarButtonItemStylePlain target:_views[2] action:@selector(showImportClaim:)];
    
    _login = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login_door"] style:UIBarButtonItemStylePlain target:_views[listOfClaimsTabIndex] action:@selector(login:)];
    
    _logout = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"logout_door"] style:UIBarButtonItemStylePlain target:_views[listOfClaimsTabIndex] action:@selector(logout:)];
    
    _menu = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu"] style:UIBarButtonItemStylePlain target:_views[2] action:@selector(showMenu:)];
    
    _zoomToCommunityArea = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_community_area"] style:UIBarButtonItemStylePlain target:_views[communityMapTabIndex] action:@selector(zoomToCommunityArea:)];
    
    _initialization = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_warning"] style:UIBarButtonItemStylePlain target:_views[communityMapTabIndex] action:@selector(initialization:)];
    
    _downloadMapTiles = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_download_tiles"] style:UIBarButtonItemStylePlain target:_views[communityMapTabIndex] action:@selector(downloadMapTiles:)];
}

- (void)setBarButtonItemsForTabBarIndex:(NSInteger)index {

    NSString *buttonTitle = NSLocalizedString(@"app_name", nil);
    UIBarButtonItem *logo = [OT logoButtonWithTitle:buttonTitle];
    self.navigationItem.leftBarButtonItems = @[logo];
    
    [_menu setTarget:_views[index]];
    UIBarButtonItem *login = [OTAppDelegate authenticated] ? _logout : _login;
//    [login setTarget:_views[index]];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    switch (index) {
        case 0: {
            if ([OTSetting getInitialization])
                self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, login, _flexibleSpace];
            else
                self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, login, _fixedSpace, _initialization, _flexibleSpace];
            [self setToolbarItems:nil];
            
            // Showcase
            UIControl *loginView = [OT findBarButtonItem:login fromNavBar:navBar];
            UIControl *initButtonView = [OTSetting getInitialization] ? nil : [OT findBarButtonItem:_initialization fromNavBar:navBar];
            NSArray *target2;
            if (initButtonView)
                target2 = @[initButtonView, loginView, [OT findBarButtonItem:_menu fromNavBar:navBar]];
            else
                target2 = @[loginView, [OT findBarButtonItem:_menu fromNavBar:navBar]];
            
            NSArray *items0 = @[@{@"type":[NSNumber numberWithInt:-1], // -1 Không focus
                                  @"target":[UIView new],
                                  @"title":NSLocalizedStringFromTable(@"showcase_main_title", @"Showcase", nil),
                                  @"detail":NSLocalizedStringFromTable(@"showcase_main_message", @"Showcase", nil)},
                                @{@"type":[NSNumber numberWithInt:0],
                                  @"target":_newsLabel,
                                  @"title":NSLocalizedString(@"title_news", @"News"),
                                  @"detail":NSLocalizedStringFromTable(@"showcase_news_message", @"Showcase", nil)},
                                @{@"type":[NSNumber numberWithInt:1],
                                  @"target":target2,
                                  @"title":@"",
                                  @"detail":NSLocalizedStringFromTable(@"showcase_actionNews_message", @"Showcase", nil)}];
            [_views[newsTabIndex] setShowcaseTargetList:items0];
            if (![OT getInitialized] && firstRun) {
                [_views[newsTabIndex] defaultShowcase:nil];
                firstRun = NO;
            }

            break;
        }
        case 1: {
            _myLocation.mapView = [(OTMapViewController *)_views[1] mapView];
            if (_mapZoomLevel >= 16)
                self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, _downloadMapTiles, _fixedSpace, _downloadClaims, _fixedSpace, _zoomToCommunityArea, _fixedSpace, _myLocation, _fixedSpace, login, _flexibleSpace];
            else
                self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, _downloadClaims, _fixedSpace, _zoomToCommunityArea, _fixedSpace, _myLocation, _fixedSpace, login, _flexibleSpace];
            [self setToolbarItems:nil];
            
            // Showcase
            UIControl *loginView = [OT findBarButtonItem:login fromNavBar:navBar];
            NSArray *items1 = @[@{@"type":[NSNumber numberWithInt:0],
                                  @"target":_mapLabel,
                                  @"title":NSLocalizedString(@"title_map", @"Community Map"),
                                  @"detail":NSLocalizedStringFromTable(@"showcase_map_message", @"Showcase", nil)},
                                @{@"type":[NSNumber numberWithInt:1],
                                  @"target":@[loginView, [OT findBarButtonItem:_menu fromNavBar:navBar]],
                                  @"title":@"",
                                  @"detail":NSLocalizedStringFromTable(@"showcase_actionMap_message", @"Showcase", nil)}];
            [_views[communityMapTabIndex] setShowcaseTargetList:items1];
            break;
        }
        case 2:
            self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, login, _fixedSpace, _import, _fixedSpace, _addClaim, _flexibleSpace];
            // Showcase
            NSArray *items2 = @[@{@"type":[NSNumber numberWithInt:0],
                                  @"target":_claimsLabel,
                                  @"title":NSLocalizedString(@"title_claims", @"List of claims"),
                                  @"detail":NSLocalizedStringFromTable(@"showcase_claims_message", @"Showcase", nil)},
                                @{@"type":[NSNumber numberWithInt:1],
                                  @"target":@[[OT findBarButtonItem:_addClaim fromNavBar:navBar], [OT findBarButtonItem:_menu fromNavBar:navBar]],
                                  @"title":@"",
                                  @"detail":NSLocalizedStringFromTable(@"showcase_actionClaims_message", @"Showcase", nil)}];
            [_views[listOfClaimsTabIndex] setShowcaseTargetList:items2];
            break;
    }
}

@end
