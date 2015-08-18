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
#import "OTFormCell.h"
#import "UIImage+OT.h"

@interface OTPersonUpdateViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPickerViewDelegate>

@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIDatePicker *datePicker;

@property (nonatomic, strong) NSArray *idTypeCollection;
@property (nonatomic, strong) NSDictionary *idTypes;
@property (nonatomic, strong) UIImageView *personImageView;

@property (nonatomic, strong) __block OTFormCell *dateOfBirthBlock;
@property (nonatomic, strong) __block OTFormCell *genderBlock;
@property (nonatomic, strong) __block OTFormCell *idTypeBlock;

@property (nonatomic, strong) UIView *pickerViewBackground;

@property (nonatomic, assign, getter=isPickerGenderShowing) BOOL pickerGenderShowing;
@property (nonatomic, assign, getter=isPickerIdTypeShowing) BOOL pickerIdTypeShowing;
@property (nonatomic, assign, getter=isDatePickerShowing) BOOL datePickerShowing;

@property (nonatomic, strong) IBOutlet UIImagePickerController *imagePickerController;

@property (assign) OTViewType viewType;

@end

@implementation OTPersonUpdateViewController

- (void)setupView {
    IdTypeEntity *idTypeEntity = [IdTypeEntity new];
    NSArray *entities= [idTypeEntity getCollectionWithProperties:@[@"code", @"displayValue"]];
    NSArray *codes = [entities valueForKeyPath:@"code"];
    NSArray *displayValues = [entities valueForKeyPath:@"displayValue"];
    _idTypes = [NSDictionary dictionaryWithObjects:displayValues forKeys:codes];
    
    if ([_person isSaved]) { // View person/group
        if (_person.owner != nil)
            self.viewType = _person.owner.claim.getViewType;
        else
            self.viewType = _person.claim.getViewType;
    } else { // Add person/group
        self.viewType = OTViewTypeAdd;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *singleTouch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
    singleTouch.numberOfTapsRequired = 1;
    [self.tableView addGestureRecognizer:singleTouch];

    [self setupView];

    CGFloat imageWith = 72;
    CGFloat cellSpace = 15;
    CGRect rect = CGRectMake(self.view.frame.size.width - imageWith - cellSpace, 5, imageWith, imageWith);
    UIView *headerView = [[UIView alloc] initWithFrame:rect];
    rect.origin.x = -cellSpace;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
    imageView.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showImagePickerAlert:)];
    singleTap.numberOfTapsRequired = 1;
    [imageView addGestureRecognizer:singleTap];
    imageView.userInteractionEnabled = YES;
    
    UIImage *personPicture = [UIImage imageWithContentsOfFile:[_person getFullPath]];
    if (personPicture == nil) personPicture = [UIImage imageNamed:@"ic_person_picture"];
    imageView.image = personPicture;
    imageView.backgroundColor = [UIColor clearColor];
    _personImageView = imageView;
    [headerView addSubview:imageView];
    self.tableView.tableHeaderView = headerView;
    
    if ([_person isSaved]) { // View person/group
        if (_person.claim == nil || [_person.claim.statusCode isEqualToString:kClaimStatusCreated]) { // Local person/group
            if (![_person.person boolValue]) { // Local group
                self.formCells = [self groupFormCellsEditable:YES];
            } else { // Local person
                self.formCells = [self personFormCellsEditable:YES];
            }
        } else { // Readonly person/group
            if (![_person.person boolValue]) { // Readonly group
                self.formCells = [self groupFormCellsEditable:NO];
            } else { // Readonly person
                self.formCells = [self personFormCellsEditable:NO];
            }
        }
    } else { // Add person/group
        if (![_person.person boolValue]) { // Add group
            self.formCells = [self groupFormCellsEditable:YES];
        } else { // Add person
            self.formCells = [self personFormCellsEditable:YES];
        }
    }
    self.customSectionHeaderHeight = 16;
    self.customSectionFooterHeight = 8;
}

//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    if (_person.getViewType != OTViewTypeView && self.allCellsAreValid) {
//        [self checkInvalidCell];
//    }
//}
- (IBAction)singleTapAction:(id)sender {
    [self hidePickers];
}

