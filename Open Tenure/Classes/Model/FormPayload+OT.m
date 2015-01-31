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

#import "FormPayload+OT.h"

@implementation FormPayload (OT)

- (NSDictionary *)dictionary {
    
    // matching managedObject vs jsonObject
    NSDictionary * const matching = @{@"attributeId": @"id"};
    
    NSArray *keys = [[[self entity] attributesByName] allKeys];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[self dictionaryWithValuesForKeys:keys]];
    
    for (NSString *key in matching.allKeys) {
        if ([dict objectForKey:key] != nil) {
            [dict setObject:[dict objectForKey:key] forKey:[matching objectForKey:key]];
            [dict removeObjectForKey:key];
        }
    }
    
    // Bổ sung thông tin từ formTemplate
    [dict setObject:self.claim.claimId forKey:@"claimId"];
    [dict setObject:self.formTemplate.name forKey:@"formTemplateName"];
    
    // SectionElementPayload dictionary
    NSMutableArray *array = [NSMutableArray array];
    for (SectionPayload *obj in self.sectionPayloadList) {
        [array addObject:obj.dictionary];
    }
    [dict setObject:array forKey:@"sectionPayloadList"];
    
    return dict;
}

- (void)importFromJSON:(NSDictionary *)keyedValues {
    [self entityWithDictionary:keyedValues];
    
    NSDictionary * const matching = @{@"attributeId": @"id"};
    
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
    
    // Assign FormTemplate
    FormTemplateEntity *entity = [FormTemplateEntity new];
    [entity setManagedObjectContext:self.managedObjectContext];
    FormTemplate *entityObject = [entity getEntityByName:[keyedValues objectForKey:@"formTemplateName"]];
    if (entityObject != nil)
        self.formTemplate = entityObject;

    // Create SectionPayload
    NSArray *objects = [keyedValues objectForKey:@"sectionPayloadList"];
    SectionPayloadEntity *sectionPayloadEntity = [SectionPayloadEntity new];
    [sectionPayloadEntity setManagedObjectContext:self.managedObjectContext];
    for (NSDictionary *object in objects) {
        SectionPayload *entityObject = [sectionPayloadEntity createObject];
        [entityObject importFromJSON:object];
        entityObject.formPayload = self;
        
        // Assign SectionTemplate
        SectionTemplateEntity *sectionTemplateEntity = [SectionTemplateEntity new];
        [sectionTemplateEntity setManagedObjectContext:self.managedObjectContext];
        SectionTemplate *sectionTemplate = [sectionTemplateEntity getEntityByName:[object objectForKey:@"name"]];
        entityObject.sectionTemplate = sectionTemplate;
    }
}

@end
