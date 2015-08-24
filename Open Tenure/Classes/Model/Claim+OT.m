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

#import "Claim+OT.h"
#import "ShapeKit.h"

@implementation Claim (OT)

- (void)setToTemporary {
    [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] setClaim:self];
}

+ (Claim *)getFromTemporary {
    return [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] claim];
}

- (BOOL)isSaved {
    return ![[self objectID] isTemporaryID];
}

- (OTViewType)getViewType {
    if ([self isSaved]) { // View claim
        if ([@[kClaimStatusChallenged,
              kClaimStatusModerated,
              kClaimStatusUnmoderated,
              kClaimStatusWithdrawn] containsObject:self.statusCode]) {
            return OTViewTypeView;
        } else {
            return OTViewTypeEdit;
        }
    } else { // Add claim
        return OTViewTypeAdd;
    }
}

- (NSDictionary *)dictionary {
    
    // matching managedObject vs jsonObject
    NSDictionary * const matching = @{
                                      @"claimId": @"id",
                                      @"claimName": @"description"
                                      
                                      };
    
    NSArray *keys = [[[self entity] attributesByName] allKeys];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[self dictionaryWithValuesForKeys:keys]];
    
    for (NSString *key in matching.allKeys) {
        if ([dict objectForKey:key] != nil) {
            [dict setObject:[dict objectForKey:key] forKey:[matching objectForKey:key]];
            [dict removeObjectForKey:key];
        }
    }
    
    [dict setObject:[NSNull null] forKey:@"gpsGeometry"];
    
    if (self.landUse != nil)
        [dict setObject:self.landUse.code forKey:@"landUseCode"];
    else
        [dict setObject:[NSNull null] forKey:@"landUseCode"];
    
    if (self.claimType != nil)
        [dict setObject:self.claimType.code forKey:@"typeCode"];
    else
        [dict setObject:[NSNull null] forKey:@"typeCode"];

    if (self.challenged != nil)
        [dict setObject:self.challenged.claimId forKey:@"challengedClaimId"];
    else
        [dict setObject:[NSNull null] forKey:@"challengedClaimId"];
    
    if (self.person != nil)
        [dict setObject:self.person.dictionary forKey:@"claimant"];
    else
        [dict setObject:[NSNull null] forKey:@"claimant"];

    if (self.attachments.count > 0) {
        NSMutableArray *array = [NSMutableArray array];
        for (Attachment *obj in self.attachments) {
            [array addObject:obj.dictionary];
        }
        [dict setObject:array forKey:@"attachments"];
    } else
        [dict setObject:@[] forKey:@"attachments"];
/*
    if (self.additionalInfo.count > 0) {
        NSMutableArray *array = [NSMutableArray array];
        for (AdditionalInfo *obj in self.additionalInfo) {
            [array addObject:obj.dictionary];
        }
        [dict setObject:array forKey:@"additionalInfos"];
    } else
        [dict setObject:@[] forKey:@"additionalInfos"];
*/
    if (self.shares.count > 0) {
        NSMutableArray *array = [NSMutableArray array];
        for (Share *obj in self.shares) {
            [array addObject:obj.dictionary];
        }
        [dict setObject:array forKey:@"shares"];
    } else
        [dict setObject:@[] forKey:@"shares"];

    if (self.locations.count > 0) {
        NSMutableArray *array = [NSMutableArray array];
        for (Location *obj in self.locations) {
            [array addObject:obj.dictionary];
        }
        [dict setObject:array forKey:@"locations"];
    } else
        [dict setObject:@[] forKey:@"locations"];
    
    // Dynamic Form
    if (self.dynamicForm != nil)
        [dict setObject:self.dynamicForm.dictionary forKey:@"dynamicForm"];
    
    return dict;
}