- (NSArray *)groupFormCellsEditable:(BOOL)editable {
    NSInteger customCellHeight = 32.0f;
    // Group name
    [self setHeaderTitle:NSLocalizedString(@"group_name", nil) forSection:0];
    OTFormInputTextFieldCell *firstName =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.name
                                       placeholder:NSLocalizedString(@"group_name", nil)
                                          delegate:self
                                         mandatory:YES
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeAlphabet
                                          viewType:self.viewType];
    if (self.viewType != OTViewTypeView)
        [firstName.textField becomeFirstResponder];
    firstName.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    firstName.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
        if (inText.length > 0) {
            inCell.validationState = BPFormValidationStateValid;
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
                _person.name = inText;
        } else {
            inCell.validationState = BPFormValidationStateInvalid;
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_field_first_name", nil);
            inCell.shouldShowInfoCell = YES;
        }
        return YES;
    };
    
    // DateOfBirth
    [self setHeaderTitle:NSLocalizedString(@"date_of_establishment_label", nil) forSection:1];
    if (_person.birthDate == nil)
        _person.birthDate = [[[OT dateFormatter] stringFromDate:[NSDate date]] substringToIndex:10];
    
    OTFormCell *dateOfBirth = [[OTFormCell alloc] initWithFrame:CGRectZero];
    _dateOfBirthBlock = dateOfBirth;
    
    UITapGestureRecognizer *dateOfBirthTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(datePickerShow:)];
    dateOfBirthTapped.numberOfTapsRequired = 1;
    
    NSString *dateOfBirthTitle = [_person.birthDate substringToIndex:10];
    
    dateOfBirth.selectionStyle = UITableViewCellSelectionStyleNone;
    dateOfBirth.imageView.image = [UIImage imageNamed:@"ic_action_datepicker"];
    dateOfBirth.textLabel.attributedText = [OT getAttributedStringFromText:dateOfBirthTitle];
    dateOfBirth.imageView.userInteractionEnabled = YES;
    [dateOfBirth.imageView addGestureRecognizer:dateOfBirthTapped];

    // IdNumber
    [self setHeaderTitle:NSLocalizedString(@"id_number", nil) forSection:2];
    OTFormInputTextFieldCell *idNumber =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.idNumber
                                       placeholder:NSLocalizedString(@"id_number", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeDefault
                                          viewType:self.viewType];
    idNumber.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit) {
            _person.idNumber = inText;
            return YES;
        } else return NO;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"postal_address", nil) forSection:3];
    OTFormInputTextFieldCell *postalAddress =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.address
                                       placeholder:NSLocalizedString(@"postal_address", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeDefault
                                          viewType:self.viewType];
    postalAddress.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    postalAddress.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit) {
            _person.address = inText;
            return YES;
        } else return NO;
    };

    [self setHeaderTitle:NSLocalizedString(@"email_address", nil) forSection:4];
    OTFormInputTextFieldCell *emailAddress =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.email
                                       placeholder:NSLocalizedString(@"email_address", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeEmailAddress
                                          viewType:self.viewType];
    emailAddress.shouldChangeTextBlock = BPValidateBlockWithPatternAndMessage(@"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", @"The email should look like name@provider.domain");
    emailAddress.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.email = inText;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"mobile_phone_number", nil) forSection:5];
    OTFormInputTextFieldCell *mobilePhoneNumber =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.mobilePhone
                                       placeholder:NSLocalizedString(@"mobile_phone_number", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                          viewType:self.viewType];
    mobilePhoneNumber.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.mobilePhone = inText;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"contact_phone_number", nil) forSection:6];
    OTFormInputTextFieldCell *contactPhoneNumber =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.phone
                                       placeholder:NSLocalizedString(@"contact_phone_number", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                          viewType:self.viewType];
    contactPhoneNumber.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.phone = inText;
    };

    dateOfBirth.customCellHeight = customCellHeight;
    return @[@[firstName], @[dateOfBirth], @[idNumber], @[postalAddress], @[emailAddress], @[mobilePhoneNumber], @[contactPhoneNumber]];
}


