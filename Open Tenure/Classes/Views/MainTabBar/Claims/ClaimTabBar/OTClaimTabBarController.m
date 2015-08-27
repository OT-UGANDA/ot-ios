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
#import "OTAdjacenciesUpdateViewController.h"
#import "OTChallengesUpdateViewController.h"
#import "OTSharesUpdateViewController.h"
#import "OTDynamicFormViewController.h"
#import "OTFormUpdateViewController.h"

@interface OTClaimTabBarController () <ViewPagerDataSource, ViewPagerDelegate>

@property (nonatomic) NSUInteger numberOfTabs;
@property (nonatomic) NSMutableArray *views;

@property (nonatomic) UIBarButtonItem *flexibleSpace;
@property (nonatomic) UIBarButtonItem *fixedSpace;
@property (nonatomic) UIBarButtonItem *save;
@property (nonatomic) UIBarButtonItem *cancel;
@property (nonatomic) UIBarButtonItem *done;
@property (nonatomic) UIBarButtonItem *mapSnapshot;
@property (nonatomic) UIBarButtonItem *addMarker;
@property (nonatomic) MKUserTrackingBarButtonItem *myLocation;
@property (nonatomic) UIBarButtonItem *takePhotoDoc;
@property (nonatomic) UIBarButtonItem *attachDoc;
@property (nonatomic) UIBarButtonItem *addShare;
@property (nonatomic) UIBarButtonItem *print;
@property (nonatomic) UIBarButtonItem *export;
@property (nonatomic) UIBarButtonItem *menu;
@property (nonatomic) UIBarButtonItem *addFormSection;
@property (nonatomic) UIBarButtonItem *zoomToCommunityArea;
@property (nonatomic) UIBarButtonItem *measure;

@property (strong, nonatomic) Claim *claim;

@property (strong, nonatomic) NSMutableArray *titles;

