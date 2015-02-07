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

#import "OTFormUpdateViewController.h"
#import "OTFormInputTextFieldCell.h"
#import "OTFormInfoCell.h"
#import "OTFormButtonCell.h"
#import "OTFormCell.h"
#import "OTFormSwitchCell.h"

@interface OTFormUpdateViewController () <UIPickerViewDelegate>

//@property (assign) OTViewType viewType;
@property (nonatomic, strong) NSMutableArray *switchFields;
@property (nonatomic, strong) NSMutableArray *dateFields;
@property (nonatomic, strong) NSMutableArray *pickFields;

@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIActionSheet *actionSheet;

@property (nonatomic, strong) FieldPayload *currentPickField;

@property (nonatomic, strong) UIView *pickerViewBackground;
@property (nonatomic, strong) UIView *datePickerBackground;

@property (nonatomic, assign, getter=isDatePickerShowing) BOOL datePickerShowing;
@property (nonatomic, assign, getter=isPickerViewShowing) BOOL pickerViewShowing;

@property (nonatomic, strong) UILabel *currentLabel;

@end

@implementation OTFormUpdateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
    singleTap.numberOfTapsRequired = 1;
    [self.tableView addGestureRecognizer:singleTap];

    _switchFields = [NSMutableArray array];
    _dateFields = [NSMutableArray array];
    _pickFields = [NSMutableArray array];
    
    // Headerview 16pt
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
    headerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = headerView;

