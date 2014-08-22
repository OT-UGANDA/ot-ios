//
//  OTFormFloatInputTextFieldCell.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/4/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTFormFloatInputTextFieldCell.h"
#import "OTFormFloatLabelTextField.h"
#import "OTFormInfoCell.h"
#import "OTAppearance.h"

@implementation OTFormFloatInputTextFieldCell

+ (Class)textInputClass {
    return [OTFormFloatLabelTextField class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor otLightGreen];
        self.spaceToNextCell = 2.0f;
        self.textField.backgroundColor = [UIColor otGreen];
        self.textField.layer.borderWidth = 0.0;
        self.textField.returnKeyType = UIReturnKeyDefault;
        self.infoCell.backgroundColor = [UIColor orangeColor];
        self.infoCell.label.textColor = [UIColor whiteColor];
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        if ([self.textField isKindOfClass:[OTFormFloatLabelTextField class]]) {
            OTFormFloatLabelTextField *floatLabelTextField = (OTFormFloatLabelTextField *)self.textField;
            
            [floatLabelTextField floatingLabel].font = [OTAppearance sharedInstance].infoCellLabelFont;
            [floatLabelTextField floatingLabel].backgroundColor = [UIColor clearColor];
        }
    }
    return self;
}

- (id)initWithText:(NSString *)text
       placeholder:(NSString *)placeholder
          delegate:(id)delegate
         mandatory:(BOOL)mandatory
  customCellHeight:(CGFloat)cellHeight
      keyboardType:(UIKeyboardType)keyboardType
          viewType:(OTViewType)viewType {
    
    if (self = [super init]) {
        self.textField.text = text;
        self.textField.placeholder = placeholder;
        self.textField.delegate = delegate;
        self.mandatory = mandatory;
        self.customCellHeight = cellHeight;
        self.textField.keyboardType = keyboardType;
        if ((viewType == OTViewTypeAdd) && mandatory) {
            // Set init to invalid
            self.validationState = BPFormValidationStateInvalid;
            // Clear validation state when begin editing
            self.didBeginEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText){
                inCell.validationState = BPFormValidationStateNone;
            };
        }
        self.textField.enabled = (viewType == OTViewTypeAdd) || (viewType == OTViewTypeEdit) ? YES : NO;
    }
    return self;
}

@end