@property (strong, nonatomic) UILabel *claimTabBarLabel;
@property (strong, nonatomic) UILabel *mapTabBarLabel;
@property (strong, nonatomic) UILabel *documentsTabBarLabel;
@property (strong, nonatomic) UILabel *adjacenciesTabBarLabel;
@property (strong, nonatomic) UILabel *challengesTabBarLabel;
@property (strong, nonatomic) UILabel *sharesTabBarLabel;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setTabBarIndex:) name:kSetClaimTabBarIndexNotificationName object:nil];
    
    self.dataSource = self;
    self.delegate = self;
    
    // Keeps tab bar below navigation bar on iOS 7.0+
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    _claim = [Claim getFromTemporary];

    OTClaimUpdateViewController *claim = [OTClaimUpdateViewController new];
    [claim setClaim:_claim];
    OTMapViewController *map = [self.storyboard instantiateViewControllerWithIdentifier:@"Map"];
    [map setClaim:_claim];
    OTDocumentsUpdateViewController *documents = [OTDocumentsUpdateViewController new];
    [documents setClaim:_claim];
    OTAdjacenciesUpdateViewController *adjacencies = [OTAdjacenciesUpdateViewController new];
    [adjacencies setClaim:_claim];
    OTChallengesUpdateViewController *challenges = [OTChallengesUpdateViewController new];
    [challenges setClaim:_claim];
    OTSharesUpdateViewController *shares = [OTSharesUpdateViewController new];
    [shares setClaim:_claim];
    _views = [@[claim, shares, documents, adjacencies, map, challenges] mutableCopy];

    [self createBarButtonItems];
    
    // Load dynamic forms
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"ordering" ascending:YES];
    NSArray *objects = [_claim.dynamicForm.formTemplate.sectionTemplateList sortedArrayUsingDescriptors:@[sortDescriptor]];
    for (SectionTemplate *object in objects) {
        id formView;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sectionTemplate = %@", object];
        SectionPayload *sectionPayload = [[[_claim.dynamicForm.sectionPayloadList allObjects] filteredArrayUsingPredicate:predicate] firstObject];
        if ([object.maxOccurrences integerValue] > 1 ||
            [object.maxOccurrences integerValue] == 0) {
            formView = [OTDynamicFormViewController new];
        } else {
            formView = [OTFormUpdateViewController new];
            SectionElementPayload *sectionElementPayload = [[sectionPayload.sectionElementPayloadList allObjects] firstObject];
            [formView setSectionElementPayload:sectionElementPayload];
        }
        [formView setSectionPayload:sectionPayload];
        [formView setClaim:_claim];
        [formView setTitle:object.displayName];
        [_views addObject:formView];
    }
    
    NSArray *titleArr = @[NSLocalizedString(@"title_claim", @"Claim"), NSLocalizedString(@"title_claim_owners", @"Owners"), NSLocalizedString(@"title_claim_documents", @"Documents"), NSLocalizedString(@"title_claim_adjacencies", @"Adjacencies"), NSLocalizedString(@"title_map", @"Map"), NSLocalizedString(@"title_claim_challenges", @"Challenges")];
    _titles = [titleArr mutableCopy];
    for (SectionTemplate *object in objects) {
        if (object.displayName != nil)
            [_titles addObject:object.displayName];
    }
    [self performSelector:@selector(loadContent) withObject:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
//    if (_claim.getViewType != OTViewTypeView) {
//        BOOL updating = NO;
//        for (SectionPayload *sectionPayload in _claim.dynamicForm.sectionPayloadList) {
//            for (SectionElementPayload *sectionElementPayload in sectionPayload.sectionElementPayloadList) {
//                for (FieldPayload *fieldPayload in sectionElementPayload.fieldPayloadList) {
//                    if ([fieldPayload.fieldTemplate.fieldType isEqualToString:@"TEXT"]) {
//                        BOOL mandatory = NO;
//                        for (FieldConstraint *fieldConstraint in fieldPayload.fieldTemplate.fieldConstraintList)
//                            if ([fieldConstraint.fieldConstraintType isEqualToString:@"NOT_NULL"]) mandatory = YES;
//                        if (mandatory && fieldPayload.stringPayload == nil) {
//                            updating = YES;
//                        }
//                    }
//                }
//            }
//        }
//        if (_claim.mappedGeometry == nil) {
//            _claim.statusCode = kClaimStatusUpdating;
//            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"not_boundary", nil)];
//            [_claim.managedObjectContext save:nil];
//        } else if (updating) {
//            _claim.statusCode = kClaimStatusUpdating;
//            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_error_mandatory_fields", nil)];
//            [_claim.managedObjectContext save:nil];
//        } else {
//            _claim.statusCode = kClaimStatusCreated;
//            [_claim.managedObjectContext save:nil];
//        }
//    }
}

- (void)setTabBarIndex:(NSNotification *)notification {
    NSInteger index = [notification.object integerValue];
    [self selectTabAtIndex:index];
    if (notification.userInfo != nil) {
        if ([[notification.userInfo objectForKey:@"action"] isEqualToString:@"close"]) {
//            NSArray *items0 = @[@{@"type":[NSNumber numberWithInt:0],
//                                  @"target":_newsLabel,
//                                  @"title":@"",
//                                  @"detail":NSLocalizedStringFromTable(@"showcase_actionAlert1_message", @"Showcase", nil)},
//                                @{@"type":[NSNumber numberWithInt:0],
//                                  @"target":[OT findBarButtonItem:_initialization fromNavBar:self.navigationController.navigationBar],
//                                  @"title":@"",
//                                  @"detail":NSLocalizedStringFromTable(@"showcase_actionAlert_message", @"Showcase", nil)}];
//            [_views[newsTabIndex] setShowcaseTargetList:items0];
//            [_views[index] defaultShowcase:notification.userInfo];
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
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:14.0];
    label.text = [[_titles objectAtIndex:index] uppercaseString];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    [label sizeToFit];
    
    switch (index) {
        case 0:
            _claimTabBarLabel = label;
            break;
        case 1:
            _mapTabBarLabel = label;
            break;
        case 2:
            _documentsTabBarLabel = label;
            break;
        case 3:
            _adjacenciesTabBarLabel = label;
            break;
        case 4:
            _challengesTabBarLabel = label;
            break;
        case 5:
            _sharesTabBarLabel = label;
    }
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
            return UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? 96.0 : 96.0;
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
    
    _mapSnapshot = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_snapshot"] style:UIBarButtonItemStylePlain target:_views[4] action:@selector(mapSnapshot:)];
    
    OTMapViewController *mapViewController = (OTMapViewController *)_views[4];
    _myLocation = [[MKUserTrackingBarButtonItem alloc] initWithMapView:mapViewController.mapView];
    
    _addMarker = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:_views[4] action:@selector(addMarker:)];
    
    _takePhotoDoc = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_camera"] style:UIBarButtonItemStylePlain target:_views[2] action:@selector(takePhotoDoc:)];

    _attachDoc = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_attachment"] style:UIBarButtonItemStylePlain target:_views[2] action:@selector(attachDoc:)];

    _addShare = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:_views[1] action:@selector(addShare:)];
    
    _menu = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu"] style:UIBarButtonItemStylePlain target:_views[0] action:@selector(showMenu:)];
    
    _export = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_export"] style:UIBarButtonItemStylePlain target:_views[0] action:@selector(export:)];
    
    _print = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_action_print"] style:UIBarButtonItemStylePlain target:_views[0] action:@selector(print:)];
    
    _addFormSection = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:nil action:@selector(addFormSection:)];

    _zoomToCommunityArea = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_community_area"] style:UIBarButtonItemStylePlain target:_views[4] action:@selector(zoomToCommunityArea:)];

    _measure = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ruler_blue"] style:UIBarButtonItemStylePlain target:_views[4] action:@selector(measureAction:)];
}