- (NSArray *)personFormCellsEditable:(BOOL)editable {
    NSInteger customCellHeight = 32.0f;
    [self setHeaderTitle:NSLocalizedString(@"first_name", nil) forSection:0];
    OTFormInputTextFieldCell *firstName =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.name
                                       placeholder:NSLocalizedString(@"first_name", nil)
                                          delegate:self
                                         mandatory:YES
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeAlphabet
                                          viewType:self.viewType];
    firstName.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText){
        if (inText.length > 0) {
            inCell.validationState = BPFormValidationStateValid;
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
                _person.name = inText;
        } else {
            inCell.validationState = BPFormValidationStateInvalid;
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_field_first_name", nil);
            inCell.shouldShowInfoCell = YES;
        }
        return YES;
    };
    firstName.didBeginEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
    
    };
    
    if (self.viewType != OTViewTypeView)
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
    lastName.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText){
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
        return YES;
    };
    lastName.didBeginEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        
    };

    lastName.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    [self setHeaderTitle:NSLocalizedString(@"date_of_birth_label", nil) forSection:2];
    if (_person.birthDate == nil)
        _person.birthDate = [[[OT dateFormatter] stringFromDate:[NSDate date]] substringToIndex:10];
    
    OTFormCell *dateOfBirth = [[OTFormCell alloc] initWithFrame:CGRectZero];
    _dateOfBirthBlock = dateOfBirth;
    
    UITapGestureRecognizer *dateOfBirthTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(datePickerShow:)];
    dateOfBirthTapped.numberOfTapsRequired = 1;
    
    NSString *dateOfBirthTitle = [_person.birthDate substringToIndex:10];
    
    dateOfBirth.selectionStyle = UITableViewCellSelectionStyleNone;
    dateOfBirth.imageView.image = [UIImage imageNamed:@"ic_action_datepicker"];
    dateOfBirth.textLabel.attributedText = [OT getAttributedStringFromText:dateOfBirthTitle];
    dateOfBirth.imageView.userInteractionEnabled = YES;
    [dateOfBirth.imageView addGestureRecognizer:dateOfBirthTapped];
    
    // Gender
    [self setHeaderTitle:NSLocalizedString(@"gender", nil) forSection:3];
    if (_person.genderCode == nil)
        _person.genderCode = @"male";
    
    OTFormCell *gender = [[OTFormCell alloc] initWithFrame:CGRectZero];
    _genderBlock = gender;
    
    UITapGestureRecognizer *genderTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerGenderShow:)];
    genderTapped.numberOfTapsRequired = 1;
    
    NSString *genderTitle = NSLocalizedString(_person.genderCode, nil);
    
    gender.selectionStyle = UITableViewCellSelectionStyleNone;
    gender.imageView.image = [UIImage imageNamed:@"ic_action_picker"];
    gender.textLabel.attributedText = [OT getAttributedStringFromText:genderTitle];
    gender.imageView.userInteractionEnabled = YES;
    [gender.imageView addGestureRecognizer:genderTapped];
    
    // IdType
    [self setHeaderTitle:NSLocalizedString(@"id_type", nil) forSection:4];
    if (_person.idTypeCode == nil) {
        NSString *idTypeCode = [[_idTypes allKeys] firstObject];
        _person.idTypeCode = idTypeCode;
    }
    
    OTFormCell *idType = [[OTFormCell alloc] initWithFrame:CGRectZero];
    _idTypeBlock = idType;
    
    UITapGestureRecognizer *idTypeTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerIdTypeShow:)];
    idTypeTapped.numberOfTapsRequired = 1;
    
    NSString *idTypeTitle = [_idTypes valueForKey:_person.idTypeCode];
    
    idType.selectionStyle = UITableViewCellSelectionStyleNone;
    idType.imageView.image = [UIImage imageNamed:@"ic_action_picker"];
    idType.textLabel.attributedText = [OT getAttributedStringFromText:idTypeTitle];
    idType.imageView.userInteractionEnabled = YES;
    [idType.imageView addGestureRecognizer:idTypeTapped];
    
    // IdNumber
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
    [[OTFormInputTextFieldCell alloc] initWithText:_person.address
                                       placeholder:NSLocalizedString(@"postal_address", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeDefault
                                          viewType:self.viewType];
    postalAddress.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.address = inText;
    };
    postalAddress.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    
    [self setHeaderTitle:NSLocalizedString(@"email_address", nil) forSection:7];
    OTFormInputTextFieldCell *emailAddress =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.address
                                       placeholder:NSLocalizedString(@"email_address", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeEmailAddress
                                          viewType:self.viewType];
    emailAddress.shouldChangeTextBlock = BPValidateBlockWithPatternAndMessage(@"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", @"The email should look like name@provider.domain");
    emailAddress.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.email = inText;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"mobile_phone_number", nil) forSection:8];
    OTFormInputTextFieldCell *mobilePhoneNumber =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.mobilePhone
                                       placeholder:NSLocalizedString(@"mobile_phone_number", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                          viewType:self.viewType];
    mobilePhoneNumber.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.mobilePhone = inText;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"contact_phone_number", nil) forSection:9];
    OTFormInputTextFieldCell *contactPhoneNumber =
    [[OTFormInputTextFieldCell alloc] initWithText:_person.phone
                                       placeholder:NSLocalizedString(@"contact_phone_number", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                          viewType:self.viewType];
    contactPhoneNumber.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _person.phone = inText;
    };
    
    dateOfBirth.customCellHeight = customCellHeight;
    gender.customCellHeight = customCellHeight;
    idType.customCellHeight = customCellHeight;
    return @[@[firstName], @[lastName], @[dateOfBirth], @[gender], @[idType], @[idNumber], @[postalAddress], @[emailAddress], @[mobilePhoneNumber], @[contactPhoneNumber]];
}

