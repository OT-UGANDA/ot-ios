//
//  BPFormSwitchCell.m
//
//  Copyright (c) 2014 Bogdan Poplauschi
//
//  Create by Chuyen Trung Tran 2015
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


#import "BPFormSwitchCell.h"
#import "OTAppearance.h"
#import "Masonry.h"


@interface BPFormSwitchCell ()

@property (nonatomic, strong) MASConstraint *widthConstraint;
@property (nonatomic, strong) MASConstraint *heightConstraint;

@end


@implementation BPFormSwitchCell

// auto-synthesize doesn't work here since the properties are defined in a base class (BPFormCell)
@synthesize spaceToNextCell = _spaceToNextCell;
@synthesize customContentHeight = _customContentHeight;
@synthesize customContentWidth = _customContentWidth;

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