- (void)setBarButtonItemsForTabBarIndex:(NSInteger)index {
    NSString *buttonTitle = NSLocalizedString(@"title_activity_claim", nil);
    if ([_claim isSaved])
        buttonTitle = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"app_name", nil), _claim.claimName];

    UIBarButtonItem *logo = [OT logoButtonWithTitle:buttonTitle];
    self.navigationItem.leftBarButtonItems = @[logo];
    
    [_save setTarget:_views[index]];
    [_done setTarget:_views[index]];
    [_menu setTarget:_views[index]];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    NSArray *target;
    switch (index) {
        case 0: { // Buttons for Claim tab
            if ([_claim isSaved]) { // View claim
                if (_claim.getViewType == OTViewTypeEdit) { // Local claim
                    self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, _done, _fixedSpace, _print, _fixedSpace, _save, _flexibleSpace];
                    target = @[[OT findBarButtonItem:_save fromNavBar:navBar],
                               [OT findBarButtonItem:_print fromNavBar:navBar],
                               [OT findBarButtonItem:_done fromNavBar:navBar],
                               [OT findBarButtonItem:_menu fromNavBar:navBar]];
                } else { // Readonly claim
                    self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, _done, _fixedSpace, _print, _flexibleSpace];
                    target = @[[OT findBarButtonItem:_print fromNavBar:navBar],
                               [OT findBarButtonItem:_done fromNavBar:navBar],
                               [OT findBarButtonItem:_menu fromNavBar:navBar]];
                }
            } else { // Add claim
                self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, _cancel, _fixedSpace, _save, _flexibleSpace];
                target = @[[OT findBarButtonItem:_save fromNavBar:navBar],
                           [OT findBarButtonItem:_cancel fromNavBar:navBar],
                           [OT findBarButtonItem:_menu fromNavBar:navBar]];
            }
            
            NSArray *items = @[@{@"type":[NSNumber numberWithInt:0],
                                 @"target":_claimTabBarLabel,
                                 @"title":NSLocalizedStringFromTable(@"showcase_claim_title", @"Showcase", nil),
                                 @"detail":NSLocalizedStringFromTable(@"showcase_claim_message", @"Showcase", nil)},
                               @{@"type":[NSNumber numberWithInt:1],
                                 @"target":target,
                                 @"title":@"",
                                 @"detail":NSLocalizedStringFromTable(@"showcase_actionClaimDetails_message", @"Showcase", nil)}];
            [_views[index] setShowcaseTargetList:items];
            break;
        }
        case 4: { // Buttons for Map tab
            _myLocation.mapView = [(OTMapViewController *)_views[index] mapView];
            [_done setTarget:_views[index]];
            [_zoomToCommunityArea setTarget:_views[index]];
            
            if ([_claim isSaved]) { // View claim
                if (_claim.getViewType == OTViewTypeEdit) { // Local claim
                    self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, _mapSnapshot, _fixedSpace, _zoomToCommunityArea, _fixedSpace, _myLocation, _fixedSpace, _addMarker, _fixedSpace, _measure, _flexibleSpace];
                    target = @[[OT findBarButtonItem:_measure fromNavBar:navBar],
                               [OT findBarButtonItem:_menu fromNavBar:navBar]];
                } else { // Readonly claim
                    self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, _done, _fixedSpace, _zoomToCommunityArea, _fixedSpace, _myLocation, _fixedSpace, _measure, _flexibleSpace];
                    target = @[[OT findBarButtonItem:_measure fromNavBar:navBar], [OT findBarButtonItem:_menu fromNavBar:navBar]];
                }
            } else { // Add claim
                self.navigationItem.rightBarButtonItems = @[_menu, _fixedSpace, _fixedSpace, _mapSnapshot, _fixedSpace, _myLocation, _fixedSpace, _addMarker, _fixedSpace, _measure, _flexibleSpace];
                target = @[[OT findBarButtonItem:_measure fromNavBar:navBar],
                           [OT findBarButtonItem:_menu fromNavBar:navBar]];
            }
            
            NSArray *items = @[@{@"type":[NSNumber numberWithInt:0],
                                 @"target":_mapTabBarLabel,
                                 @"title":NSLocalizedString(@"title_map", @"Community Map"),
                                 @"detail":NSLocalizedStringFromTable(@"showcase_claim_map_message", @"Showcase", nil)},
                               @{@"type":[NSNumber numberWithInt:0],
                                 @"target":[UIView new],
                                 @"title":@"",
                                 @"detail":NSLocalizedStringFromTable(@"showcase_claim_mapdraw_message", @"Showcase", nil)},
                               @{@"type":[NSNumber numberWithInt:1],
                                 @"target":target,
                                 @"title":@"",
                                 @"detail":NSLocalizedStringFromTable(@"showcase_actionClaimMap_message", @"Showcase", nil)}];
            [_views[index] setCustomShowcase:YES];
            [_views[index] setShowcaseTargetList:items];
            break;
        }
        case 2: { // Buttons for Documents tab
            [_done setTarget:_views[index]];
            if ([_claim isSaved]) { // View claim
                if (_claim.getViewType == OTViewTypeEdit) { // Local claim
                    self.navigationItem.rightBarButtonItems = @[_takePhotoDoc, _fixedSpace, _attachDoc, _flexibleSpace];
                    target = @[[OT findBarButtonItem:_attachDoc fromNavBar:navBar],
                               [OT findBarButtonItem:_takePhotoDoc fromNavBar:navBar]];
                } else { // Readonly claim
                    // TODO: Can be edit and save?
                    self.navigationItem.rightBarButtonItems = @[_done, _fixedSpace, _takePhotoDoc, _fixedSpace, _attachDoc, _flexibleSpace];
                    target = @[[OT findBarButtonItem:_attachDoc fromNavBar:navBar],
                               [OT findBarButtonItem:_done fromNavBar:navBar]];
                }
            } else { // Add claim
                self.navigationItem.rightBarButtonItems = @[_takePhotoDoc, _fixedSpace, _attachDoc, _flexibleSpace];
                target = @[[OT findBarButtonItem:_attachDoc fromNavBar:navBar],
                           [OT findBarButtonItem:_takePhotoDoc fromNavBar:navBar]];
            }
            NSArray *items = @[@{@"type":[NSNumber numberWithInt:0],
                                 @"target":_documentsTabBarLabel,
                                 @"title":NSLocalizedString(@"title_claim_documents", nil),
                                 @"detail":NSLocalizedStringFromTable(@"showcase_claim_document_message", @"Showcase", nil)},
                               @{@"type":[NSNumber numberWithInt:1],
                                 @"target":target,
                                 @"title":@"",
                                 @"detail":NSLocalizedStringFromTable(@"showcase_claim_documentAttach_message", @"Showcase", nil)}];
            [_views[index] setShowcaseTargetList:items];
            break;
        }
        case 3: { // Buttons for Adjacencies tab
            [_done setTarget:_views[index]];
            [_save setTarget:_views[0]];
            if ([_claim isSaved]) { // View claim
                if (_claim.getViewType == OTViewTypeEdit) { // Local claim
                    self.navigationItem.rightBarButtonItems = @[_save];
                } else { // Readonly claim
                    // TODO: Can be edit and save?
                    self.navigationItem.rightBarButtonItems = @[_done, _flexibleSpace];
                }
            } else { // Add claim
                self.navigationItem.rightBarButtonItems = @[_save];
            }
            NSArray *items = @[@{@"type":[NSNumber numberWithInt:0],
                                 @"target":_adjacenciesTabBarLabel,
                                 @"title":NSLocalizedString(@"title_claim_adjacencies", nil),
                                 @"detail":NSLocalizedStringFromTable(@"showcase_claim_adjacencies_message", @"Showcase", nil)}];
            [_views[index] setShowcaseTargetList:items];
            break;
        }
        case 5: { // Buttons for Challenges tab
            [_done setTarget:_views[index]];
            if ([_claim isSaved]) { // View claim
                if (_claim.getViewType == OTViewTypeEdit) { // Local claim
                    self.navigationItem.rightBarButtonItems = @[];
                } else { // Readonly claim
                    // TODO: Can be edit and save?
                    self.navigationItem.rightBarButtonItems = @[_done, _flexibleSpace];
                }
            } else { // Add claim
                self.navigationItem.rightBarButtonItems = @[];
            }
            NSArray *items = @[@{@"type":[NSNumber numberWithInt:0],
                                 @"target":_challengesTabBarLabel,
                                 @"title":NSLocalizedString(@"title_claim_challenges", nil),
                                 @"detail":NSLocalizedStringFromTable(@"showcase_claim_challenges_message", @"Showcase", nil)}];
            [_views[index] setShowcaseTargetList:items];
            break;
        }
        case 1: { // Buttons for Shares tab
            [_done setTarget:_views[index]];
            if ([_claim isSaved]) { // View claim
                if (_claim.getViewType == OTViewTypeEdit) { // Local claim
                    self.navigationItem.rightBarButtonItems = @[_addShare, _flexibleSpace];
                } else { // Readonly claim
                    // TODO: Can be edit and save?
                    self.navigationItem.rightBarButtonItems = @[_done, _flexibleSpace];
                }
            } else { // Add claim
                self.navigationItem.rightBarButtonItems = @[_addShare, _flexibleSpace];
            }
            NSArray *items = @[@{@"type":[NSNumber numberWithInt:0],
                                 @"target":_sharesTabBarLabel,
                                 @"title":NSLocalizedString(@"title_claim_owners", nil),
                                 @"detail":NSLocalizedStringFromTable(@"showcase_claim_shares_message", @"Showcase", nil)}];
            [_views[index] setShowcaseTargetList:items];
            break;
        }
        default: // Buttons for Dynamic form
            [_done setTarget:_views[index]];
            [_addFormSection setTarget:_views[index]];
            [_save setTarget:_views[0]];
            if ([_claim isSaved]) { // View claim
                if (_claim.getViewType == OTViewTypeEdit) { // Local claim
                    if ([[[[_views[index] sectionPayload] sectionTemplate] maxOccurrences] integerValue] > 1 ||
                        [[[[_views[index] sectionPayload] sectionTemplate] maxOccurrences] integerValue] == 0)
                        self.navigationItem.rightBarButtonItems = @[_addFormSection, _flexibleSpace];
                    else
                        self.navigationItem.rightBarButtonItems = @[_save, _flexibleSpace];
                } else { // Readonly claim
                    // TODO: Can be edit and save?
                    self.navigationItem.rightBarButtonItems = @[_done, _flexibleSpace];
                }
            } else { // Add claim
                if ([[[[_views[index] sectionPayload] sectionTemplate] maxOccurrences] integerValue] > 1 ||
                    [[[[_views[index] sectionPayload] sectionTemplate] maxOccurrences] integerValue] == 0)
                    self.navigationItem.rightBarButtonItems = @[_addFormSection, _flexibleSpace];
                else
                    self.navigationItem.rightBarButtonItems = @[_save, _flexibleSpace];
            }
            break;
    }
}

@end
