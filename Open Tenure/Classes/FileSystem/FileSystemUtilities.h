//
//  FileSystemUtilities.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 7/27/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import <Foundation/Foundation.h>

@class Claim;
@interface FileSystemUtilities : NSObject

#define _CLAIMS_FOLDER @"claims"
#define _CLAIMANTS_FOLDER @"claimants"
#define _CLAIM_PREFIX @"claim_"
#define _CLAIMANT_PREFIX @"claimant_"
#define _ATTACHMENT_FOLDER @"attachments"
#define _OPEN_TENURE_FOLDER @"Open Tenure"

+ (BOOL)createFolder:(NSString *)folderName;
+ (BOOL)createClaimsFolder;
+ (BOOL)createOpenTenureFolder;
+ (BOOL)createClaimantsFolder;
+ (BOOL)createClaimFolder:(NSString *)claimId;
+ (BOOL)createClaimantFolder:(NSString *)personId;
+ (BOOL)removeClaimantFolder:(NSString *)personId;
+ (BOOL)deleteClaim:(NSString *)claimId;
+ (BOOL)deleteClaimant:(NSString *)personId;
+ (BOOL)deleteFile:(NSString *)file;
+ (BOOL)deleteCompressedClaim:(NSString *)claimId;
+ (int)getUploadProgress:(Claim *)claim;
+ (NSString *)getClaimsFolder;
+ (NSString *)getClaimantsFolder;
+ (NSString *)getClaimFolder:(NSString *)claimId;
+ (NSString *)getAttachmentFolder:(NSString *)claimId;
+ (NSString *)getCompressClaim:(NSString *)claimId;
+ (NSString *)getOpentenureFolder;
+ (BOOL)copyFileInAttachFolder:(NSString *)claimId source:(NSString *)source;
+ (NSString *)getJsonClaim:(NSString *)claimId;
+ (NSString *)getJsonAttachment:(NSString *)attachmentId;
+ (NSString *)matchTypeCode:(NSString *)original;

+ (NSString *)getClaimantImagePath:(NSString *)personId;

+ (NSURL *)applicationDocumentsDirectory;
+ (NSURL *)applicationHiddenDocumentsDirectory;

+ (BOOL)copyFileFromSource:(NSURL *)source toDestination:(NSURL *)destination;

@end
