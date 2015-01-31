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

#import "OTFormCell.h"
#import "UIColor+OT.h"
#import "OTAppearance.h"

@implementation OTFormCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor otLightGreen];
        self.spaceToNextCell = 2.0f;
        self.textLabel.backgroundColor = [UIColor whiteColor];
        self.textLabel.font = [OTAppearance sharedInstance].infoCellLabelFont;
        self.detailTextLabel.font = [OTAppearance sharedInstance].infoCellLabelFont;
        self.detailTextLabel.textColor = [UIColor redColor];
        
        [self.textLabel setClipsToBounds:YES];
        [[self.textLabel layer] setCornerRadius:4.f];
        [[self.textLabel layer] setBorderWidth:0.8f];
        [[self.textLabel layer] setBorderColor:[[UIColor otGreen] CGColor]];
    }
    return self;
}

// Có thể thay đổi chiều rộng của cell
- (void)setFrame:(CGRect)frame {
    //if (self.tag == 1)
//        frame.size.width -= 96;
    [super setFrame:frame];
}


@end
