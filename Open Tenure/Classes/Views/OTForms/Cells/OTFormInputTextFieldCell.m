//
//  OTFormInputTextFieldCell.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/4/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTFormInputTextFieldCell.h"
#import "OTFormInfoCell.h"
#import "PickerView.h"
#import "UIColor+OT.h"

@implementation OTFormInputTextFieldCell

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

- (void)setFrame:(CGRect)frame {
//    frame.size.width -= 96;
    [super setFrame:frame];
}

@end
