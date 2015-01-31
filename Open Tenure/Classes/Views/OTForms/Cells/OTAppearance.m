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

#import "OTAppearance.h"

@implementation OTAppearance

+(OTAppearance *)sharedInstance {
    static dispatch_once_t onceToken;
    static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    
    return instance;
}

- (id)init {
    if (self = [super init]) {
        [self loadDefaults];
    }
    return self;
}

- (void)loadDefaults {
    self.tableViewBackGroundColor           = [UIColor otLightGreen];
    
    self.inputCellBackgroundColor           = [UIColor whiteColor];
    self.inputCellTextFieldTextColor        = [UIColor blackColor];
    self.inputCellTextFieldBackgroundColor  = [UIColor colorWithRed:0.93f green:0.93f blue:0.93f alpha:1.0f];
    self.inputCellTextFieldBorderColor      = [UIColor colorWithRed:0.85f green:0.85f blue:0.85f alpha:1.0f];
    
    self.infoCellBackgroundColor            = [UIColor whiteColor];
    self.infoCellLabelTextColor             = [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f];
    self.infoCellLabelBackgroundColor       = [UIColor clearColor];
    
    self.buttonCellBackgroundColor          = [UIColor whiteColor];
    
    self.headerFooterLabelTextColor         = [UIColor blackColor];
    
    self.inputCellTextFieldFont             = [UIFont systemFontOfSize:14.0f];
    self.inputCellTextFieldFloatingLabelFont= [UIFont systemFontOfSize: 8.0f];
    self.infoCellLabelFont                  = [UIFont systemFontOfSize:14.0f];
    self.headerFooterLabelFont              = [UIFont systemFontOfSize:13.0f];
    
    self.infoCellHeight = 16.0f;
    self.spaceBetweenCells = 8.0f;
}

@end
