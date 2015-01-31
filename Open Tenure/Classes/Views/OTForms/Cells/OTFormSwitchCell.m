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

#import "OTFormSwitchCell.h"
#import "OTAppearance.h"
#import "Masonry.h"

@interface OTFormSwitchCell ()

@property (nonatomic, strong) MASConstraint *widthConstraint;
@property (nonatomic, strong) MASConstraint *heightConstraint;

@end

@implementation OTFormSwitchCell

@synthesize spaceToNextCell = _spaceToNextCell;
@synthesize customContentHeight = _customContentHeight;
@synthesize customContentWidth = _customContentWidth;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor otLightGreen];
        self.spaceToNextCell = 2.0f;
        self.textLabel.backgroundColor = [UIColor whiteColor];
        self.textLabel.font = [OTAppearance sharedInstance].infoCellLabelFont;
        
        [self.textLabel setClipsToBounds:YES];
        [[self.textLabel layer] setCornerRadius:4.f];
        [[self.textLabel layer] setBorderWidth:0.8f];
        [[self.textLabel layer] setBorderColor:[[UIColor otGreen] CGColor]];
    }
    return self;
}

- (id)initWithTextLabel:(NSString *)text customCellHeight:(CGFloat)cellHeight viewType:(OTViewType)viewType {
    if (self = [super init]) {
        NSMutableParagraphStyle *style =  [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = NSTextAlignmentJustified;
        style.firstLineHeadIndent = 5.0f;
        style.headIndent = 5.0f;
        style.tailIndent = -5.0f;
        NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:text attributes:@{ NSParagraphStyleAttributeName:style}];
        self.textLabel.attributedText = attrText;
        
        self.customCellHeight = cellHeight;
        self.switches.enabled = (viewType == OTViewTypeAdd) || (viewType == OTViewTypeEdit) ? YES : NO;
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupCell];
        [self setupSwitch];
    }
    return self;
}

- (void)setupCell {
    self.backgroundColor = [BPAppearance sharedInstance].buttonCellBackgroundColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setupSwitch {
    self.switches = [[UISwitch alloc] init];
    self.switches.transform = CGAffineTransformMakeScale(0.75, 0.75);
    self.switches.backgroundColor = [UIColor clearColor];
    [self.switches addTarget:self action:@selector(switchPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView insertSubview:self.switches aboveSubview:self.textLabel];
    
    [self.widthConstraint uninstall];
    [self.heightConstraint uninstall];
    
    [self.switches mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_right).offset(-self.switches.frame.size.width - 5);
        CGFloat offset = 0;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
            offset = 4;
        make.centerY.equalTo(self.mas_centerY).offset(offset);
    }];
}

- (void)switchPressed:(id)sender {
    if (self.switchActionBlock) {
        self.switchActionBlock(self.switches);
    }
}

- (void)setSpaceToNextCell:(CGFloat)inSpaceToNextCell {
    if (inSpaceToNextCell != _spaceToNextCell) {
        _spaceToNextCell = inSpaceToNextCell;
        
        if (self.customContentHeight == 0) {
            
            [self.heightConstraint uninstall];
            [self.switches mas_updateConstraints:^(MASConstraintMaker *make) {
                self.heightConstraint = make.height.equalTo(self.mas_height).offset(-inSpaceToNextCell);
            }];
        }
    }
}

- (void)setCustomContentHeight:(CGFloat)inCustomContentHeight {
    if (inCustomContentHeight != _customContentHeight) {
        _customContentHeight = inCustomContentHeight;
        
        [self.heightConstraint uninstall];
        [self.switches mas_updateConstraints:^(MASConstraintMaker *make) {
            self.heightConstraint = make.height.equalTo(@(inCustomContentHeight));
        }];
    }
}

- (void)setCustomContentWidth:(CGFloat)inCustomContentWidth {
    if (inCustomContentWidth != _customContentWidth) {
        _customContentWidth = inCustomContentWidth;
        
        [self.widthConstraint uninstall];
        [self.switches mas_updateConstraints:^(MASConstraintMaker *make) {
            self.widthConstraint = make.width.equalTo(@(inCustomContentWidth));
        }];
    }
}

- (CGFloat)cellHeight {
    CGFloat cellHeight = (self.customCellHeight ?: self.bounds.size.height);
    return cellHeight;
}

@end
