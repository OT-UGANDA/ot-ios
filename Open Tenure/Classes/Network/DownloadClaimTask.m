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

#import "DownloadClaimTask.h"

@interface DownloadClaimTask ()

@property (nonatomic, strong) NSString *claimId;

@end

@implementation DownloadClaimTask

- (id)initWithClaimId:(NSString *)claimId {
    if (self = [super init]) {
        _claimId = claimId;
    }
    return self;
}

- (void)main {
    ALog(@"Downloading %@", _claimId);
    [CommunityServerAPI getClaim:_claimId completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
            [_delegate downloadClaimTask:self didFinishWithSuccess:NO];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                    [_delegate downloadClaimTask:self didFinishWithSuccess:NO];
                } else {
                    ClaimEntity *claimEntity = [ClaimEntity new];
                    [claimEntity setManagedObjectContext:temporaryContext];
                    Claim *claim = [claimEntity create];
                    [claim importFromJSON:object];
                    
                    
                    
                    // Tạo
/*
                    @property (nonatomic, retain) NSSet *additionalInfo;
OK                    @property (nonatomic, retain) NSSet *attachments;
OK                    @property (nonatomic, retain) NSSet *owners;
OK                    @property (nonatomic, retain) ClaimType *claimType;
OK                    @property (nonatomic, retain) LandUse *landUse;
OK                    @property (nonatomic, retain) Person *person;
                    @property (nonatomic, retain) Claim *challenged;
*/
                    _claim = claim;
                    
                    [_delegate downloadClaimTask:self didFinishWithSuccess:YES];
                }
            } else {
                NSString *errorString = NSLocalizedString(@"error_generic_conection", @"An error has occurred during connection");
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
                [_delegate downloadClaimTask:self didFinishWithSuccess:NO];
            }
        }
    }];
}

@end