- (IBAction)datePickerShow:(UIGestureRecognizer *)sender {
    if (self.viewType == OTViewTypeView) return;
    if (![self isPickerGenderShowing] && ![self isPickerIdTypeShowing] && ![self isDatePickerShowing]) {
        [self dismissKeyboard];
        CGRect frame = _dateOfBirthBlock.textLabel.frame;
        
        _pickerViewBackground = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, _dateOfBirthBlock.frame.origin.y + _dateOfBirthBlock.frame.size.height, frame.size.width, 150)];
        _pickerViewBackground.layer.borderColor = [[UIColor otGreen] CGColor];
        _pickerViewBackground.layer.borderWidth = 1;
        _pickerViewBackground.layer.cornerRadius = 4.0f;
        _pickerViewBackground.backgroundColor = [UIColor whiteColor];
        _pickerViewBackground.alpha = 0.95;
        
        _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 150)];
        _datePickerShowing = YES;
        [_datePicker setDatePickerMode:UIDatePickerModeDate];
        [_datePicker addTarget:self action:@selector(datePickerChanged:) forControlEvents:UIControlEventValueChanged];
        
        // Đặt ngày của datePicker theo ngày của field
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];
        NSString *dateText = [_dateOfBirthBlock.textLabel.text substringToIndex:10];
        NSDate *date = [dateFormatter dateFromString:dateText];
        if (date != nil)
            [_datePicker setDate:date];
        
        [_pickerViewBackground addSubview:_datePicker];
        [_dateOfBirthBlock.superview.superview addSubview:_pickerViewBackground];
    } else if ([self isPickerGenderShowing])
        [self pickerGenderDone:nil];
    else if ([self isPickerIdTypeShowing])
        [self pickerIdTypeDone:nil];
    else if ([self isDatePickerShowing])
        [self datePickerDone:nil];
}

- (IBAction)datePickerDone:(id)sender {
    [_pickerViewBackground removeFromSuperview];
    _datePickerShowing = NO;
}