//    [self setupView];
    NSMutableArray *fields = [NSMutableArray array];
    NSInteger customCellHeight = 32.0f;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"ordering" ascending:YES];
    NSArray *fieldTemplateList = [[_sectionElementPayload.sectionPayload.sectionTemplate.fieldTemplateList allObjects] sortedArrayUsingDescriptors:@[sortDescriptor]];
    for (int i = 0; i < fieldTemplateList.count; i++) {
        FieldTemplate *fieldTemplate = [fieldTemplateList objectAtIndex:i];
        [self setHeaderTitle:fieldTemplate.displayName forSection:i];
        FieldPayloadEntity *fieldPayloadEntity = [FieldPayloadEntity new];
        [fieldPayloadEntity setManagedObjectContext:_sectionElementPayload.managedObjectContext];
        FieldPayload *fieldPayload = [fieldPayloadEntity getObjectBySectionElementPayload:_sectionElementPayload andFieldTemplate:fieldTemplate sortKeys:@[@"attributeId"]];
        
        FieldConstraint *fieldConstraint;
        for (FieldConstraint *object in fieldTemplate.fieldConstraintList)
            if ([object.fieldConstraintType isEqualToString:@"OPTION"]) fieldConstraint = object;
        
        id cell;
        if ([fieldTemplate.fieldType isEqualToString:@"BOOL"]) {
            [_switchFields addObject:fieldPayload];
            cell = [[OTFormSwitchCell alloc] initWithTextLabel:fieldTemplate.hint
                                              customCellHeight:customCellHeight
                                                      viewType:_claim.getViewType];
            
            [((OTFormSwitchCell *)cell).switches setOn:[fieldPayload.booleanPayload boolValue]];
            ((OTFormSwitchCell *)cell).switches.tag = _switchFields.count - 1;
            ((OTFormSwitchCell *)cell).switchActionBlock = ^(UISwitch *switches) {
                [self switchValueDidChange:switches];
            };
            
        } else if ([fieldTemplate.fieldType isEqualToString:@"DECIMAL"]) {
            cell = [[OTFormInputTextFieldCell alloc] initWithText:[fieldPayload.bigDecimalPayload stringValue]
                                                      placeholder:fieldTemplate.hint
                                                         delegate:self
                                                        mandatory:NO
                                                 customCellHeight:customCellHeight
                                                     keyboardType:UIKeyboardTypeDefault
                                                         viewType:_claim.getViewType];

            ((OTFormInputTextFieldCell *)cell).shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
                if (inText.length > 0) {
                    inCell.validationState = BPFormValidationStateValid;
                    inCell.shouldShowInfoCell = NO;
                    if (_claim.getViewType == OTViewTypeAdd || _claim.getViewType == OTViewTypeEdit)
                        fieldPayload.bigDecimalPayload = [NSDecimalNumber decimalNumberWithString:inText];
                }
                return YES;
            };
        } else if ([fieldTemplate.fieldType isEqualToString:@"DATE"]) {
            cell = [[OTFormCell alloc] initWithFrame:CGRectZero];

            UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(datePickerShow:)];
            tapped.numberOfTapsRequired = 1;
            
            [_dateFields addObject:fieldPayload];
            
            NSString *title = fieldPayload.stringPayload != nil ? fieldPayload.stringPayload : fieldTemplate.hint;
            
            if (fieldPayload.stringPayload == nil || [fieldPayload.stringPayload isEqualToString:@""]) {
                title = [[OT dateFormatter] stringFromDate:[NSDate date]];
                fieldPayload.stringPayload = [title substringToIndex:10];
            }
            
            ((OTFormCell *)cell).selectionStyle = UITableViewCellSelectionStyleNone;
            ((OTFormCell *)cell).imageView.image = [UIImage imageNamed:@"ic_action_datepicker"];
            ((OTFormCell *)cell).textLabel.attributedText = [OT getAttributedStringFromText:[title substringToIndex:10]];
            ((OTFormCell *)cell).imageView.userInteractionEnabled = YES;
            ((OTFormCell *)cell).imageView.tag = _dateFields.count - 1;
            [((OTFormCell *)cell).imageView addGestureRecognizer:tapped];
        } else if ([fieldTemplate.fieldType isEqualToString:@"TEXT"] && [fieldConstraint.fieldConstraintType isEqualToString:@"OPTION"]) { // Text picker
            cell = [[OTFormCell alloc] initWithFrame:CGRectZero];
            
            UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerShow:)];
            tapped.numberOfTapsRequired = 1;
            
            [_pickFields addObject:fieldPayload];
            
            NSString *title = fieldPayload.stringPayload != nil ? fieldPayload.stringPayload : fieldTemplate.hint;
            if (fieldPayload.stringPayload != nil && ![fieldPayload.stringPayload isEqualToString:@""]) {
                FieldConstraintOption *fieldConstraintOption = [FieldConstraintOptionEntity getEntityById:fieldPayload.stringPayload];
                title = fieldConstraintOption.displayName;
            } else { // Lấy phần tử đầu tiên trong list option mặc định
                FieldConstraintOption *fieldConstraintOption = [[fieldConstraint.fieldConstraintOptionList allObjects] firstObject];
                title = fieldConstraintOption.displayName;
                fieldPayload.stringPayload = fieldConstraintOption.attributeId;
            }

            ((OTFormCell *)cell).selectionStyle = UITableViewCellSelectionStyleNone;
            ((OTFormCell *)cell).imageView.image = [UIImage imageNamed:@"ic_action_picker"];
            ((OTFormCell *)cell).textLabel.attributedText = [OT getAttributedStringFromText:title];
            ((OTFormCell *)cell).imageView.userInteractionEnabled = YES;
            ((OTFormCell *)cell).imageView.tag = _pickFields.count - 1;
            [((OTFormCell *)cell).imageView addGestureRecognizer:tapped];
        } else if ([fieldTemplate.fieldType isEqualToString:@"TEXT"]) { // Text thường
            // Kiểm tra field NOT_NULL
            BOOL mandatory = NO;
            for (FieldConstraint *object in fieldTemplate.fieldConstraintList)
                if ([object.fieldConstraintType isEqualToString:@"NOT_NULL"]) mandatory = YES;
            
            cell = [[OTFormInputTextFieldCell alloc] initWithText:fieldPayload.stringPayload
                                                      placeholder:fieldTemplate.hint
                                                         delegate:self
                                                        mandatory:mandatory
                                                 customCellHeight:customCellHeight
                                                     keyboardType:UIKeyboardTypeDefault
                                                         viewType:_claim.getViewType];

            ((OTFormInputTextFieldCell *)cell).shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
                if (inText.length > 0) {
                    inCell.validationState = BPFormValidationStateValid;
                    inCell.shouldShowInfoCell = NO;
                    if (_claim.getViewType == OTViewTypeAdd || _claim.getViewType == OTViewTypeEdit)
                        fieldPayload.stringPayload = inText;
                } else {
                    inCell.validationState = BPFormValidationStateInvalid;
                    inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_fields", nil);
                    inCell.shouldShowInfoCell = YES;
                }
                return YES;
            };
            ((OTFormInputTextFieldCell *)cell).textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        } else { // Chưa rõ
            [UIAlertView showWithTitle:@"Error!" message:[NSString stringWithFormat:@"Unknow field type: %tu", fieldTemplate.fieldConstraintList.count] cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[@"OK"] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                
            }];
            cell = [[OTFormInputTextFieldCell alloc] initWithText:fieldPayload.stringPayload
                                                      placeholder:fieldTemplate.hint
                                                         delegate:self
                                                        mandatory:NO
                                                 customCellHeight:customCellHeight
                                                     keyboardType:UIKeyboardTypeDefault
                                                         viewType:_claim.getViewType];
            
            ((OTFormInputTextFieldCell *)cell).shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
                if (inText.length > 0) {
                    inCell.validationState = BPFormValidationStateValid;
                    inCell.shouldShowInfoCell = NO;
                    if (_claim.getViewType == OTViewTypeAdd || _claim.getViewType == OTViewTypeEdit)
                        fieldPayload.stringPayload = inText;
                } else {
                    inCell.validationState = BPFormValidationStateInvalid;
                    inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_fields", nil);
                    inCell.shouldShowInfoCell = YES;
                }
                return YES;
            };
            ((OTFormInputTextFieldCell *)cell).textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        }
        [cell setCustomCellHeight:customCellHeight];
        [fields addObject:@[cell]];
    }
    self.formCells = fields;
    self.customSectionHeaderHeight = 20;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done:(id)sender {
    if ([_claim.managedObjectContext hasChanges] && _claim.getViewType == OTViewTypeEdit) {
        [UIAlertView showWithTitle:NSLocalizedStringFromTable(@"title_save_dialog", @"Additional", nil) message:NSLocalizedStringFromTable(@"message_save_dialog", @"Additional", nil) style:UIAlertViewStyleDefault cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"action_save", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                [self.navigationController dismissViewControllerAnimated:NO completion:^{
                    [_claim.managedObjectContext save:nil];
                }];
            } else {
                [self.navigationController dismissViewControllerAnimated:NO completion:^{
                    [self performSelector:@selector(rollback) withObject:nil afterDelay:0];
                }];
            }
            
        }];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)rollback {
    [_claim.managedObjectContext rollback];
}

