//
//  ClaimTypeEntity.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/6/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "AbstractEntity.h"

@class ResponseClaimType, ClaimType;
@interface ClaimTypeEntity : AbstractEntity

+ (BOOL)insertFromResponseObject:(ResponseClaimType *)responseObject;
+ (BOOL)updateFromResponseObject:(ResponseClaimType *)responseObject;

- (NSArray *)getCollection;
+ (NSArray *)getCollection;
+ (ClaimType *)claimTypeByCode:(NSString *)code;
+ (ClaimType *)claimTypeByDisplayValue:(NSString *)displayValue;

@end
