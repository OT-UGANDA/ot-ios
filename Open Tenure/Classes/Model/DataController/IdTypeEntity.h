//
//  IdTypeEntity.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/5/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "AbstractEntity.h"

@class ResponseIdType, IdType;

@interface IdTypeEntity : AbstractEntity

+ (BOOL)insertFromResponseObject:(ResponseIdType *)responseObject;
+ (BOOL)updateFromResponseObject:(ResponseIdType *)responseObject;

- (NSArray *)getCollection;
+ (NSArray *)getCollection;
+ (IdType *)idTypeByCode:(NSString *)code;
+ (IdType *)idTypeByDisplayValue:(NSString *)displayValue;

@end
