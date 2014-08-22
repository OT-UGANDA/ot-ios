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

#import "OTPersonUpdateViewController.h"
#import "OTFormInfoCell.h"
#import "OTFormInputTextFieldCell.h"
#import "PickerView.h"

@interface OTPersonUpdateViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) PickerView *pickerView;

@property (nonatomic, strong) NSArray *idTypeCollection;
@property (nonatomic, strong) NSMutableArray *idTypeDisplayValue;
@property (nonatomic, strong) UIImageView *personImageView;
@property (assign) OTViewType viewType;

@end

@implementation OTPersonUpdateViewController

- (void)setupView {
    _pickerView = [[PickerView alloc] init];
    [_pickerView setDateFormat:[[OT dateFormatter] dateFormat]];
    [_pickerView setShouldHideOnSelection:YES];
    
    IdTypeEntity *idTypeEntity = [IdTypeEntity new];
    [idTypeEntity setManagedObjectContext:_person.managedObjectContext];
    _idTypeCollection = [idTypeEntity getCollection];
    
    _idTypeDisplayValue = [NSMutableArray array];
    for (IdType *object in _idTypeCollection) {
        [_idTypeDisplayValue addObject:object.displayValue];
    }

    if ([_person isSaved]) { // View person/group
        if (_person.claim == nil || [_person.claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local person/group
            if (_person.personType == kPersonTypeGroup) { // Local group
                self.viewType = OTViewTypeEdit;
            } else { // Local person
                self.viewType = OTViewTypeEdit;
            }
        } else { // Readonly person/group
            if (_person.personType == kPersonTypeGroup) { // Readonly group
                self.viewType = OTViewTypeView;
            } else { // Readonly person
                self.viewType = OTViewTypeView;
            }
        }
    } else { // Add person/group
        if (_person.personType == kPersonTypeGroup) { // Add group
            self.viewType = OTViewTypeAdd;
        } else { // Add person
            self.viewType = OTViewTypeAdd;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
    
    CGFloat imageWith = 72;
    CGFloat cellSpace = 15;
    CGRect rect = CGRectMake(self.view.frame.size.width - imageWith - cellSpace, 5, imageWith, imageWith);
    UIView *headerView = [[UIView alloc] initWithFrame:rect];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showImagePickerAlert:)];
    singleTap.numberOfTapsRequired = 1;
    [imageView addGestureRecognizer:singleTap];
    imageView.userInteractionEnabled = YES;
    NSLog(@"%@", _person.personId);
    NSString *imageFile = [FileSystemUtilities getClaimantImagePath:_person.personId];
    UIImage *personPicture = [UIImage imageWithContentsOfFile:imageFile];
    if (personPicture == nil) personPicture = [UIImage imageNamed:@"ic_person_picture"];
    imageView.image = personPicture;
    imageView.backgroundColor = [UIColor whiteColor];
    _personImageView = imageView;
    [headerView addSubview:imageView];
    self.tableView.tableHeaderView = headerView;
    
    if ([_person isSaved]) { // View person/group
        if (_person.claim == nil || [_person.claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local person/group
            if (_person.personType == kPersonTypeGroup) { // Local group
                self.formCells = [self groupFormCellsEditable:YES];
            } else { // Local person
                self.formCells = [self personFormCellsEditable:YES];
            }
        } else { // Readonly person/group
            if (_person.personType == kPersonTypeGroup) { // Readonly group
                self.formCells = [self groupFormCellsEditable:NO];
            } else { // Readonly person
                self.formCells = [self personFormCellsEditable:NO];
            }
        }
    } else { // Add person/group
        if (_person.personType == kPersonTypeGroup) { // Add group
            self.formCells = [self groupFormCellsEditable:YES];
        } else { // Add person
            self.formCells = [self personFormCellsEditable:YES];
        }
    }
    
    self.customSectionHeaderHeight = 20;
}

- (NSArray *)groupFormCellsEditable:(BOOL)editable {
    NSInteger customCellHeight = 40.0f;
    
    [self setHeaderTitle:NSLocalizedString(@"group_name", nil) forSection:0];
    OTFormInputTextFieldCell *firstName =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.firstName
                                       placeholder:NSLocalizedString(@"group_name", nil)
                                          delegate:self
                                         mandatory:YES
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeAlphabet
                                          viewType:self.viewType];
    firstName.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (inText.length > 0) {
            inCell.validationState = BPFormValidationStateValid;
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
                _person.firstName = inText;
        } else {
            inCell.validationState = BPFormValidationStateInvalid;
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_field_first_name", nil);
            inCell.shouldShowInfoCell = YES;
        }
    };
    if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
        [firstName.textField becomeFirstResponder];
    firstName.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    [self setHeaderTitle:NSLocalizedString(@"date_of_establishment_label", nil) forSection:1];
    OTFormInputTextFieldCell *dateOfBirth =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.dateOfBirth
                                       placeholder:NSLocalizedString(@"date_of_establishment_label", nil)
                                          delegate:self
                                         mandatory:YES
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                          viewType:self.viewType];
    
    __block OTFormInputTextFieldCell *dateOfBirthBlock = dateOfBirth;
    dateOfBirth.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        [[OT dateFormatter] setTimeZone:gmt];
        NSDate *date = [[OT dateFormatter] dateFromString:inText];
        if (date != nil) {
            inCell.validationState = BPFormValidationStateValid;
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
                _person.dateOfBirth = inText;
        }
        else {
            inCell.validationState = BPFormValidationStateInvalid;
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_birthdate", nil);
            inCell.shouldShowInfoCell = YES;
        }
        [_pickerView detach];
    };
    // Hiện DatePicker khi bắt đầu edit (bắt buộc)
    dateOfBirth.didBeginEditingBlock =  ^void(BPFormInputCell *inCell, NSString *inText){
        inCell.validationState = BPFormValidationStateNone;
        // Xác định vùng hiển thị popover
        [_pickerView attachWithTextField:dateOfBirthBlock.textField];
        // Đặt kiểu ngày giờ cho DatePicker
        [_pickerView setPickType:PickTypeDate];
        // Đặt ngày cho DatePicker theo dữ liệu hiện tại (nên)
        [_pickerView matchDate:dateOfBirthBlock.textField.text];
        // Hiện popover
        [_pickerView showPopOverList];
    };
    // Đặt ngày ngược lại cho DatePicker khi nhập liệu bằng bàn phím (tùy chọn)
    dateOfBirth.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
        [_pickerView matchDate:inText];
        return YES;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"id_number", nil) forSection:2];
    OTFormInputTextFieldCell *idNumber =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.idNumber
                                       placeholder:NSLocalizedString(@"id_number", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeDefault
                                          viewType:self.viewType];
    idNumber.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.idNumber = inText;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"postal_address", nil) forSection:3];
    OTFormInputTextFieldCell *postalAddress =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.postalAddress
                                       placeholder:NSLocalizedString(@"postal_address", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeDefault
                                          viewType:self.viewType];
    postalAddress.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.postalAddress = inText;
    };
    postalAddress.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    
    [self setHeaderTitle:NSLocalizedString(@"email_address", nil) forSection:4];
    OTFormInputTextFieldCell *emailAddress =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.postalAddress
                                       placeholder:NSLocalizedString(@"email_address", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeEmailAddress
                                          viewType:self.viewType];
    emailAddress.shouldChangeTextBlock = BPValidateBlockWithPatternAndMessage(@"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", @"The email should look like name@provider.domain");
    emailAddress.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.emailAddress = inText;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"mobile_phone_number", nil) forSection:5];
    OTFormInputTextFieldCell *mobilePhoneNumber =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.mobilePhoneNumber
                                       placeholder:NSLocalizedString(@"mobile_phone_number", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                          viewType:self.viewType];
    mobilePhoneNumber.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.mobilePhoneNumber = inText;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"contact_phone_number", nil) forSection:6];
    OTFormInputTextFieldCell *contactPhoneNumber =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.contactPhoneNumber
                                       placeholder:NSLocalizedString(@"contact_phone_number", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                          viewType:self.viewType];
    contactPhoneNumber.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.contactPhoneNumber = inText;
    };
    
    return @[@[firstName], @[dateOfBirth], @[idNumber], @[postalAddress], @[emailAddress], @[mobilePhoneNumber], @[contactPhoneNumber]];
}

