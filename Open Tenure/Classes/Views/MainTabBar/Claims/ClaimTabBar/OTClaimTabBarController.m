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
#import "OTClaimTabBarController.h"
#import "OTMapViewController.h"
#import "OTClaimUpdateViewController.h"
#import "OTDocumentsUpdateViewController.h"
#import "OTAdditionalUpdateViewController.h"
#import "OTAdjacenciesUpdateViewController.h"
#import "OTChallengesUpdateViewController.h"
#import "OTSharesUpdateViewController.h"

@interface OTClaimTabBarController () <ViewPagerDataSource, ViewPagerDelegate>

@property (nonatomic) NSUInteger numberOfTabs;
@property (nonatomic) NSArray *views;

@property (nonatomic) UIBarButtonItem *flexibleSpace;
@property (nonatomic) UIBarButtonItem *fixedSpace;
@property (nonatomic) UIBarButtonItem *save;
@property (nonatomic) UIBarButtonItem *cancel;
@property (nonatomic) UIBarButtonItem *done;
@property (nonatomic) UIBarButtonItem *mapSnapshot;
@property (nonatomic) MKUserTrackingBarButtonItem *myLocation;
@property (nonatomic) UIBarButtonItem *takePhotoDoc;
@property (nonatomic) UIBarButtonItem *attachDoc;
@property (nonatomic) UIBarButtonItem *addAdditionalInfo;
@property (nonatomic) UIBarButtonItem *addShare;

@property (strong, nonatomic) Claim *claim;

@end

@implementation OTClaimTabBarController

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
    
    self.dataSource = self;
    self.delegate = self;
    
    // Keeps tab bar below navigation bar on iOS 7.0+
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    _claim = [Claim getFromTemporary];
    if ([_claim isSaved]) { // View claim
        if ([_claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local claim
            self.title = NSLocalizedString(@"title_edit_claim", @"Edit claim");
        } else { // Readonly claim
            self.title = NSLocalizedString(@"title_claim", @"Claim");
        }
    } else { // Add claim
        self.title = NSLocalizedString(@"title_activity_claim", @"New claim");
    }
    OTClaimUpdateViewController *claim = [OTClaimUpdateViewController new];
    [claim setClaim:_claim];
    OTMapViewController *map = [self.storyboard instantiateViewControllerWithIdentifier:@"Map"];
    [map setClaim:_claim];
    OTDocumentsUpdateViewController *documents = [OTDocumentsUpdateViewController new];
    [documents setClaim:_claim];
    OTAdditionalUpdateViewController *addInfo = [OTAdditionalUpdateViewController new];
    [addInfo setClaim:_claim];
    OTAdjacenciesUpdateViewController *adjacencies = [OTAdjacenciesUpdateViewController new];
    [adjacencies setClaim:_claim];
    OTChallengesUpdateViewController *challenges = [OTChallengesUpdateViewController new];
    [challenges setClaim:_claim];
    OTSharesUpdateViewController *shares = [OTSharesUpdateViewController new];
    [shares setClaim:_claim];
    _views = @[claim, map, documents, addInfo, adjacencies, challenges, shares];
    
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
    NSArray *titles = @[NSLocalizedString(@"title_claim", @"Claim"), NSLocalizedString(@"title_map", @"Map"), NSLocalizedString(@"title_claim_documents", @"Documents"), NSLocalizedString(@"additional_info", @"Additional Information"), NSLocalizedString(@"title_claim_adjacencies", @"Adjacencies"), NSLocalizedString(@"title_claim_challenges", @"Challenges"), NSLocalizedString(@"title_claim_owners", @"Shares")];
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
            return UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? 146.0 : 146.0;
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
 */

- (void)createBarButtonItems {
    
    _flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    _fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    _fixedSpace.width = 22;
    
    _save = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_save"] style:UIBarButtonItemStylePlain target:_views[0] action:@selector(save:)];

    _cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:_views[0] action:@selector(cancel:)];

    _done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:_views[0] action:@selector(done:)];
    
    _mapSnapshot = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:_views[1] action:@selector(mapSnapshot:)];
    
    OTMapViewController *mapViewController = (OTMapViewController *)_views[1];
    _myLocation = [[MKUserTrackingBarButtonItem alloc] initWithMapView:mapViewController.mapView];

    _takePhotoDoc = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:_views[2] action:@selector(takePhotoDoc:)];

    _attachDoc = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_attachment"] style:UIBarButtonItemStylePlain target:_views[2] action:@selector(attachDoc:)];

    _addAdditionalInfo = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:_views[3] action:@selector(addAdditionalInfo:)];
    
    _addShare = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:_views[6] action:@selector(addShare:)];
}