#pragma mark - Actions

- (void)switchValueDidChange:(UISwitch *)aSwitch {
    if (_switchFields.count > 0) {
        FieldPayload *fieldPayload = [_switchFields objectAtIndex:aSwitch.tag];
        fieldPayload.booleanPayload = [NSNumber numberWithBool:aSwitch.isOn];
    }
}

- (IBAction)datePickerShow:(UITapGestureRecognizer *)sender {
    if (_dateFields.count > 0 && _claim.getViewType != OTViewTypeView) {
        if (!_pickerViewShowing && !_datePickerShowing) {
            [self dismissKeyboard];
            _currentPickField = [_dateFields objectAtIndex:sender.view.tag];
            OTFormCell *formCell = (OTFormCell *)[self getSuperViewByClass:[OTFormCell class] fromView:sender.view];
            CGRect frame = formCell.textLabel.frame;
            _currentLabel = formCell.textLabel;
            
            _datePickerBackground = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, formCell.frame.origin.y + frame.size.height, frame.size.width, 150)];
            _datePickerBackground.layer.borderColor = [[UIColor otGreen] CGColor];
            _datePickerBackground.layer.borderWidth = 1;
            _datePickerBackground.layer.cornerRadius = 4.0f;
            _datePickerBackground.backgroundColor = [UIColor whiteColor];
            _datePickerBackground.alpha = 0.95;

            _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 150)];
            _datePickerShowing = YES;
            [_datePicker setDatePickerMode:UIDatePickerModeDate];
            [_datePicker addTarget:self action:@selector(pickerChanged:) forControlEvents:UIControlEventValueChanged];

            // Đặt ngày của datePicker theo ngày của field
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];
            NSDate *date = [dateFormatter dateFromString:_currentLabel.text];
            if (date != nil)
                [_datePicker setDate:date];

            [_datePickerBackground addSubview:_datePicker];
            [formCell.superview.superview addSubview:_datePickerBackground];
        } else [self hidePickers];
    }
}