- (NSArray *)personFormCellsEditable:(BOOL)editable {
    NSInteger customCellHeight = 40.0f;
    [self setHeaderTitle:NSLocalizedString(@"first_name", nil) forSection:0];
    OTFormInputTextFieldCell *firstName =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.firstName
                                       placeholder:NSLocalizedString(@"first_name", nil)
                                          delegate:self
                                         mandatory:YES
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeAlphabet
                                          viewType:self.viewType];
    firstName.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (inText.length > 0) {
            inCell.validationState = BPFormValidationStateValid;
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
                _person.firstName = inText;
        } else {
            inCell.validationState = BPFormValidationStateInvalid;
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_field_first_name", nil);
            inCell.shouldShowInfoCell = YES;
        }
    };
    if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
        [firstName.textField becomeFirstResponder];
    firstName.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;

    [self setHeaderTitle:NSLocalizedString(@"last_name", nil) forSection:1];
    OTFormInputTextFieldCell *lastName =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.lastName
                                       placeholder:NSLocalizedString(@"last_name", nil)
                                          delegate:self
                                         mandatory:YES
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeAlphabet
                                          viewType:self.viewType];
    lastName.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (inText.length > 0) {
            inCell.validationState = BPFormValidationStateValid;
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
                _person.lastName = inText;
        } else {
            inCell.validationState = BPFormValidationStateInvalid;
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_field_last_name", nil);
            inCell.shouldShowInfoCell = YES;
        }
    };
    lastName.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    [self setHeaderTitle:NSLocalizedString(@"date_of_birth_label", nil) forSection:2];
    OTFormInputTextFieldCell *dateOfBirth =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.dateOfBirth
                                       placeholder:NSLocalizedString(@"date_of_birth", nil)
                                          delegate:self
                                         mandatory:YES
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                          viewType:self.viewType];
    
    __block OTFormInputTextFieldCell *dateOfBirthBlock = dateOfBirth;
    dateOfBirth.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        [[OT dateFormatter] setTimeZone:gmt];
        NSDate *date = [[OT dateFormatter] dateFromString:inText];
        if (date != nil) {
            inCell.validationState = BPFormValidationStateValid;
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
                _person.dateOfBirth = inText;
        }
        else {
            inCell.validationState = BPFormValidationStateInvalid;
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_birthdate", nil);
            inCell.shouldShowInfoCell = YES;
        }
        [_pickerView detach];
    };
    // Hiện DatePicker khi bắt đầu edit (bắt buộc)
    dateOfBirth.didBeginEditingBlock =  ^void(BPFormInputCell *inCell, NSString *inText){
        // Xác định vùng hiển thị popover
        [_pickerView attachWithTextField:dateOfBirthBlock.textField];
        // Đặt kiểu ngày giờ cho DatePicker
        [_pickerView setPickType:PickTypeDate];
        // Đặt ngày cho DatePicker theo dữ liệu hiện tại (nên)
        [_pickerView matchDate:dateOfBirthBlock.textField.text];
        // Hiện popover
        [_pickerView showPopOverList];
    };
    // Đặt ngày ngược lại cho DatePicker khi nhập liệu bằng bàn phím (tùy chọn)
    dateOfBirth.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
        [_pickerView matchDate:inText];
        return YES;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"gender", nil) forSection:3];
    OTFormInputTextFieldCell *gender =
    [[OTFormInputTextFieldCell alloc] initWithText:NSLocalizedString(_person.gender, nil)
                                       placeholder:NSLocalizedString(@"gender", nil)
                                          delegate:self
                                         mandatory:YES
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeDefault
                                          viewType:self.viewType];
    __block OTFormInputTextFieldCell *genderBlock = gender;
    gender.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        if (inText.length > 0) {
            inCell.validationState = BPFormValidationStateValid;
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit) {
                if ([inText isEqualToString:NSLocalizedString(@"male", nil)])
                    _person.gender = @"male";
                else
                    _person.gender = @"female";
            }
            [_pickerView detach];
        } else {
            inCell.validationState = BPFormValidationStateInvalid;
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_field_gender", nil);
            inCell.shouldShowInfoCell = YES;
        }
    };
    gender.didBeginEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        genderBlock.validationState = BPFormValidationStateNone;
        NSArray *genders = @[NSLocalizedString(@"male", nil),
                             NSLocalizedString(@"female", nil)];
        [_pickerView setPickType:PickTypeList];
        [_pickerView setPickItems:genders];
        [_pickerView attachWithTextField:genderBlock.textField];
        [_pickerView showPopOverList];
    };
    gender.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
        // Disable typing
        return NO;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"id_type", nil) forSection:4];
    OTFormInputTextFieldCell *idType =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.idType.displayValue
                                       placeholder:NSLocalizedString(@"id_type", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeDefault
                                          viewType:self.viewType];
    
    __block OTFormInputTextFieldCell *idTypeBlock = idType;
    idType.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(displayValue == %@)", inText];
            IdType *idType = [[_idTypeCollection filteredArrayUsingPredicate:predicate] firstObject];
            _person.idType = idType;
        }
        [_pickerView detach];
    };
    idType.didBeginEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        inCell.validationState = BPFormValidationStateNone;
        [_pickerView setPickType:PickTypeList];
        [_pickerView setPickItems:_idTypeDisplayValue];
        [_pickerView attachWithTextField:idTypeBlock.textField];
        [_pickerView showPopOverList];
    };
    idType.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
        // Disable typing
        return NO;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"id_number", nil) forSection:5];
    OTFormInputTextFieldCell *idNumber =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.idNumber
                                       placeholder:NSLocalizedString(@"id_number", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                          viewType:self.viewType];
    idNumber.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.idNumber = inText;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"postal_address", nil) forSection:6];
    OTFormInputTextFieldCell *postalAddress =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.postalAddress
                                       placeholder:NSLocalizedString(@"postal_address", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeDefault
                                          viewType:self.viewType];
    postalAddress.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.postalAddress = inText;
    };
    postalAddress.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    
    [self setHeaderTitle:NSLocalizedString(@"email_address", nil) forSection:7];
    OTFormInputTextFieldCell *emailAddress =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.postalAddress
                                       placeholder:NSLocalizedString(@"email_address", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeEmailAddress
                                          viewType:self.viewType];
    emailAddress.shouldChangeTextBlock = BPValidateBlockWithPatternAndMessage(@"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", @"The email should look like name@provider.domain");
    emailAddress.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.emailAddress = inText;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"mobile_phone_number", nil) forSection:8];
    OTFormInputTextFieldCell *mobilePhoneNumber =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.mobilePhoneNumber
                                       placeholder:NSLocalizedString(@"mobile_phone_number", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                          viewType:self.viewType];
    mobilePhoneNumber.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.mobilePhoneNumber = inText;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"contact_phone_number", nil) forSection:9];
    OTFormInputTextFieldCell *contactPhoneNumber =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.contactPhoneNumber
                                       placeholder:NSLocalizedString(@"contact_phone_number", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                          viewType:self.viewType];
    contactPhoneNumber.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.contactPhoneNumber = inText;
    };
        
    return @[@[firstName], @[lastName], @[dateOfBirth], @[gender], @[idType], @[idNumber], @[postalAddress], @[emailAddress], @[mobilePhoneNumber], @[contactPhoneNumber]];
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
            if (cell.validationState == BPFormValidationStateInvalid) {
                [self performSelector:@selector(showInvalidCell:) withObject:cell afterDelay:3];
            }
        }
        i++;
    }
}

