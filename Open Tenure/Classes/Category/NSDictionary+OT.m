//
//  NSDictionary+OT.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/6/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "NSDictionary+OT.h"

@implementation NSDictionary (OT)

- (NSDictionary *)deserialize {
    const NSMutableDictionary *replaced = [self mutableCopy];
    const NSNull *null = [NSNull null];
    for (NSString *object in self.allKeys) {
        const id value = [self objectForKey:object];
        [replaced setValue:((value != null) ? value :nil) forKey:object];
    }
    return [replaced copy];
}

@end
