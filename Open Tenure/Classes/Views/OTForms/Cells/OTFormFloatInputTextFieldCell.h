//
//  OTFormFloatInputTextFieldCell.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/4/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "BPFormFloatInputTextFieldCell.h"

@interface OTFormFloatInputTextFieldCell : BPFormFloatInputTextFieldCell

- (id)initWithText:(NSString *)text
       placeholder:(NSString *)placeholder
          delegate:(id)delegate
         mandatory:(BOOL)mandatory
  customCellHeight:(CGFloat)cellHeight
      keyboardType:(UIKeyboardType)keyboardType
          viewType:(OTViewType)viewType;

@end