- (void)setBarButtonItemsForTabBarIndex:(NSInteger)index {
    [_save setTarget:_views[index]];
    switch (index) {
        case 0: // Buttons for Claim tab
            if ([_claim isSaved]) { // View claim
                if ([_claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local claim
                    self.navigationItem.rightBarButtonItems = @[_cancel, _fixedSpace, _save, _flexibleSpace];
                } else { // Readonly claim
                    self.navigationItem.rightBarButtonItems = @[_cancel, _flexibleSpace];
                }
            } else { // Add claim
                self.navigationItem.rightBarButtonItems = @[_cancel, _fixedSpace, _save, _flexibleSpace];
            }
            break;
        case 1: // Buttons for Map tab
            _myLocation.mapView = [(OTMapViewController *)_views[1] mapView];
            if ([_claim isSaved]) { // View claim
                if ([_claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local claim
                    self.navigationItem.rightBarButtonItems = @[_mapSnapshot, _fixedSpace, _myLocation, _flexibleSpace];
                } else { // Readonly claim
                    self.navigationItem.rightBarButtonItems = @[_myLocation, _flexibleSpace];
                }
            } else { // Add claim
                self.navigationItem.rightBarButtonItems = @[_mapSnapshot, _fixedSpace, _myLocation, _flexibleSpace];
            }
            break;
        case 2: // Buttons for Documents tab
            if ([_claim isSaved]) { // View claim
                if ([_claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local claim
                    self.navigationItem.rightBarButtonItems = @[_takePhotoDoc, _fixedSpace, _attachDoc, _flexibleSpace];
                } else { // Readonly claim
                    // TODO: Can be edit and save?
                    self.navigationItem.rightBarButtonItems = @[_takePhotoDoc, _fixedSpace, _attachDoc, _flexibleSpace];
                }
            } else { // Add claim
                self.navigationItem.rightBarButtonItems = @[_takePhotoDoc, _fixedSpace, _attachDoc, _flexibleSpace];
            }
            break;
        case 3: // Buttons for Additional Information tab
            if ([_claim isSaved]) { // View claim
                if ([_claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local claim
                    self.navigationItem.rightBarButtonItems = @[_addAdditionalInfo, _flexibleSpace];
                } else { // Readonly claim
                    // TODO: Can be edit and save?
                    self.navigationItem.rightBarButtonItems = @[_flexibleSpace];
                }
            } else { // Add claim
                self.navigationItem.rightBarButtonItems = @[_addAdditionalInfo, _flexibleSpace];
            }
            break;
        case 4: // Buttons for Adjacencies tab
            if ([_claim isSaved]) { // View claim
                if ([_claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local claim
                    self.navigationItem.rightBarButtonItems = @[_flexibleSpace];
                } else { // Readonly claim
                    // TODO: Can be edit and save?
                    self.navigationItem.rightBarButtonItems = @[_flexibleSpace];
                }
            } else { // Add claim
                self.navigationItem.rightBarButtonItems = @[_flexibleSpace];
            }
            break;
        case 5: // Buttons for Challenges tab
            self.navigationItem.rightBarButtonItems = @[_flexibleSpace];
            break;
        case 6: // Buttons for Shares tab
            if ([_claim isSaved]) { // View claim
                if ([_claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local claim
                    self.navigationItem.rightBarButtonItems = @[_addShare, _flexibleSpace];
                } else { // Readonly claim
                    // TODO: Can be edit and save?
                    self.navigationItem.rightBarButtonItems = @[_flexibleSpace];
                }
            } else { // Add claim
                self.navigationItem.rightBarButtonItems = @[_addShare, _flexibleSpace];
            }
            break;
    }
}

@end
