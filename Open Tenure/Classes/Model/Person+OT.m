/**
 * ******************************************************************************************
 * Copyright (C) 2014 - Food and Agriculture Organization of the United Nations (FAO).
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice,this list
 *       of conditions and the following disclaimer.
 *    2. Redistributions in binary form must reproduce the above copyright notice,this list
 *       of conditions and the following disclaimer in the documentation and/or other
 *       materials provided with the distribution.
 *    3. Neither the name of FAO nor the names of its contributors may be used to endorse or
 *       promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,STRICT LIABILITY,OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * *********************************************************************************************
 */

#import "Person+OT.h"

@implementation Person (OT)

- (void)setToTemporary {
    [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] setPerson:self];
}

+ (Person *)getFromTemporary {
    return [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] person];
}

- (NSString *)fullNameType:(OTFullNameType)type {
    switch (type) {
        case OTFullNameTypeDefault:
            if (self.lastName != nil || self.lastName.length > 0)
                return [NSString stringWithFormat:@"%@ %@", self.name, self.lastName];
            else
                return [NSString stringWithFormat:@"%@", self.name];
            break;
        case OTFullNameType1:
            if (self.lastName != nil || self.lastName.length > 0)
                return [NSString stringWithFormat:@"%@ %@", self.lastName, self.name];
            else
                return [NSString stringWithFormat:@"%@", self.lastName];
            break;
    }
    return nil;
}

- (BOOL)isSaved {
    return ![[self objectID] isTemporaryID];
}

- (OTViewType)getViewType {
    if ([self isSaved]) { // View person/group
        if (self.owner != nil)
            return self.owner.claim.getViewType;
        else
            return self.claim.getViewType;
    } else { // Add person/group
        return OTViewTypeAdd;
    }
}

- (NSDictionary *)dictionary {

    // matching managedObject vs jsonObject
    NSDictionary * const matching = @{
                                      @"personId": @"id",
                                      
                                      };
    
    NSArray *keys = [[[self entity] attributesByName] allKeys];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[self dictionaryWithValuesForKeys:keys]];
    
    for (NSString *key in matching.allKeys) {
        if ([dict objectForKey:key] != nil) {
            [dict setObject:[dict objectForKey:key] forKey:[matching objectForKey:key]];
            [dict removeObjectForKey:key];
        }
    }
    [dict setValue:[NSNumber numberWithBool:[[dict valueForKey:@"person"] boolValue]] forKey:@"person"];

    return dict;
}

- (void)importFromJSON:(NSDictionary *)keyedValues {
    [self entityWithDictionary:keyedValues];
    
    NSDictionary * const matching = @{
                                      @"personId": @"id",
                                      
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
}

- (Person *)clone {
    PersonEntity *personEntity = [PersonEntity new];
    [personEntity setManagedObjectContext:self.managedObjectContext];
    Person *person = [personEntity create];

    NSDictionary *attributes = [[self entity] attributesByName];
    for (NSString *attribute in attributes) {
        [person setValue:[self valueForKey:attribute] forKey:attribute];
    }
    person.personId = [[[NSUUID UUID] UUIDString] lowercaseString];
    
    return person;
}

- (NSString *)getFullPath {
    NSString *claimAttachmentsFolder = nil;
    if (self.claim != nil) {
        claimAttachmentsFolder = [[self.claim getFullPath] stringByAppendingPathComponent:_ATTACHMENT_FOLDER];
    } else if (self.owner != nil) {
        claimAttachmentsFolder = [[self.owner.claim getFullPath] stringByAppendingPathComponent:_ATTACHMENT_FOLDER];
    }
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:claimAttachmentsFolder isDirectory:&isDirectory]) {
        [FileSystemUtilities createFolder:claimAttachmentsFolder];
    }
    if (claimAttachmentsFolder != nil) {
        NSString *fileName = [self.personId stringByAppendingPathExtension:@"jpg"];
        return [claimAttachmentsFolder stringByAppendingPathComponent:fileName];
    }
    return nil;
}

@end
