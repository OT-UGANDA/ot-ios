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

#import "OTClaimUpdateViewController.h"
#import "OTFormInfoCell.h"
#import "OTFormInputTextFieldCell.h"
#import "PickerView.h"
#import "OTSelectionTabBarViewController.h"

@interface OTClaimUpdateViewController () <OTSelectionTabBarViewControllerDelegate>

@property (nonatomic, strong) PickerView *pickerView;
@property (nonatomic, strong) NSArray *claimTypeCollection;
@property (nonatomic, strong) NSArray *landUseCollection;

@property (nonatomic, strong) NSMutableArray *claimTypeDisplayValye;
@property (nonatomic, strong) NSMutableArray *landUseDisplayValue;

@property (nonatomic, strong) __block OTFormInputTextFieldCell *claimantBlock;
@property (nonatomic, strong) __block OTFormInputTextFieldCell *challengedBlock;
@property (assign) OTViewType viewType;

@end

@implementation OTClaimUpdateViewController

- (void)setupView {
    _pickerView = [[PickerView alloc] init];
    [_pickerView setDateFormat:[[OT dateFormatter] dateFormat]];
    [_pickerView setShouldHideOnSelection:YES];
    
    ClaimTypeEntity *claimTypeEntity = [ClaimTypeEntity new];
    [claimTypeEntity setManagedObjectContext:_claim.managedObjectContext];
    _claimTypeCollection = [claimTypeEntity getCollection];
    
    _claimTypeDisplayValye = [NSMutableArray array];
    for (ClaimType *object in _claimTypeCollection) {
        [_claimTypeDisplayValye addObject:object.displayValue];
    }
    
    LandUseEntity *landUseEntity = [LandUseEntity new];
    [landUseEntity setManagedObjectContext:_claim.managedObjectContext];
    _landUseCollection = [landUseEntity getCollection];
    _landUseDisplayValue = [NSMutableArray array];
    for (LandUse *object in _landUseCollection) {
        [_landUseDisplayValue addObject:object.displayValue];
    }
    
    // Dùng để view claim và person sử dụng context khi ở trạng thái select
    [_claim setToTemporary];

    self.viewType = _claim.getViewType;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
    
    NSInteger customCellHeight = 40.0f;
    
    [self setHeaderTitle:NSLocalizedString(@"claim_name_label", nil) forSection:0];
    OTFormInputTextFieldCell *claimName =
    [[OTFormInputTextFieldCell alloc] initWithText:_claim.claimName
                                       placeholder:NSLocalizedString(@"claim_name", nil)
                                          delegate:self
                                         mandatory:YES
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeAlphabet
                                          viewType:self.viewType];
    claimName.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (inText.length > 0) {
            inCell.validationState = BPFormValidationStateValid;
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
                _claim.claimName = inText;
        } else {
            inCell.validationState = BPFormValidationStateInvalid;
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_fields", nil);
            inCell.shouldShowInfoCell = YES;
        }
    };
    if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
        [claimName.textField becomeFirstResponder];
    claimName.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    
    // Claim Type
    [self setHeaderTitle:NSLocalizedString(@"claim_type", nil) forSection:1];
    OTFormInputTextFieldCell *claimType =
    [[OTFormInputTextFieldCell alloc] initWithText:_claim.claimType.displayValue
                                       placeholder:NSLocalizedString(@"claim_type", nil)
                                          delegate:self
                                         mandatory:YES
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeAlphabet
                                          viewType:self.viewType];
    
    __block OTFormInputTextFieldCell *claimTypeBlock = claimType;
    claimType.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        if (inText.length > 0) {
            inCell.validationState = BPFormValidationStateValid;
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(displayValue == %@)", inText];
                ClaimType *claimType = [[_claimTypeCollection filteredArrayUsingPredicate:predicate] firstObject];
                _claim.claimType = claimType;
            }
            [_pickerView detach];
        } else {
            inCell.validationState = BPFormValidationStateInvalid;
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_fields", nil);
            inCell.shouldShowInfoCell = YES;
            [_pickerView detach];
        }
    };
    claimType.didBeginEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        [_pickerView setPickType:PickTypeList];
        [_pickerView setPickItems:_claimTypeDisplayValye];
        [_pickerView attachWithTextField:claimTypeBlock.textField];
        [_pickerView showPopOverList];
    };
    claimType.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
        inCell.validationState = BPFormValidationStateNone;
        // Disable typing
        return NO;
    };

    // Land Use
    [self setHeaderTitle:NSLocalizedString(@"land_use", nil) forSection:2];
    OTFormInputTextFieldCell *landUse =
    [[OTFormInputTextFieldCell alloc] initWithText:_claim.landUse.displayValue
                                       placeholder:NSLocalizedString(@"land_use", nil)
                                          delegate:self
                                         mandatory:YES
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeAlphabet
                                          viewType:self.viewType];
    __block OTFormInputTextFieldCell *landUseBlock = landUse;
    landUse.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (inText.length > 0) {
            inCell.validationState = BPFormValidationStateValid;
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(displayValue == %@)", inText];
                LandUse *landUse = [[_landUseCollection filteredArrayUsingPredicate:predicate] firstObject];
                if (landUse != nil)
                    _claim.landUse = landUse;
            }
            [_pickerView detach];
        } else {
            inCell.validationState = BPFormValidationStateInvalid;
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_fields", nil);
            inCell.shouldShowInfoCell = YES;
            [_pickerView detach];
        }
    };
    landUse.didBeginEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        inCell.validationState = BPFormValidationStateNone;
        [_pickerView setPickType:PickTypeList];
        [_pickerView setPickItems:_landUseDisplayValue];
        [_pickerView attachWithTextField:landUseBlock.textField];
        [_pickerView showPopOverList];
    };
    landUse.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
        // Disable typing
        return NO;
    };

    // Date of right's start (YYYY-MM-DD)
    [self setHeaderTitle:NSLocalizedString(@"date_of_start_label", nil) forSection:3];
    OTFormInputTextFieldCell *startDate =
    [[OTFormInputTextFieldCell alloc] initWithText:_claim.startDate
                                       placeholder:NSLocalizedString(@"date_of_start", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeDecimalPad
                                          viewType:self.viewType];
    __block OTFormInputTextFieldCell *startDateBlock = startDate;
    startDate.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        NSDate *date = [[OT dateFormatter] dateFromString:inText];
        if (date != nil && inText.length > 0) {
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
                _claim.startDate = inText;
        }
        else {
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_startdate", nil);
            inCell.shouldShowInfoCell = YES;
        }
        [_pickerView detach];
    };
    startDate.didBeginEditingBlock =  ^void(BPFormInputCell *inCell, NSString *inText){
        [_pickerView attachWithTextField:startDateBlock.textField];
        [_pickerView setPickType:PickTypeDate];
        [_pickerView showPopOverList];
    };
    startDate.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
        [_pickerView matchDate:inText];
        return YES;
    };
    
    // Claim notes
    [self setHeaderTitle:NSLocalizedString(@"claim_notes", nil) forSection:4];
    OTFormInputTextFieldCell *claimNotes =
    [[OTFormInputTextFieldCell alloc] initWithText:_claim.notes
                                       placeholder:NSLocalizedString(@"insert_claim_notes", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeDefault
                                          viewType:self.viewType];
    claimNotes.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _claim.notes = inText;
    };
    
    // Select person
    [self setHeaderTitle:NSLocalizedString(@"claimant", nil) forSection:5];
    OTFormInputTextFieldCell *claimant =
    [[OTFormInputTextFieldCell alloc] initWithText:[_claim.person fullNameType:OTFullNameTypeDefault]
                                       placeholder:NSLocalizedString(@"message_touch_to_select_a_person", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeDefault
                                          viewType:self.viewType];
    _claimantBlock = claimant;
    claimant.didBeginEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:OTPersonSelectionAction] forKey:@"OTSelectionAction"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        OTAppDelegate* appDelegate = (OTAppDelegate*)[[UIApplication sharedApplication] delegate];
        id main = appDelegate.window.rootViewController;
        OTSelectionTabBarViewController *selectionViewController = (OTSelectionTabBarViewController *)[[main storyboard] instantiateViewControllerWithIdentifier:@"SelectionTabBarDetail"];
        selectionViewController.selectionDelegate = self;
        
        UINavigationController *nav = [[main storyboard] instantiateViewControllerWithIdentifier:@"SelectionTabBar"];
        nav = [nav initWithRootViewController:selectionViewController];
        
        if (nav != nil) {
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        }
    };
    claimant.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText){
        return NO;
    };
    claimant.infoCell.label.text = @"string";
    claimant.shouldShowValidation = YES;

    // Select challenged to claim
    [self setHeaderTitle:NSLocalizedString(@"challenge_to", nil) forSection:6];
    OTFormInputTextFieldCell *challenged =
    [[OTFormInputTextFieldCell alloc] initWithText:_claim.challenged.claimName
                                       placeholder:NSLocalizedString(@"message_touch_to_select_a_claim", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeDefault
                                          viewType:self.viewType];
    _challengedBlock = challenged;
    challenged.didBeginEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:OTClaimSelectionAction] forKey:@"OTSelectionAction"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        OTAppDelegate* appDelegate = (OTAppDelegate*)[[UIApplication sharedApplication] delegate];
        id main = appDelegate.window.rootViewController;
        OTSelectionTabBarViewController *selectionViewController = (OTSelectionTabBarViewController *)[[main storyboard] instantiateViewControllerWithIdentifier:@"SelectionTabBarDetail"];
        selectionViewController.selectionDelegate = self;
        
        UINavigationController *nav = [[main storyboard] instantiateViewControllerWithIdentifier:@"SelectionTabBar"];
        nav = [nav initWithRootViewController:selectionViewController];
        
        if (nav != nil) {
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        }
    };
    challenged.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText){
        return NO;
    };
    
    self.formCells = @[@[claimName], @[claimType], @[landUse], @[startDate], @[claimNotes], @[claimant], @[challenged]];
    
    self.customSectionHeaderHeight = 20;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma Bar Buttons Action