- (IBAction)pickerGenderShow:(UIGestureRecognizer *)sender {
    if (self.viewType == OTViewTypeView) return;
    if (![self isPickerGenderShowing] && ![self isPickerIdTypeShowing] && ![self isDatePickerShowing]) {
        [self dismissKeyboard];
        CGRect frame = _genderBlock.textLabel.frame;
        
        _pickerViewBackground = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, _genderBlock.frame.origin.y + _genderBlock.frame.size.height, frame.size.width, 150)];
        _pickerViewBackground.layer.borderColor = [[UIColor otGreen] CGColor];
        _pickerViewBackground.layer.borderWidth = 1;
        _pickerViewBackground.layer.cornerRadius = 4.0f;
        _pickerViewBackground.backgroundColor = [UIColor whiteColor];
        _pickerViewBackground.alpha = 0.95;
        
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 150)];
        _pickerView.delegate = self;
        _pickerGenderShowing = YES;
        [_pickerView reloadAllComponents];
        
        NSArray *genders = @[@"male", @"female"];
        
        for (int i = 0; i < genders.count; i++) {
            if ([_person.genderCode isEqualToString:genders[i]])
                [_pickerView selectRow:i inComponent:0 animated:YES];
        }
        
        [_pickerViewBackground addSubview:_pickerView];
        [_genderBlock.superview.superview addSubview:_pickerViewBackground];
    } else [self hidePickers];
}

- (IBAction)pickerGenderDone:(id)sender {
    [_pickerViewBackground removeFromSuperview];
    _pickerGenderShowing = NO;
}

- (IBAction)pickerIdTypeShow:(UIGestureRecognizer *)sender {
    if (self.viewType == OTViewTypeView) return;
    if (![self isPickerGenderShowing] && ![self isPickerIdTypeShowing] && ![self isDatePickerShowing]) {
        [self dismissKeyboard];
        CGRect frame = _idTypeBlock.textLabel.frame;
        
        _pickerViewBackground = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, _idTypeBlock.frame.origin.y + _idTypeBlock.frame.size.height, frame.size.width, 150)];
        _pickerViewBackground.layer.borderColor = [[UIColor otGreen] CGColor];
        _pickerViewBackground.layer.borderWidth = 1;
        _pickerViewBackground.layer.cornerRadius = 4.0f;
        _pickerViewBackground.backgroundColor = [UIColor whiteColor];
        _pickerViewBackground.alpha = 0.95;
        
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 150)];
        _pickerView.delegate = self;
        _pickerIdTypeShowing = YES;
        [_pickerView reloadAllComponents];
        
        NSArray *options = [_idTypes allKeys];
        
        for (int i = 0; i < options.count; i++) {
            if ([_person.idTypeCode isEqualToString:options[i]])
                [_pickerView selectRow:i inComponent:0 animated:YES];
        }
        
        [_pickerViewBackground addSubview:_pickerView];
        [_idTypeBlock.superview.superview addSubview:_pickerViewBackground];
    } else [self hidePickers];
}

- (IBAction)pickerIdTypeDone:(id)sender {
    [_pickerViewBackground removeFromSuperview];
    _pickerIdTypeShowing = NO;
}

- (void)hidePickers {
    if ([self isPickerGenderShowing])
        [self pickerGenderDone:nil];
    else if ([self isPickerIdTypeShowing])
        [self pickerIdTypeDone:nil];
    else
        [self datePickerDone:nil];
}

- (void)dismissKeyboard {
    for (id cells in self.formCells) {
        for (id cell in cells) {
            if ([cell isKindOfClass:[BPFormInputTextFieldCell class]]) {
                [[cell textField] resignFirstResponder];
            }
        }
    }
}

#pragma handle UIDatePicker method

- (IBAction)datePickerChanged:(UIDatePicker *)sender {
    NSString *dateString = [[[OT dateFormatter] stringFromDate:[sender date]] substringToIndex:10];
    _dateOfBirthBlock.textLabel.attributedText = [OT getAttributedStringFromText:dateString];
    _person.birthDate = dateString;
}

