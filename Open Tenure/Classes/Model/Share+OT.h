//
//  Share+OT.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 9/23/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "Share.h"

@interface Share (OT)

- (NSDictionary *)dictionary;

- (void)importFromJSON:(NSDictionary *)keyedValues;

@end
