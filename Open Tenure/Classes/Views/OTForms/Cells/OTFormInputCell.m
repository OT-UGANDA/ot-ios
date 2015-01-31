//
//  OTFormInputCell.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 1/8/15.
//  Copyright (c) 2015 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTFormInputCell.h"
#import "OTAppearance.h"

@implementation OTFormInputCell

+ (Class)textInputClass {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Must subclass BPFormInputCell"]
                                 userInfo:nil];
    return nil;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupCell];
    }
    return self;
}

- (void)setupCell {
    self.backgroundColor = [OTAppearance sharedInstance].inputCellBackgroundColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.validationState = BPFormValidationStateNone;
}

@end