- (UIView *)getSuperViewByClass:(Class)class fromView:(UIView *)view {
    if (view.superview != nil) {
        if ([NSStringFromClass([view.superview class]) isEqualToString:NSStringFromClass(class)]) {
            return view.superview;
        } else {
            return [self getSuperViewByClass:class fromView:view.superview];
        }
    }
    return nil;
}

- (IBAction)pickerShow:(UITapGestureRecognizer *)sender {
    if (_pickFields.count > 0 && _claim.getViewType != OTViewTypeView) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            if (!_pickerViewShowing && !_datePickerShowing) {
                [self dismissKeyboard];
                _currentPickField = [_pickFields objectAtIndex:sender.view.tag];
                OTFormCell *formCell = (OTFormCell *)[self getSuperViewByClass:[OTFormCell class] fromView:sender.view];
                CGRect frame = formCell.textLabel.frame;
                _currentLabel = formCell.textLabel;
                
                _pickerViewBackground = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, formCell.frame.origin.y + frame.size.height, frame.size.width, 200)];
                _pickerViewBackground.layer.borderColor = [[UIColor otGreen] CGColor];
                _pickerViewBackground.layer.borderWidth = 1;
                _pickerViewBackground.layer.cornerRadius = 4.0f;
                _pickerViewBackground.backgroundColor = [UIColor whiteColor];
                _pickerViewBackground.alpha = 0.95;
                
                _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 200)];
                _pickerView.delegate = self;
                _pickerViewShowing = YES;
                [_pickerView reloadAllComponents];

                
                FieldConstraint *fieldConstraint;
                for (FieldConstraint *object in _currentPickField.fieldTemplate.fieldConstraintList)
                    if ([object.fieldConstraintType isEqualToString:@"OPTION"]) fieldConstraint = object;
                
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"ordering" ascending:YES];
                NSArray *options = [[fieldConstraint.fieldConstraintOptionList allObjects]  sortedArrayUsingDescriptors:@[sortDescriptor]];
                for (int i = 0; i < options.count; i++) {
                    FieldConstraintOption *fieldConstraintOption = [options objectAtIndex:i];
                    if ([_currentLabel.text isEqualToString:fieldConstraintOption.displayName])
                        [_pickerView selectRow:i inComponent:0 animated:YES];
                }

                [_pickerViewBackground addSubview:_pickerView];
                [formCell.superview.superview addSubview:_pickerViewBackground];
            } else [self hidePickers];
        } else {
            if (!_pickerViewShowing && !_datePickerShowing) {
                [self dismissKeyboard];
                _currentPickField = [_pickFields objectAtIndex:sender.view.tag];
                OTFormCell *formCell = (OTFormCell *)[self getSuperViewByClass:[OTFormCell class] fromView:sender.view];
                CGRect frame = formCell.textLabel.frame;
                _currentLabel = formCell.textLabel;
                
                _pickerViewBackground = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, formCell.frame.origin.y + frame.size.height, frame.size.width, 200)];
                _pickerViewBackground.layer.borderColor = [[UIColor otGreen] CGColor];
                _pickerViewBackground.layer.borderWidth = 1;
                _pickerViewBackground.layer.cornerRadius = 4.0f;
                _pickerViewBackground.backgroundColor = [UIColor whiteColor];
                _pickerViewBackground.alpha = 0.95;
                
                _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 200)];
                _pickerView.delegate = self;
                _pickerViewShowing = YES;
                [_pickerView reloadAllComponents];
                
                
                FieldConstraint *fieldConstraint;
                for (FieldConstraint *object in _currentPickField.fieldTemplate.fieldConstraintList)
                    if ([object.fieldConstraintType isEqualToString:@"OPTION"]) fieldConstraint = object;
                
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"ordering" ascending:YES];
                NSArray *options = [[fieldConstraint.fieldConstraintOptionList allObjects]  sortedArrayUsingDescriptors:@[sortDescriptor]];
                for (int i = 0; i < options.count; i++) {
                    FieldConstraintOption *fieldConstraintOption = [options objectAtIndex:i];
                    if ([_currentLabel.text isEqualToString:fieldConstraintOption.displayName])
                        [_pickerView selectRow:i inComponent:0 animated:YES];
                }
                
                [_pickerViewBackground addSubview:_pickerView];
                [formCell.superview.superview addSubview:_pickerViewBackground];
            } else [self hidePickers];
        }
    }
}