static bool allCellChecked = false;
- (IBAction)save:(id)sender {
    if (self.allCellsAreValid) {
        if ([_person.managedObjectContext hasChanges]) {
            [FileSystemUtilities createClaimantFolder:_person.personId];
            [_person.managedObjectContext save:nil];
            [self setupView];
            [self.tableView reloadData];
        }
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"message_saved", nil)];
    } else {
        if (!allCellChecked) [self checkInvalidCell];
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_error_mandatory_fields", nil)];
    }
}

- (IBAction)cancel:(id)sender {
    if (![_person isSaved]) {
        [self.navigationController dismissViewControllerAnimated:NO completion:^{
            [_person.managedObjectContext deleteObject:_person];
        }];
    } else {
        if ([_person.managedObjectContext hasChanges] &&
            (_person.claim == nil || [_person.claim.statusCode isEqualToString:kClaimStatusCreated])) {
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
    [_person.managedObjectContext rollback];
}

#pragma mark ActionSheet

- (IBAction)showImagePickerAlert:(id)sender {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.delegate = self;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [UIActionSheet showFromRect:[[sender view] frame] inView:self.view animated:YES withTitle:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"Select from photo library", nil), NSLocalizedString(@"Take new picture", nil)] tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
            if (buttonIndex == [actionSheet cancelButtonIndex]) return;
            if (buttonIndex == 0) {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            } else {
                if (TARGET_IPHONE_SIMULATOR) return;
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                imagePickerController.showsCameraControls = YES;
                imagePickerController.videoQuality = UIImagePickerControllerQualityTypeMedium;
                imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
                imagePickerController.cameraDevice= UIImagePickerControllerCameraDeviceRear;
                imagePickerController.navigationBarHidden = NO;
                
            }
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }];
    } else {
        [UIActionSheet showFromToolbar:self.navigationController.toolbar withTitle:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"Select from photo library", nil), NSLocalizedString(@"Take new picture", nil)] tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
            if (buttonIndex == [actionSheet cancelButtonIndex]) return;
            if (buttonIndex == 0) {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            } else {
                if (TARGET_IPHONE_SIMULATOR) return;
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                imagePickerController.showsCameraControls = YES;
                imagePickerController.videoQuality = UIImagePickerControllerQualityTypeMedium;
                imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
                imagePickerController.cameraDevice= UIImagePickerControllerCameraDeviceRear;
                imagePickerController.navigationBarHidden = NO;
                
            }
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }];
    }
}

#pragma mark UIImagePickerViewControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (!selectedImage) return;
        
        // Create a thumbnail version of the image for the recipe object.
        CGFloat newSize = 150.0;
        CGSize size = selectedImage.size;
        CGFloat ratio = (size.width > size.height) ? newSize / size.width : newSize / size.height;
        CGRect rect = CGRectMake(0.0, 0.0, ratio * size.width, ratio * size.height);
        
        UIGraphicsBeginImageContext(rect.size);
        [selectedImage drawInRect:rect];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        _personImageView.image = newImage;
        
        NSString *imageFile = [FileSystemUtilities getClaimantImagePath:_person.personId];
        NSData *imageData = UIImageJPEGRepresentation(newImage, 1.0);
        [imageData writeToFile:imageFile atomically:YES];
    }];
}


@end
