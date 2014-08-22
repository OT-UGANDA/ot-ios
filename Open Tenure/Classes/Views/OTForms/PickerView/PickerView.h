//
//  PickerView.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/8/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PickType) {
    /*!
     Default UITextField
     */
    PickTypeNone = 0,
    
    /*!
     Pick List Readonly
     */
    PickTypeList,
    
    /*!
     Pick List Suggestions
     */
    PickTypeSuggestion,
    
    /*!
     Pick UIDatePicker
     */
    PickTypeDate
};

@interface PickerView : NSObject

@property (nonatomic, assign) PickType pickType;
@property BOOL shouldHideOnSelection;

- (id)initWithPickItems:(NSArray *)pickItems;

- (void)attachWithTextField:(UITextField *)textField;
- (void)detach;

- (void)setPopoverSize:(CGSize)size;

- (void)showPopOverList;

/*!
 Set pick list
 */
- (void)setPickItems:(NSArray *)pickItems;

- (void)setDate:(NSDate *)date;

- (void)setDateFormat:(NSString *)dateFormat;

- (void)setDatePickerMode:(UIDatePickerMode)datePickerMode;

/*!
 Filter array and reload TableView
 */
- (void)matchStrings:(NSString *)letters;

/*!
 Match date from string
 */
- (void)matchDate:(NSString *)dateString;

@end
