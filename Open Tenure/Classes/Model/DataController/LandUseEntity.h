//
//  LandUseEntity.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/6/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "AbstractEntity.h"

@class ResponseLandUse, LandUse;

@interface LandUseEntity : AbstractEntity

+ (BOOL)insertFromResponseObject:(ResponseLandUse *)responseObject;
+ (BOOL)updateFromResponseObject:(ResponseLandUse *)responseObject;

- (NSArray *)getCollection;
+ (NSArray *)getCollection;
+ (LandUse *)landUseByCode:(NSString *)code;
+ (LandUse *)landUseByDisplayValue:(NSString *)displayValue;

@end