- (void)showInvalidCell:(OTFormInputTextFieldCell *)cell {
    allCellChecked = true;
    [cell.textField becomeFirstResponder];
    [cell.textField resignFirstResponder];
}

- (void)checkInvalidCell {
    NSInteger i = 0;
    while (i < self.formCells.count) {
        for (OTFormInputTextFieldCell *cell in self.formCells[i]) {
            if (cell.validationState == BPFormValidationStateInvalid && cell != _claimantBlock) {
                [self performSelector:@selector(showInvalidCell:) withObject:cell afterDelay:3];
            }
        }
        i++;
    }
}

static bool allCellChecked = false;
- (IBAction)save:(id)sender {
    if (self.allCellsAreValid) {
        if (_claim.person == nil) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_unable_to_save_missing_person", nil)];
        } else if ([_claim.managedObjectContext hasChanges]) {
            [FileSystemUtilities createClaimFolder:_claim.claimId];
            [_claim.managedObjectContext save:nil];
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"message_saved", nil)];
            [self setupView];
            [self.tableView reloadData];
        }
    } else {
        if (!allCellChecked) [self checkInvalidCell];
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_error_mandatory_fields", nil)];
    }
}

- (IBAction)cancel:(id)sender {
    if (![_claim isSaved]) {
        [self.navigationController dismissViewControllerAnimated:NO completion:^{
            [_claim.managedObjectContext deleteObject:_claim];
        }];
    } else {
        if ([_claim.managedObjectContext hasChanges] && (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)) {
            [UIAlertView showWithTitle:NSLocalizedString(@"title_save_dialog", nil) message:NSLocalizedString(@"message_save_dialog", nil) style:UIAlertViewStyleDefault cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"action_save", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex == 1) {
                    [self.navigationController dismissViewControllerAnimated:NO completion:^{
                        [self save:nil];
                    }];
                } else {
                    [self.navigationController dismissViewControllerAnimated:NO completion:^{
                        [self performSelector:@selector(rollback) withObject:nil afterDelay:0];
                    }];
                }
                
            }];
        } else {
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
        }
    }
    
}

- (IBAction)done:(id)sender {
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}

- (void)rollback {
    [_claim.managedObjectContext rollback];
}

#pragma OTSelectionTabBarViewControllerDelegate methods

- (void)personSelection:(OTSelectionTabBarViewController *)controller didSelectPerson:(Person *)person {
    _claim.person = person;
    _claimantBlock.textField.text = [person fullNameType:OTFullNameTypeDefault];
    _claimantBlock.validationState = BPFormValidationStateValid;
    
    ShareEntity *shareEntity = [ShareEntity new];
    [shareEntity setManagedObjectContext:_claim.managedObjectContext];
    Share *share = [shareEntity create];
    share.shareId = [[[NSUUID UUID] UUIDString] lowercaseString];
    [share addOwnersObject:[person clone]];
    share.denominator = [NSNumber numberWithInteger:100];
    share.nominator = [NSNumber numberWithInteger:100];
    share.claim = _claim;
    
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)claimSelection:(OTSelectionTabBarViewController *)controller didSelelectClaim:(Claim *)claim {
    _claim.challenged = claim;
    _challengedBlock.textField.text = claim.claimName;
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