#pragma mark - UIPickerViewDelegate methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    if ([self isPickerGenderShowing]) {
        NSArray *options = @[@"male", @"female"];
        
        _person.genderCode = options[row];
        
        NSArray *displayOptions = @[NSLocalizedString(@"male", nil), NSLocalizedString(@"female", nil)];
        
        _genderBlock.textLabel.attributedText = [OT getAttributedStringFromText:displayOptions[row]];
    } else if ([self isPickerIdTypeShowing]) {
        NSString *idTypeDisplayValue = [[_idTypes allValues] objectAtIndex:row];
        NSString *idTypeCode = [[_idTypes allKeys] objectAtIndex:row];
        _person.idTypeCode = idTypeCode;
        _idTypeBlock.textLabel.attributedText = [OT getAttributedStringFromText:idTypeDisplayValue];
    }
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if ([self isPickerGenderShowing])
        return 2;
    else
        return [[_idTypes allKeys] count];
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title;
    NSArray *options;
    if ([self isPickerGenderShowing]) {
        options = @[NSLocalizedString(@"male", nil), NSLocalizedString(@"female", nil)];
    } else {
        options = [_idTypes allValues];
    }
    title = [options objectAtIndex:row];
    
    return title;
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
                [self performSelector:@selector(showInvalidCell:) withObject:cell afterDelay:0.3];
            }
        }
        i++;
    }
}

- (void)updateShare {
    if (_person.claim.shares.count != 0 || _person.claim == nil) return;
    ShareEntity *shareEntity = [ShareEntity new];
    [shareEntity setManagedObjectContext:_person.claim.managedObjectContext];
    Share *share = [shareEntity create];
    share.shareId = [[[NSUUID UUID] UUIDString] lowercaseString];
    [share addOwnersObject:[_person clone]];
    share.denominator = [NSNumber numberWithInteger:100];
    share.nominator = [NSNumber numberWithInteger:100];
    share.claim = _person.claim;
}

