//
//  AdditionalInfoEntity.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/13/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "AbstractEntity.h"

@class AdditionalInfo;

@interface AdditionalInfoEntity : AbstractEntity

+ (AdditionalInfo *)create;
- (AdditionalInfo *)create;

+ (AdditionalInfo *)createFromDictionary:(NSDictionary *)dictionary;

@end
