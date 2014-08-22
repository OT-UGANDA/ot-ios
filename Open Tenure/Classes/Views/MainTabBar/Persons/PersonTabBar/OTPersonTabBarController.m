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

#import "OTPersonTabBarController.h"
#import "CommunityServerAPI.h"
#import "OTPersonUpdateViewController.h"
#import "OTPersonsViewController.h"
#import "Person+OT.h"

@interface OTPersonTabBarController () <ViewPagerDataSource, ViewPagerDelegate>

@property (nonatomic) NSUInteger numberOfTabs;
@property (nonatomic) NSArray *views;

@property (nonatomic) UIBarButtonItem *flexibleSpace;
@property (nonatomic) UIBarButtonItem *fixedSpace;
@property (nonatomic) UIBarButtonItem *save;
@property (nonatomic) UIBarButtonItem *cancel;
@property (nonatomic) UIBarButtonItem *done;

@property (strong, nonatomic) Person *person;

@end

@implementation OTPersonTabBarController

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
    
    _person = [Person getFromTemporary];
    NSLog(@"%@", [_person.managedObjectContext description]);

    self.dataSource = self;
    self.delegate = self;
    
    // Keeps tab bar below navigation bar on iOS 7.0+
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // Set title and view
    if ([_person isSaved]) { // View person/group
        if (_person.claim == nil || [_person.claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local person/group
            if (_person.personType == kPersonTypeGroup) { // Local group
                self.title = NSLocalizedString(@"title_group_details", @"Group Detail");
            } else { // Local person
                self.title = NSLocalizedString(@"title_person_details", @"Person Detail");
            }
        } else { // Readonly person/group
            if (_person.personType == kPersonTypeGroup) { // Readonly group
                self.title = NSLocalizedString(@"title_group_details", @"Group Detail");
            } else { // Readonly person
                self.title = NSLocalizedString(@"title_person_details", @"Person Detail");
            }
        }
    } else { // Add person/group
        if (_person.personType == kPersonTypeGroup) { // Add group
            self.title = NSLocalizedString(@"title_activity_group", @"New group");
        } else { // Add person
            self.title = NSLocalizedString(@"title_activity_person", @"New person");
        }
    }
    
    OTPersonUpdateViewController *personViewController = [OTPersonUpdateViewController new];
    [personViewController setPerson:_person];
    _views = @[personViewController];
    
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
    if ([_person isSaved]) { // View person/group
        if (_person.claim == nil || [_person.claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local person/group
            if (_person.personType == kPersonTypeGroup) { // Local group
                titles = @[NSLocalizedString(@"title_group_details", @"Group Detail")];
            } else { // Local person
                titles = @[NSLocalizedString(@"title_person_details", @"Person Detail")];
            }
        } else { // Readonly person/group
            if (_person.personType == kPersonTypeGroup) { // Readonly group
                titles = @[NSLocalizedString(@"title_group_details", @"Group Detail")];
            } else { // Readonly person
                titles = @[NSLocalizedString(@"title_person_details", @"Person Detail")];;
            }
        }
    } else { // Add person/group
        if (_person.personType == kPersonTypeGroup) { // Add group
            titles = @[NSLocalizedString(@"title_activity_group", @"New group")];
        } else { // Add person
            titles = @[NSLocalizedString(@"title_activity_person", @"New person")];
        }
    }

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
    
    _save = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_save"] style:UIBarButtonItemStylePlain target:_views[0] action:@selector(save:)];
    
    _cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:_views[0] action:@selector(cancel:)];
    
    _done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:_views[0] action:@selector(done:)];
    
}

- (void)setBarButtonItemsForTabBarIndex:(NSInteger)index {
    switch (index) {
        case 0:
            if ([_person isSaved]) { // View person/group
                if (_person.claim == nil || [_person.claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local person/group
                    if (_person.personType == kPersonTypeGroup) { // Local group
                        self.navigationItem.rightBarButtonItems = @[_cancel, _fixedSpace, _save, _flexibleSpace];
                    } else { // Local person
                        self.navigationItem.rightBarButtonItems = @[_cancel, _fixedSpace, _save, _flexibleSpace];
                    }
                } else { // Readonly person/group
                    if (_person.personType == kPersonTypeGroup) { // Readonly group
                        self.navigationItem.rightBarButtonItems = @[_cancel, _flexibleSpace];
                    } else { // Readonly person
                        self.navigationItem.rightBarButtonItems = @[_cancel, _flexibleSpace];
                    }
                }
            } else { // Add person/group
                if (_person.personType == kPersonTypeGroup) { // Add group
                    self.navigationItem.rightBarButtonItems = @[_cancel, _fixedSpace, _save, _flexibleSpace];
                } else { // Add person
                    self.navigationItem.rightBarButtonItems = @[_cancel, _fixedSpace, _save, _flexibleSpace];
                }
            }
    }
}

@end