static bool allCellChecked = false;
- (IBAction)save:(id)sender {
    if (self.allCellsAreValid) {
        if ([_person.managedObjectContext hasChanges]) {
            [self updateShare];
            [_person.managedObjectContext save:nil];
            [self setupView];
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
            if (_person.owner != nil)
                [_person.owner removeOwnersObject:_person];
            if (_person.claim != nil)
                _person.claim = nil;
            [_person.managedObjectContext deleteObject:_person];
        }];
    } else {
        if ([_person.managedObjectContext hasChanges] &&
            (_person.claim == nil || [_person.claim.statusCode isEqualToString:kClaimStatusCreated])) {
            [UIAlertView showWithTitle:NSLocalizedStringFromTable(@"title_save_dialog", @"Additional", nil) message:NSLocalizedStringFromTable(@"message_save_dialog", @"Additional", nil) style:UIAlertViewStyleDefault cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"action_save", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
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
    if (_person.getViewType == OTViewTypeView)
        [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    else {
        if (_person.name != nil) {
            if (self.allCellsAreValid) {
                [self.navigationController dismissViewControllerAnimated:NO completion:^{
                    //[self save:nil];
                }];
            } else {
                if (!allCellChecked) [self checkInvalidCell];
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_error_mandatory_fields", nil)];
            }
        } else {
            if (!allCellChecked) [self checkInvalidCell];
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_error_mandatory_fields", nil)];
        }
    }
}

- (void)rollback {
    [_person.managedObjectContext rollback];
}

#pragma mark ActionSheet

- (IBAction)showImagePickerAlert:(id)sender {
    Claim *claim;
    if (_person.claim != nil) { // Claimant
        claim = _person.claim;
    } else { // owner
        claim = _person.owner.claim;
    }
    
    if (![claim canBeUploaded]) {
        return;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [UIActionSheet showFromRect:[[sender view] frame] inView:self.view animated:YES withTitle:nil cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[NSLocalizedStringFromTable(@"from_photo_library", @"Additional", nil), NSLocalizedStringFromTable(@"take_new_photo", @"Additional", nil)] tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
            
            UIImagePickerController *picker = [UIImagePickerController new];
            picker.modalPresentationStyle = UIModalPresentationCurrentContext;
            picker.delegate = self;
            picker.navigationBarHidden = NO;

            if (buttonIndex == [actionSheet cancelButtonIndex]) return;
            if (buttonIndex == 0) {
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            } else {
                if (TARGET_IPHONE_SIMULATOR) return;
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                picker.showsCameraControls = YES;
                picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
                picker.cameraDevice= UIImagePickerControllerCameraDeviceRear;
            }
            self.imagePickerController = picker;
            dispatch_async(dispatch_get_main_queue(), ^{ // Fixed for Xcode 6, iOS 8
                [self presentViewController:self.imagePickerController animated:YES completion:nil];
            });
        }];
    } else {
        [UIActionSheet showFromToolbar:self.navigationController.toolbar withTitle:nil cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[NSLocalizedStringFromTable(@"from_photo_library", @"Additional", nil), NSLocalizedStringFromTable(@"take_new_photo", @"Additional", nil)] tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
            
            UIImagePickerController *picker = [UIImagePickerController new];
            picker.delegate = self;
            picker.navigationBarHidden = NO;

            if (buttonIndex == [actionSheet cancelButtonIndex]) return;
            if (buttonIndex == 0) {
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            } else {
                if (TARGET_IPHONE_SIMULATOR) return;
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                picker.showsCameraControls = YES;
                picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
                picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
                picker.cameraDevice= UIImagePickerControllerCameraDeviceRear;
            }
            self.imagePickerController = picker;
            dispatch_async(dispatch_get_main_queue(), ^{ // Fixed for Xcode 6, iOS 8
                [self presentViewController:self.imagePickerController animated:YES completion:nil];
            });
        }];
    }
}

#pragma mark UIImagePickerViewControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (!selectedImage) return;
    
    // Create squared image
    CGFloat width = selectedImage.size.width < selectedImage.size.height ? selectedImage.size.width : selectedImage.size.height;
    UIImage *newImage = [selectedImage cropToSize:CGSizeMake(width, width)];
    
    // Create a thumbnail version of the image for the recipe object.
    CGSize newSize = CGSizeMake(320.0, 320.0);
    newImage = [newImage changeToSize:newSize];
    _personImageView.image = newImage;

    BOOL isUpdate = [[NSFileManager defaultManager] fileExistsAtPath:[_person getFullPath]];
    ALog(@"%tu", isUpdate);
    
    // Update or Create new photo
    NSData *imageData = UIImageJPEGRepresentation(newImage, 1.0);
    [imageData writeToFile:[_person getFullPath] atomically:YES];
    NSNumber *fileSize = [NSNumber numberWithUnsignedInteger:imageData.length];
    NSString *md5 = [imageData md5];
    
    if (_person.claim != nil) { // claimant
        Attachment *attachment;
        if (isUpdate) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(typeCode.code == %@)", @"personPhoto"];
            NSSet *personObjects = [_person.claim.attachments filteredSetUsingPredicate:predicate];
            
            for (Attachment *att in personObjects) {
                if ([att.fileName isEqualToString:[_person getFullPath]]) {
                    attachment = att;
                    break;
                }
            }
        }
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(code == %@)", @"personPhoto"];
        
        // Nạp lại sau khi claim đã save
        DocumentTypeEntity *docTypeEntity = [DocumentTypeEntity new];
        [docTypeEntity setManagedObjectContext:_person.managedObjectContext];
        NSArray *docTypeCollection = [docTypeEntity getCollection];
        DocumentType *docType = [[docTypeCollection filteredArrayUsingPredicate:predicate] firstObject];

        if (attachment == nil) {
            AttachmentEntity *attachmentEntity = [AttachmentEntity new];
            [attachmentEntity setManagedObjectContext:_person.managedObjectContext];
            attachment = [attachmentEntity create];
            attachment.claim = _person.claim;
            attachment.typeCode = docType;
            attachment.attachmentId = [[[NSUUID UUID] UUIDString] lowercaseString];
            attachment.statusCode = kAttachmentStatusCreated;
        }
        attachment.documentDate = [[[OT dateFormatter] stringFromDate:[NSDate date]] substringToIndex:10];
        attachment.mimeType = @"image/jpg";
        attachment.fileName = [_person.personId stringByAppendingPathExtension:@"jpg"];
        attachment.fileExtension = @"jpg";
        attachment.size = [fileSize stringValue];
        attachment.md5 = md5;
        attachment.note = docType.displayValue;
        [attachment.managedObjectContext save:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"saved", nil)];
        });
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}



@end
