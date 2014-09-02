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
#import "OTPersonsViewController.h"
#import "OTClaimsViewController.h"

@interface OTMainTabBarController () <ViewPagerDataSource, ViewPagerDelegate>

@property (nonatomic) NSUInteger numberOfTabs;
@property (nonatomic) NSArray *views;

@property (nonatomic) UIBarButtonItem *flexibleSpace;
@property (nonatomic) UIBarButtonItem *fixedSpace;
@property (nonatomic) MKUserTrackingBarButtonItem *myLocation;
@property (nonatomic) UIBarButtonItem *downloadClaims;
@property (nonatomic) UIBarButtonItem *addPerson;
@property (nonatomic) UIBarButtonItem *addClaim;
@property (nonatomic) UIBarButtonItem *login;
@property (nonatomic) UIBarButtonItem *logout;
@property (nonatomic) UIBarButtonItem *menu;
@property (nonatomic) UIBarButtonItem *done;

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
    
    self.dataSource = self;
    self.delegate = self;
    
    // self.title = @"Main View";
    
    // Keeps tab bar below navigation bar on iOS 7.0+
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // Setup views
    NSArray *storyboardIdentifiers = @[@"News", @"Map", @"Persons", @"Claims"];
    id news = [self.storyboard instantiateViewControllerWithIdentifier:storyboardIdentifiers[0]];
    id map = [self.storyboard instantiateViewControllerWithIdentifier:storyboardIdentifiers[1]];
    id persons = [self.storyboard instantiateViewControllerWithIdentifier:storyboardIdentifiers[2]];
    id claims = [self.storyboard instantiateViewControllerWithIdentifier:storyboardIdentifiers[3]];
    _views = @[news, map, persons, claims];
    
    [self createBarButtonItems];
    self.navigationController.toolbar.tintColor = [UIColor otDarkBlue];
    
    [self performSelector:@selector(loadContent) withObject:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationChanged:) name:kLoginSuccessNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationChanged:) name:kLogoutSuccessNotificationName object:nil];
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
    
    [self setBarButtonItemsForTabBarIndex:3];
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Update changes after screen rotates
    [self performSelector:@selector(setNeedsReloadOptions) withObject:nil afterDelay:duration];
}

#pragma mark - ViewPagerDataSource

- (NSUInteger)numberOfTabsForViewPager:(ViewPagerController *)viewPager {
    return self.numberOfTabs;
}

- (UIView *)viewPager:(ViewPagerController *)viewPager viewForTabAtIndex:(NSUInteger)index {
    NSArray *titles = @[NSLocalizedString(@"title_news", @"News"), NSLocalizedString(@"title_map", @"Map"), NSLocalizedString(@"title_persons", @"Persons"), NSLocalizedString(@"title_claims", @"Claims")];
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:14.0];
    label.text = titles[index];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    [label sizeToFit];
    
    return label;
}

- (UIViewController *)viewPager:(ViewPagerController *)viewPager contentViewControllerForTabAtIndex:(NSUInteger)index {
    id cvc = _views[index];
    return cvc;
}

- (void)viewPager:(ViewPagerController *)viewPager didChangeTabToIndex:(NSUInteger)index {
    [self setBarButtonItemsForTabBarIndex:index];
}

- (CGFloat)viewPager:(ViewPagerController *)viewPager valueForOption:(ViewPagerOption)option withDefault:(CGFloat)value {
    switch (option) {
        case ViewPagerOptionStartFromSecondTab:
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
    
    _downloadClaims = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_download"] style:UIBarButtonItemStylePlain target:_views[1] action:@selector(downloadClaims:)];
    
    _addPerson = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:_views[2] action:@selector(addPerson:)];
    
    _addClaim = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:_views[3] action:@selector(addClaim:)];
    
    _login = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_login_door"] style:UIBarButtonItemStylePlain target:_views[3] action:@selector(login:)];
    
    _logout = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_logout_door"] style:UIBarButtonItemStylePlain target:_views[3] action:@selector(logout:)];
    
    _menu = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu"] style:UIBarButtonItemStylePlain target:_views[3] action:@selector(showMenu:)];
}

- (void)setBarButtonItemsForTabBarIndex:(NSInteger)index {
    [_menu setTarget:_views[index]];
    switch (index) {
        case 0:
            self.navigationItem.rightBarButtonItems = @[_menu, _flexibleSpace];
            [self setToolbarItems:nil];
            break;

        case 1:
            _myLocation.mapView = [(OTMapViewController *)_views[1] mapView];
            self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, _downloadClaims, _fixedSpace, _myLocation, _flexibleSpace];
            [self setToolbarItems:nil];
            break;
            
        case 2: {
            self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, _addPerson, _flexibleSpace];
            UIBarButtonItem *item = [_views[index] editButtonItem];
            [self setToolbarItems:@[item]];
            break;
        }
        case 3:
            if ([OTAppDelegate authenticated]) {
                self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, _logout, _fixedSpace, _addClaim, _flexibleSpace];
            } else {
                self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, _login, _fixedSpace, _addClaim, _flexibleSpace];
            }
            UIBarButtonItem *item = [_views[index] editButtonItem];
            [self setToolbarItems:@[item]];
            break;
    }
}

@end
