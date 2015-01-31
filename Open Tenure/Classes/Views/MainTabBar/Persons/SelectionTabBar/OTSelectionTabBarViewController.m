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

#import "OTSelectionTabBarViewController.h"
#import "OTClaimsViewController.h"
#import "OTShareUpdateViewController.h"

@interface OTSelectionTabBarViewController () <ViewPagerDataSource, ViewPagerDelegate, OTClaimsViewControllerDelegate>

@property (nonatomic) NSUInteger numberOfTabs;
@property (nonatomic) NSArray *views;

@property (nonatomic) UIBarButtonItem *flexibleSpace;
@property (nonatomic) UIBarButtonItem *fixedSpace;
@property (nonatomic) UIBarButtonItem *addPerson;
@property (nonatomic) UIBarButtonItem *cancel;
@property (nonatomic) UIBarButtonItem *save;

@property (nonatomic) OTSelectionAction selectionAction;

@end

@implementation OTSelectionTabBarViewController

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
    
    // Get view type
    _selectionAction = [[NSUserDefaults standardUserDefaults] integerForKey:@"OTSelectionAction"];
    
    self.dataSource = self;
    self.delegate = self;
    
    // Keeps tab bar below navigation bar on iOS 7.0+
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    // Set title and view
    switch (_selectionAction) {
        case OTClaimSelectionAction: {
            OTClaimsViewController *claimsViewController = (OTClaimsViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"Claims"];
            claimsViewController.delegate = self;
            _views = @[claimsViewController];
            break;
        }
        case OTShareViewDetail: {
            OTShareUpdateViewController *shareUpdateviewController = (OTShareUpdateViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"Share"];
            _views = @[shareUpdateviewController];
            break;
        }
    }
    
    [self createBarButtonItems];
    
    [self performSelector:@selector(loadContent) withObject:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
    
    NSArray *titles;
    
    switch (_selectionAction) {
        case OTClaimSelectionAction:
            titles = @[NSLocalizedString(@"title_claims", @"Claims")];
            break;
        case OTShareViewDetail:
            titles = @[NSLocalizedString(@"title_activity_share_details", nil)];
            break;
    }
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:14.0];
    label.text = [titles[index] uppercaseString];
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
            return UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? 128.0 : 128.0;
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
    
    _addPerson = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:_views[0] action:@selector(addPerson:)];
    
    _save = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_save"] style:UIBarButtonItemStylePlain target:_views[0] action:@selector(save:)];

    _cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:_views[0] action:@selector(cancel:)];
}

- (void)setBarButtonItemsForTabBarIndex:(NSInteger)index {
    NSArray *titles;
    
    switch (_selectionAction) {
        case OTClaimSelectionAction:
            titles = @[NSLocalizedString(@"title_claims", @"Claims")];
            break;
        case OTShareViewDetail:
            titles = @[NSLocalizedString(@"title_activity_share_details", nil)];
            break;
    }
    
    NSString *buttonTitle = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"app_name", nil), titles[index]];
    UIBarButtonItem *logo = [OT logoButtonWithTitle:buttonTitle];
    self.navigationItem.leftBarButtonItems = @[logo];
    
    switch (index) {
        case 0:
            switch (_selectionAction) {
                case OTClaimSelectionAction: {
                    self.navigationItem.rightBarButtonItems = @[_cancel, _flexibleSpace];
                    break;
                }
                case OTShareViewDetail: {
                    if ([[[Claim getFromTemporary] statusCode] isEqualToString:kClaimStatusCreated]) {
                        self.navigationItem.rightBarButtonItems = @[_cancel, _flexibleSpace];
                    } else {
                        self.navigationItem.rightBarButtonItems = @[_cancel, _flexibleSpace];
                    }
                    break;
                }
            }
            break;
    }
}

#pragma OTClaimViewControllerDelegate method

- (void)claimSelection:(OTClaimsViewController *)controller didSelectClaim:(Claim *)claim {
    [_selectionDelegate claimSelection:self didSelelectClaim:claim];
}

@end
