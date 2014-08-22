//
//  PersonEntity.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/7/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "AbstractEntity.h"

@interface PersonEntity : AbstractEntity

+ (Person *)create;

- (Person *)create;

+ (Person *)createFromDictionary:(NSDictionary *)object;

+ (Person *)getPersonByPersonId:(NSString *)personId;

@end