- (void)importFromJSON:(NSDictionary *)keyedValues {
    [self entityWithDictionary:keyedValues];
    
    NSDictionary * const matching = @{
                                      @"claimId": @"id",
                                      @"claimName": @"description"
                                      
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
    
    // get claimType
    ClaimTypeEntity *claimTypeEntity = [ClaimTypeEntity new];
    [claimTypeEntity setManagedObjectContext:self.managedObjectContext];
    NSArray *claimTypeCollection = [claimTypeEntity getCollection];
    NSString *typeCode = [keyedValues objectForKey:@"typeCode"];
    NSPredicate *claimTypePredicate = [NSPredicate predicateWithFormat:@"(code CONTAINS[cd] %@)", typeCode];
    ClaimType *claimType = [[claimTypeCollection filteredArrayUsingPredicate:claimTypePredicate] firstObject];
    self.claimType = claimType;
    
    // get landUseCode
    LandUseEntity *landUseEntity = [LandUseEntity new];
    [landUseEntity setManagedObjectContext:self.managedObjectContext];
    NSArray *landUseCollection = [landUseEntity getCollection];
    NSString *landUseCode = [keyedValues objectForKey:@"landUseCode"];
    NSPredicate *landUsePredicate = [NSPredicate predicateWithFormat:@"(code CONTAINS[cd] %@)", landUseCode];
    LandUse *landUse = [[landUseCollection filteredArrayUsingPredicate:landUsePredicate] firstObject];
    self.landUse = landUse;
    
    // create person
    PersonEntity *personEntity = [PersonEntity new];
    [personEntity setManagedObjectContext:self.managedObjectContext];
    NSDictionary *claimant = [keyedValues objectForKey:@"claimant"];
    Person *person = [personEntity create];
    [person importFromJSON:claimant];
    self.person = person;
    
    // create Attachment
    NSArray *attachments = [keyedValues objectForKey:@"attachments"];
    if (attachments.count > 0) {
        AttachmentEntity *attachmentEntity = [AttachmentEntity new];
        [attachmentEntity setManagedObjectContext:temporaryContext];
        for (NSDictionary *attachmentDict in attachments) {
            Attachment *attachment = [attachmentEntity create];
            [attachment importFromJSON:attachmentDict];
            attachment.claim = self;
        }
    }
    
    // create owners
    NSArray *shares = [keyedValues objectForKey:@"shares"];
    if (shares.count > 0) {
        ShareEntity *shareEntity = [ShareEntity new];
        [shareEntity setManagedObjectContext:self.managedObjectContext];
        for (NSDictionary *shareDict in shares) {
            Share *share = [shareEntity create];
            [share importFromJSON:shareDict];
            share.claim = self;
        }
    }
    
    // create locations
    NSArray *locations = [keyedValues objectForKey:@"locations"];
    if (locations.count > 0) {
        LocationEntity *locationEntity = [LocationEntity new];
        [locationEntity setManagedObjectContext:self.managedObjectContext];
        for (NSDictionary *locationDict in locations) {
            Location *location = [locationEntity create];
            [location importFromJSON:locationDict];
            location.claim = self;
        }
    }
    
    // create dynamicForm
    NSDictionary *dynamicFormJSON = [keyedValues objectForKey:@"dynamicForm"];
    if (dynamicFormJSON != nil && ![dynamicFormJSON isKindOfClass:[NSNull class]]) {
        FormPayloadEntity *entity = [FormPayloadEntity new];
        [entity setManagedObjectContext:self.managedObjectContext];
        FormPayload *entityObject = [entity createObject];
        [entityObject importFromJSON:dynamicFormJSON];
        self.dynamicForm = entityObject;
    }
}

- (BOOL)canBeUploaded {
    NSArray *conditional = @[kClaimStatusCreated, kClaimStatusUpdateError, kClaimStatusUpdateIncomplete, kClaimStatusUpdating, kClaimStatusUploadError, kClaimStatusUploadIncomplete, kClaimStatusUploading];
    return [conditional containsObject:self.statusCode];
}

- (void)withDraw{
    if (self.getViewType != OTViewTypeView) return;
    [CommunityServerAPI withdrawClaim:[self claimId] completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            ALog("Withdraw sucessfully");
            self.statusCode = kClaimStatusWithdrawn;
            [self.managedObjectContext save:nil];
            //[OT handleErrorWithMessage:NSLocalizedString(@"message_login_no_more_valid", nil)];
           [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"You have succefully withdrawn the claim", @"You have succefully withdrawn the claim")];
        }
    }
     ];
}

- (double)area {
    double area_ = 0.0f;
    if (self.mappedGeometry != nil) {
        ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:self.mappedGeometry];
        area_ = [polygon.geometry getArea];
        area_ = round(area_);
        NSInteger mod = (long)area_ % 10;
        area_ = mod > 8 ? area_ + 1 : (mod > 3 ? area_ - mod + 5 : area_ - mod);
    }
    return area_;
}

- (NSString *)getFullPath {
    NSString *docDir = [[FileSystemUtilities applicationDocumentsDirectory] path];
    NSString *claimsPath = [docDir stringByAppendingPathComponent:_CLAIMS_FOLDER];
    NSString *claimFolder = [_CLAIM_PREFIX stringByAppendingString:self.claimId];
    NSString *path = [claimsPath stringByAppendingPathComponent:claimFolder];
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        [FileSystemUtilities createClaimFolder:self.claimId];
    }
    return path;
}

- (NSString *)getCSVGeoData {
    NSMutableString *csvString = [NSMutableString stringWithString:@"SEQUENCE_NUMBER,GPS_LAT,GPS_LON,MAP_LAT,MAP_LON\n"];
    if (self.mappedGeometry != nil) {
        if (self.gpsGeometry != nil && [[self.gpsGeometry substringToIndex:7] isEqualToString:@"POLYGON"]) {
            ShapeKitPolygon *gpsPolygon = [[ShapeKitPolygon alloc] initWithWKT:self.gpsGeometry];
            ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:self.mappedGeometry];
            for (int i = 0; i < polygon.geometry.pointCount; i++) {
                CLLocationCoordinate2D coord = MKCoordinateForMapPoint(polygon.geometry.points[i]);
                CLLocationCoordinate2D gpsCoord = coord;
                if (i < gpsPolygon.geometry.pointCount) {
                    gpsCoord = MKCoordinateForMapPoint(gpsPolygon.geometry.points[i]);
                }
                [csvString appendFormat:@"%d,%f,%f,%f,%f\n", i, gpsCoord.latitude, gpsCoord.longitude, coord.latitude, coord.longitude];
            }
        } else {
            ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:self.mappedGeometry];
            for (int i = 0; i < polygon.geometry.pointCount; i++) {
                CLLocationCoordinate2D coord = MKCoordinateForMapPoint(polygon.geometry.points[i]);
                [csvString appendFormat:@"%d,%f,%f,%f,%f\n", i, coord.latitude, coord.longitude, coord.latitude, coord.longitude];
            }
        }
        return csvString;
    }
    return nil;
}

@end