- (void)hidePickers {
    if (_datePickerShowing)
        [self datePickerDone:nil];
    else
        [self pickerViewDone:nil];
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

- (IBAction)singleTapAction:(id)sender {
    [self hidePickers];
}

#pragma mark - UIPickerViewDelegate methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    FieldConstraint *fieldConstraint;
    for (FieldConstraint *object in _currentPickField.fieldTemplate.fieldConstraintList)
        if ([object.fieldConstraintType isEqualToString:@"OPTION"]) fieldConstraint = object;

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"ordering" ascending:YES];
    NSArray *options = [[fieldConstraint.fieldConstraintOptionList allObjects]  sortedArrayUsingDescriptors:@[sortDescriptor]];
    FieldConstraintOption *fieldConstraintOption = [options objectAtIndex:row];

    _currentPickField.stringPayload = fieldConstraintOption.name;
    
    _currentLabel.attributedText = [OT getAttributedStringFromText:fieldConstraintOption.displayName];
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    FieldConstraint *fieldConstraint;
    for (FieldConstraint *object in _currentPickField.fieldTemplate.fieldConstraintList)
        if ([object.fieldConstraintType isEqualToString:@"OPTION"]) fieldConstraint = object;
    
    NSUInteger numRows = fieldConstraint.fieldConstraintOptionList.count;
    
    return numRows;
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title;
    FieldConstraint *fieldConstraint;
    for (FieldConstraint *object in _currentPickField.fieldTemplate.fieldConstraintList)
        if ([object.fieldConstraintType isEqualToString:@"OPTION"]) fieldConstraint = object;

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"ordering" ascending:YES];
    NSArray *options = [[fieldConstraint.fieldConstraintOptionList allObjects]  sortedArrayUsingDescriptors:@[sortDescriptor]];
    FieldConstraintOption *fieldConstraintOption = [options objectAtIndex:row];
    title = fieldConstraintOption.displayName;
    
    return title;
}


#pragma handle UIDatePicker method

- (IBAction)pickerChanged:(UIDatePicker *)sender {
    NSString *dateString = [[OT dateFormatter] stringFromDate:[sender date]];
    
    _currentLabel.attributedText = [OT getAttributedStringFromText:[dateString substringToIndex:10]];
    _currentPickField.stringPayload = [dateString substringToIndex:10];
}

- (IBAction)pickerViewDone:(id)sender {
    [_pickerViewBackground removeFromSuperview];
    _pickerViewShowing = NO;
}

- (IBAction)datePickerDone:(id)sender {
    [_datePickerBackground removeFromSuperview];
    _datePickerShowing = NO;
}

- (void)listSubviewsOfView:(UIView *)view {
    
    // Get the subviews of the view
    NSArray *subviews = [view subviews];
    
    // Return if there are no subviews
    if ([subviews count] == 0) return; // COUNT CHECK LINE
    
    for (UIView *subview in subviews) {
        
        // Do what you want to do with the subview
        NSLog(@"%@", subview);
        
        // List the subviews of subview
        [self listSubviewsOfView:subview];
    }
}


- (UIView *)getSubviewByClass:(Class)class fromView:(UIView *)view {
    if ([[view subviews] count] > 0) {
        for (UIView *subview in [view subviews]) {
            if ([NSStringFromClass([subview class]) isEqualToString:NSStringFromClass(class)]) {
                return subview;
            } else {
                UIView *nextView = [self getSubviewByClass:class fromView:subview];
                if ([NSStringFromClass([nextView class]) isEqualToString:NSStringFromClass(class)])
                    return nextView;
            }
        }
    }
    return nil;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (cell.tag == OTFormCellTypeBoolean) {
        UISwitch *otSwitch = (UISwitch *)[self getSubviewByClass:[UISwitch class] fromView:cell];
        CGRect cf = cell.textLabel.frame;
        CGRect sf = otSwitch.frame;
        sf.origin.x = cf.size.width - sf.size.width;
        [otSwitch setFrame:sf];
        [cell drawRect:cell.frame];
    }
}

@end
