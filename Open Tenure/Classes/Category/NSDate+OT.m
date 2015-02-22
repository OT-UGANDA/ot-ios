//
//  NSDate+OT.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 2/13/15.
//  Copyright (c) 2015 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "NSDate+OT.h"

@implementation NSDate (OT)

+ (NSInteger)daysToDateTime:(NSDate *)dateTime {
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
                 interval:NULL forDate:[self date]];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
                 interval:NULL forDate:dateTime];
    
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

@end
