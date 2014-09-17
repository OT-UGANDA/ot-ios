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

#import "PickerView.h"

#define DEFAULT_POPOVER_SIZE CGSizeMake(300, 200)

@interface PickerView () <UITableViewDataSource, UITableViewDelegate>

@property (strong) NSArray *stringsArray;
@property (strong) NSArray *matchedStrings;

@property (strong) UIPopoverController *popOver;
@property (strong) UITableViewController *controller;
@property (strong) UITextField *textField;

@property (strong) UIDatePicker *datePicker;
@property (nonatomic) NSDateFormatter *dateFormatter;

@property (nonatomic) UITableView *tableView;

@end

@implementation PickerView

- (id)init {
    if (self = [super init]) {
        [self setupView];
    }
    return self;
}

- (id)initWithPickItems:(NSArray *)pickItems {
    self = [super init];
    if (self) {
        [self setupView];
        self.stringsArray = pickItems;
    }
    return self;
}

- (void)attachWithTextField:(UITextField *)textField {
    self.textField = textField;
}

- (void)detach {
    _textField = [[UITextField alloc] initWithFrame:CGRectNull];
    [_popOver dismissPopoverAnimated:YES];
}

- (void)setPopoverSize:(CGSize)size {
    self.popOver.popoverContentSize = size;
}

- (void)setupView {
    UITableViewController *tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    self.tableView = tableViewController.tableView;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    self.controller = tableViewController;
    self.popOver = [[UIPopoverController alloc] initWithContentViewController:_controller];
    
    self.datePicker = [[UIDatePicker alloc] initWithFrame:_controller.view.frame];
    _datePicker.datePickerMode = UIDatePickerModeDate;
    [_datePicker addTarget:self action:@selector(pickerChanged:) forControlEvents:UIControlEventValueChanged];
    self.matchedStrings = [NSArray array];
    self.dateFormatter = [NSDateFormatter new];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    // Default values
    _popOver.popoverContentSize = DEFAULT_POPOVER_SIZE;
    self.shouldHideOnSelection = YES;
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectNull];
}

#pragma mark - Modifiers

- (void)setPickItems:(NSArray *)pickItems {
    self.stringsArray = pickItems;
    [_tableView reloadData];
}

- (void)setDate:(NSDate *)date {
    [_datePicker setDate:date];
}

- (void)setDateFormat:(NSString *)dateFormat {
    [_dateFormatter setDateFormat:dateFormat];
}

- (void)setDatePickerMode:(UIDatePickerMode)datePickerMode {
    [_datePicker setDatePickerMode:datePickerMode];
}

#pragma mark - Matching strings and Popover

- (void)matchStrings:(NSString *)letters {
    if (_stringsArray.count > 0) {
        
        self.matchedStrings = [_stringsArray
                               filteredArrayUsingPredicate:
                               [NSPredicate predicateWithFormat:@"self contains[cd] %@", letters]];
        [_controller.tableView reloadData];
    }
}

- (void)matchDate:(NSString *)dateString {
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [_dateFormatter setTimeZone:gmt];
    NSDate *date = [_dateFormatter dateFromString:dateString];
    if (date != nil)
        [_datePicker setDate:date];
}

- (void)showPopOverList {
    switch ([self pickType]) {
        case PickTypeNone:
            break;
            
        case PickTypeList:
            self.controller.view = _tableView;
            [_tableView flashScrollIndicators];
            if (!_popOver.isPopoverVisible) {
                CGRect frame = _textField.frame;
                frame.size.width = 300;
                [_popOver presentPopoverFromRect:frame
                                          inView:_textField.superview
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
            }
            break;
            
        case PickTypeDate: {
            self.controller.view = _datePicker;
            if (!_popOver.isPopoverVisible) {
                CGRect frame = _textField.frame;
                frame.size.width = 300;
                [_popOver presentPopoverFromRect:frame
                                          inView:_textField.superview
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
            }
            break;
        }
        case PickTypeSuggestion:
            self.controller.view = _tableView;
            [_tableView flashScrollIndicators];
            if (_matchedStrings.count == 0) {
                [_popOver dismissPopoverAnimated:YES];
            } else if (!_popOver.isPopoverVisible) {
                CGRect frame = _textField.frame;
                frame.size.width = 300;
                [_popOver presentPopoverFromRect:frame
                                          inView:_textField.superview
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
            }
            break;
    }
}

#pragma handle UIDatePicker method

- (IBAction)pickerChanged:(UIDatePicker *)sender {
    NSString *dateString = [_dateFormatter stringFromDate:[sender date]];
    _textField.text = dateString;
}

#pragma mark - TableView Delegate & DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ([self pickType]) {
        case PickTypeNone:
            break;
            
        case PickTypeList:
            return _stringsArray.count;
            break;
            
        case PickTypeDate:
            
            break;
            
        case PickTypeSuggestion:
            return _matchedStrings.count;
            break;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    switch ([self pickType]) {
        case PickTypeNone:
            break;
            
        case PickTypeList:
            cell.textLabel.text = [_stringsArray objectAtIndex:indexPath.row];
            break;
            
        case PickTypeDate:
            
            break;
            
        case PickTypeSuggestion: {
            cell.textLabel.text = [_matchedStrings objectAtIndex:indexPath.row];
            break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self pickType]) {
        case PickTypeNone:
            break;
            
        case PickTypeList:
            _textField.text = [_stringsArray objectAtIndex:indexPath.row];
            break;
        case PickTypeDate:
            
            break;
            
        case PickTypeSuggestion: {
            _textField.text = [_matchedStrings objectAtIndex:indexPath.row];
            break;
        }
    }
    if (_shouldHideOnSelection) {
        [_popOver dismissPopoverAnimated:YES];
    }
}

@end
