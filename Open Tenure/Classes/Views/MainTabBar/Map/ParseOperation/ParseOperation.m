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
#import "ParseOperation.h"
#import "ClaimParser.h"

@interface ParseOperation () <ClaimParserDelegate> {
    NSUInteger _parsedClaimsCounter;
}

@property (nonatomic, strong) Claim *claim;
@property (nonatomic, strong) ClaimType *claimType;
@property (nonatomic, strong) LandUse *landUse;
@property (nonatomic, strong) Person *person;
@property (nonatomic, strong) IdType *idType;
@property (nonatomic, strong) Owner *owner;
@property (nonatomic, strong) AdditionalInfo *additionalInfo;
@property (nonatomic, strong) Attachment *attachment;
@property (nonatomic, strong) DocumentType *documentType;

@property (nonatomic, strong) ClaimEntity *claimEntity;
@property (nonatomic, strong) ClaimTypeEntity *claimTypeEntity;
@property (nonatomic, strong) LandUseEntity *landUseEntity;
@property (nonatomic, strong) PersonEntity *personEntity;
@property (nonatomic, strong) IdTypeEntity *idTypeEntity;
@property (nonatomic, strong) OwnerEntity *ownerEntity;
@property (nonatomic, strong) AdditionalInfoEntity *additionalInfoEntity;
@property (nonatomic, strong) AttachmentEntity *attachmentEntity;
@property (nonatomic, strong) DocumentTypeEntity *documentTypeEntity;

@property (nonatomic, strong) NSArray *claimsToDownload;

@property (nonatomic) NSMutableArray *currentParseBatch;

@property (strong) NSManagedObjectContext *managedObjectContext;
@property (strong) NSPersistentStoreCoordinator *sharedPSC;

@end

@implementation ParseOperation

- (id)initWithResponseClaims:(NSArray *)responseClaims sharedPSC:(NSPersistentStoreCoordinator *)psc {
    if (self = [super init]) {
        _claimEntity = [ClaimEntity new];
        _claimTypeEntity = [ClaimTypeEntity new];
        _landUseEntity = [LandUseEntity new];
        _personEntity = [PersonEntity new];
        _idTypeEntity = [IdTypeEntity new];
        _ownerEntity = [OwnerEntity new];
        _additionalInfoEntity = [AdditionalInfoEntity new];
        _documentTypeEntity = [DocumentTypeEntity new];
        
        _responseClaims = responseClaims;
        _currentParseBatch = [[NSMutableArray alloc] init];
        
        self.sharedPSC = psc;
    }
    return self;
}

/*!
 Kiểm tra sự tồn tại của claim trên local (những claim đã tải về). Cập nhật trạng thái cho các claims đã tải về nếu có sự thay đổi từ phía server.
 @result
 Danh sách các claim mới tải về
 */
- (NSArray *)getValidResponseClaimList:(NSMutableArray *)objects {
    NSMutableArray *newResponseObject = [NSMutableArray array];
    for (NSDictionary *object in objects) {
        ResponseClaim *responseObject = [ResponseClaim claimWithDictionary:object];
        //if ([ClaimEntity updateFromResponseObject:responseObject]) {
            [newResponseObject addObject:responseObject];
        //}
    }
    return newResponseObject;
}

- (void)addClaimsToList:(NSArray *)claims {
    
    if ([self.managedObjectContext hasChanges]) {
        if (![self.managedObjectContext save:nil]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application, although it may be useful
            // during development. If it is not possible to recover from the error, display an alert
            // panel that instructs the user to quit the application by pressing the Home button.
            //
            NSLog(@"Unresolved error");
            abort();
        }
    }
}

- (void)main {
    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    self.managedObjectContext.persistentStoreCoordinator = self.sharedPSC;

    for (ResponseClaim *responseClaim in _responseClaims) {
        [self downloadClaim:responseClaim.claimId];
    }
    
    if ([self.currentParseBatch count] > 0) {
        [self addClaimsToList:self.currentParseBatch];
    }
    
}

- (void)downloadClaim:(NSString *)claimId {
    
    [CommunityServerAPI getClaim:claimId completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self processClaimData:nil];
            _parsedClaimsCounter++;
            [self.currentParseBatch addObject:@"string"];
        });
    }];

}

- (void)processClaimData:(NSData *)data {
    NSLog(@"string");
}

- (void)claimParser:(ClaimParser *)claimParser didEndElement:(NSData *)data {
    NSLog(@"didEndElement");
}

@end
