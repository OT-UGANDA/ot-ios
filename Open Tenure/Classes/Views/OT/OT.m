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


#import "OT.h"

NSString * const kLoginSuccessNotificationName = @"LoginSuccessNotificationName";
NSString * const kLogoutSuccessNotificationName = @"LogoutSuccessNotificationName";
NSString * const kGetAllClaimsSuccessNotificationName = @"GetAllClaimsSuccessNotificationName";

NSString * const kResponseClaimsErrorNotificationName = @"ResponseClaimsErrorNotificationName";
NSString * const kResponseClaimsMessageErrorKey = @"ResponseClaimsMessageErrorKey";

NSString * const kWithdrawClaimSuccessNotificationName = @"WithdrawClaimSuccessNotificationName";
NSString * const kGetClaimSuccessNotificationName = @"GetClaimSuccessNotificationName";

NSString * const kClaimStatusCreated = @"created";
NSString * const kClaimStatusUploading = @"uploading";
NSString * const kClaimStatusUnmoderated = @"unmoderated";
NSString * const kClaimStatusModerated = @"moderated";
NSString * const kClaimStatusChallenged = @"challenged";
NSString * const kClaimStatusUploadIncomplete = @"upload_incomplete";
NSString * const kClaimStatusUploadError = @"upload_error";
NSString * const kClaimStatusWithdrawn = @"withdrawn";

NSString * const kAttachmentStatusCreated = @"created";
NSString * const kAttachmentStatusUploading = @"uploading";
NSString * const kAttachmentStatusUploaded = @"uploaded";
NSString * const kAttachmentStatusDeleted = @"deleted";
NSString * const kAttachmentStatusUpload_Incomplete = @"upload_incomplete";
NSString * const kAttachmentStatusUpload_Error = @"upload_error";
NSString * const kAttachmentStatusDownload_Incomplete = @"download_incomplete";
NSString * const kAttachmentStatusDownload_Failed = @"download_failed";
NSString * const kAttachmentStatusDownloading = @"downloading";

NSString * const kPersonTypePhysical = @"physical";
NSString * const kPersonTypeGroup = @"group";

@implementation OT

+ (void)handleError:(NSError *)error {
    NSString *errorMessage = [error localizedDescription];
    [SVProgressHUD showErrorWithStatus:errorMessage];
}

+ (void)handleErrorWithMessage:(NSString *)message {
    [SVProgressHUD showErrorWithStatus:message];
}

+ (NSDateFormatter *)dateFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    return dateFormatter;
}

+ (void)updateIdType {
    [CommunityServerAPI getIdTypesWithCompletionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSMutableArray *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    for (NSDictionary *object in objects) {
                        ResponseIdType *responseObject = [[ResponseIdType alloc] initWithDictionary:object];
                        [IdTypeEntity updateFromResponseObject:responseObject];
                    }
                }
            } else {
                NSString *errorString = NSLocalizedString(@"error_generic_conection", @"An error has occurred during connection");
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

+ (void)updateLandUse {
    [CommunityServerAPI getLandUsesWithCompletionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSMutableArray *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    for (NSDictionary *object in objects) {
                        ResponseLandUse *responseObject = [ResponseLandUse landUseWithDictionary:object];
                        [LandUseEntity updateFromResponseObject:responseObject];
                    }
                }
            } else {
                NSString *errorString = NSLocalizedString(@"error_generic_conection", @"An error has occurred during connection");
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

+ (void)updateClaimType {
    [CommunityServerAPI getClaimTypesWithCompletionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSMutableArray *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    for (NSDictionary *object in objects) {
                        ResponseClaimType *responseObject = [ResponseClaimType claimTypeWithDictionary:object];
                        [ClaimTypeEntity updateFromResponseObject:responseObject];
                    }
                }
            } else {
                NSString *errorString = NSLocalizedString(@"error_generic_conection", @"An error has occurred during connection");
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

+ (void)updateDocumentType {
    [CommunityServerAPI getDocumentTypesWithCompletionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSMutableArray *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    for (NSDictionary *object in objects) {
                        ResponseDocumentType *responseObject = [ResponseDocumentType documentTypeWithDictionary:object.deserialize];
                        [DocumentTypeEntity updateFromResponseObject:responseObject];
                    }
                }
            } else {
                NSString *errorString = NSLocalizedString(@"error_generic_conection", @"An error has occurred during connection");
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

@end
