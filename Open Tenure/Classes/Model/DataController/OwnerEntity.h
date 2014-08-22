//
//  OwnerEntity.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/15/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "AbstractEntity.h"

@class Owner;

@interface OwnerEntity : AbstractEntity

- (Owner *)create;

+ (Owner *)create;

+ (Owner *)createFromDictionary:(NSDictionary *)dictionary;

@end
