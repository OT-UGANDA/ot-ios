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
        self.textField.backgroundColor = [UIColor whiteColor];
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
