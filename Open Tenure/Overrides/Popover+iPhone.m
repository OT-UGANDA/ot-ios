//
//  Popover+iPhone.m
//  Popover
//
//  Created by Chuyen Trung Tran on 11/26/13.
//  Copyright (c) 2013 Chuyen Trung Tran. All rights reserved.
//

#import "Popover+iPhone.h"

@implementation UIPopoverController (overrides)

+ (BOOL)_popoversDisabled {
    return NO;
}

@end