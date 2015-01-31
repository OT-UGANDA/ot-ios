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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AdditionalInfo, Attachment, Claim, ClaimType, LandUse, Person, Share, Location, FormPayload;

@interface Claim : NSManagedObject

@property (nonatomic, retain) NSString * challengeExpiryDate;
@property (nonatomic, retain) NSString * challengedClaimId;
@property (nonatomic, retain) NSString * claimId;
@property (nonatomic, retain) NSString * claimName;
@property (nonatomic, retain) NSString * decisionDate;
@property (nonatomic, retain) NSString * eastAdjacency;
@property (nonatomic, retain) NSString * gpsGeometry;
@property (nonatomic, retain) NSString * lodgementDate;
@property (nonatomic, retain) NSString * mappedGeometry;
@property (nonatomic, retain) NSString * northAdjacency;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSString * nr;
@property (nonatomic, retain) NSString * recorderName;
@property (nonatomic, retain) NSString * southAdjacency;
@property (nonatomic, retain) NSString * startDate;
@property (nonatomic, retain) NSString * statusCode;
@property (nonatomic, retain) NSString * westAdjacency;
@property (nonatomic, retain) NSSet *additionalInfo;
@property (nonatomic, retain) NSSet *attachments;
@property (nonatomic, retain) Claim *challenged;
@property (nonatomic, retain) NSSet *challenges;
@property (nonatomic, retain) ClaimType *claimType;
@property (nonatomic, retain) LandUse *landUse;
@property (nonatomic, retain) NSSet *shares;
@property (nonatomic, retain) Person *person;
@property (nonatomic, retain) NSSet *locations;
@property (nonatomic, retain) FormPayload *dynamicForm;

@end

@interface Claim (CoreDataGeneratedAccessors)

- (void)addAdditionalInfoObject:(AdditionalInfo *)value;
- (void)removeAdditionalInfoObject:(AdditionalInfo *)value;
- (void)addAdditionalInfo:(NSSet *)values;
- (void)removeAdditionalInfo:(NSSet *)values;

- (void)addAttachmentsObject:(Attachment *)value;
- (void)removeAttachmentsObject:(Attachment *)value;
- (void)addAttachments:(NSSet *)values;
- (void)removeAttachments:(NSSet *)values;

- (void)addChallengesObject:(Claim *)value;
- (void)removeChallengesObject:(Claim *)value;
- (void)addChallenges:(NSSet *)values;
- (void)removeChallenges:(NSSet *)values;

- (void)addSharesObject:(Share *)value;
- (void)removeSharesObject:(Share *)value;
- (void)addShares:(NSSet *)values;
- (void)removeShares:(NSSet *)values;

- (void)addLocationsObject:(Location *)value;
- (void)removeLocationsObject:(Location *)value;
- (void)addLocations:(NSSet *)values;
- (void)removeLocations:(NSSet *)values;

@end
