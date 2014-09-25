//
//  Share+OT.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 9/23/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "Share+OT.h"

@implementation Share (OT)

- (NSDictionary *)dictionary {
    
    // matching managedObject vs jsonObject
    NSDictionary * const matching = @{
                                      @"shareId": @"id",
                                      
                                      };
    
    NSArray *keys = [[[self entity] attributesByName] allKeys];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[self dictionaryWithValuesForKeys:keys]];
    
    for (NSString *key in matching.allKeys) {
        if ([dict objectForKey:key] != nil) {
            [dict setObject:[dict objectForKey:key] forKey:[matching objectForKey:key]];
            [dict removeObjectForKey:key];
        }
    }
    
    if (self.owners.count > 0) {
        NSMutableArray *array = [NSMutableArray array];
        for (Person *obj in self.owners) {
            [array addObject:obj.dictionary];
        }
        [dict setObject:array forKey:@"owners"];
    } else
        [dict setObject:@[] forKey:@"owners"];
    
    return dict;
}

- (void)importFromJSON:(NSDictionary *)keyedValues {
    [self entityWithDictionary:keyedValues];
    
    NSDictionary * const matching = @{
                                      @"shareId": @"id",
                                      
                                      };
    
    NSDictionary *attributes = [[self entity] attributesByName];
    for (NSString *key in matching.allKeys) {
        id value = [keyedValues objectForKey:[matching objectForKey:key]];
        if (value == nil || [value isKindOfClass:[NSNull class]]) {
            continue;
        }
        NSAttributeType attributeType = [[attributes objectForKey:key] attributeType];
        if ((attributeType == NSStringAttributeType) && ([value isKindOfClass:[NSNumber class]])) {
            value = [value stringValue];
        } else if (((attributeType == NSInteger16AttributeType) || (attributeType == NSInteger32AttributeType) || (attributeType == NSInteger64AttributeType) || (attributeType == NSBooleanAttributeType)) && ([value isKindOfClass:[NSString class]])) {
            value = [NSNumber numberWithInteger:[value integerValue]];
        } else if ((attributeType == NSFloatAttributeType) &&  ([value isKindOfClass:[NSString class]])) {
            value = [NSNumber numberWithDouble:[value doubleValue]];
        }
        [self setValue:value forKey:key];
    }
    
    // Add shares
    NSArray *shares = [keyedValues objectForKey:@"shares"];
    if (shares.count > 0) {
        PersonEntity *personEntity = [PersonEntity new];
        [personEntity setManagedObjectContext:self.managedObjectContext];
        for (NSArray *owners in shares) {
            for (NSDictionary *personDict in owners) {
                Person *person = [personEntity create];
                [person importFromJSON:personDict];
                person.owner = self;
            }
        }
    }
}

@end
