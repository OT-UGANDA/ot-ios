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

#import "FileSystemUtilities.h"

@implementation FileSystemUtilities


/**
 *
 * Create the folder under the application's documents directory.
 *
 **/

+ (BOOL)createFolder:(NSString *)folderName {
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:folderName isDirectory:&isDirectory]) {
        if (isDirectory)
            return YES;
        else {
            [NSException raise:@".data exists, and is a file" format:@"Path: %@", folderName];
            return NO;
        }
    }
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:folderName withIntermediateDirectories:YES attributes:nil error:&error]) {
        [NSException raise:@"Failed creating directory" format:@"[%@], %@", folderName, error];
        return NO;
    }
    return YES;
}

/**
 *
 * Create the folder that contains all the cliams under the application file
 * system
 *
 **/

+ (BOOL)createClaimsFolder {
    NSString *docDir = [[self applicationDocumentsDirectory] path];
    NSString *path = [docDir stringByAppendingPathComponent:_CLAIMS_FOLDER];
    return [self createFolder:path];
}

/**
 *
 * Create the OpenTenure folder under the the public file system Here will
 * be exported the compressed claim
 *
 **/

+ (BOOL)createOpenTenureFolder {
    NSString *docDir = [[self applicationDocumentsDirectory] path];
    NSString *path = [docDir stringByAppendingPathComponent:_OPEN_TENURE_FOLDER];
    return [self createFolder:path];
}

+ (BOOL)createClaimantsFolder {
    NSString *docDir = [[self applicationDocumentsDirectory] path];
    NSString *path = [docDir stringByAppendingPathComponent:_CLAIMANTS_FOLDER];
    return [self createFolder:path];
}

+ (BOOL)createClaimFolder:(NSString *)claimId {
    NSString *claimsPath = [self getClaimsFolder];
    NSString *claimFolder = [_CLAIM_PREFIX stringByAppendingString:claimId];
    NSString *path = [claimsPath stringByAppendingPathComponent:claimFolder];
    NSString *fullPath = [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:path];
    if ([self createFolder:fullPath]) {
        path = [path stringByAppendingPathComponent:_ATTACHMENT_FOLDER];
        return [self createFolder:fullPath];
    }
    return NO;
}

+ (BOOL)createClaimantFolder:(NSString *)personId {
    NSString *claimantsPath = [self getClaimantsFolder];
    NSString *claimantFolder = [_CLAIMANT_PREFIX stringByAppendingString:personId];
    NSString *path = [claimantsPath stringByAppendingPathComponent:claimantFolder];
    path = [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:path];
    return [self createFolder:path];
}

+ (BOOL)removeClaimantFolder:(NSString *)personId {
    NSString *claimantsPath = [self getClaimantsFolder];
    NSString *claimantFolder = [_CLAIMANT_PREFIX stringByAppendingString:personId];
    NSString *path = [claimantsPath stringByAppendingPathComponent:claimantFolder];
    path = [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:path];
    return [self deleteFile:path];
}

+ (BOOL)deleteClaim:(NSString *)claimId {
    NSString *claimsPath = [self getClaimsFolder];
    NSString *claimFolder = [_CLAIM_PREFIX stringByAppendingString:claimId];
    NSString *path = [claimsPath stringByAppendingPathComponent:claimFolder];
    path = [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:path];
    return [self deleteFile:path];
}

+ (BOOL)deleteClaimant:(NSString *)personId {
    NSString *claimantsPath = [self getClaimantsFolder];
    NSString *claimantFolder = [_CLAIMANT_PREFIX stringByAppendingString:personId];
    NSString *path = [claimantsPath stringByAppendingPathComponent:claimantFolder];
    path = [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:path];
    return [self deleteFile:path];
}

+ (BOOL)deleteFile:(NSString *)file {
    if (![[NSFileManager defaultManager] fileExistsAtPath:file])
        return YES;
    NSError *error = nil;
    if ([file isEqualToString:@".DS_Store"])
        return NO;
    if (![[NSFileManager defaultManager] removeItemAtPath:file error: &error]) {
        [NSException raise:@"Unable to remove file: error" format:@"[%@], %@", file, error];
        return NO;
    }
    return YES;
}

+ (BOOL)deleteCompressedClaim:(NSString *)claimId {
    return [self deleteFile:[self getCompressClaim:claimId]];
}

+ (BOOL)deleteDocumentsFolder {
    BOOL status = YES;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager removeItemAtPath:documentsDirectory error:nil]) {
        status = NO;
    }
    return status;
}

+ (int)getUploadProgress:(Claim *)claim {
    // TODO: After create model
    return 0;
}

+ (NSString *)getClaimsFolder {
    NSString *docDir = [[self applicationDocumentsDirectory] path];
    NSString *path = [docDir stringByAppendingPathComponent:_CLAIMS_FOLDER];
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        [self createClaimsFolder];
    }
    return _CLAIMS_FOLDER;
}

+ (NSString *)getClaimantsFolder {
    NSString *docDir = [[self applicationDocumentsDirectory] path];
    NSString *path = [docDir stringByAppendingPathComponent:_CLAIMANTS_FOLDER];
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        [self createClaimantsFolder];
    }
    return _CLAIMANTS_FOLDER;
}

+ (NSString *)getClaimFolder:(NSString *)claimId {
    NSString *docDir = [[self applicationDocumentsDirectory] path];
    NSString *claimsPath = [docDir stringByAppendingPathComponent:_CLAIMS_FOLDER];
    NSString *claimFolder = [_CLAIM_PREFIX stringByAppendingString:claimId];
    NSString *path = [claimsPath stringByAppendingPathComponent:claimFolder];
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        [self createClaimFolder:claimId];
    }
    return [[self getClaimsFolder] stringByAppendingPathComponent:claimFolder];
}

+ (NSString *)getClaimantFolder:(NSString *)claimId {
    NSString *docDir = [[self applicationDocumentsDirectory] path];
    NSString *claimantsPath = [docDir stringByAppendingPathComponent:_CLAIMANTS_FOLDER];
    BOOL isDirectory;
    NSString *claimantFolder = [_CLAIMANT_PREFIX stringByAppendingString:claimId];
    NSString *path = [claimantsPath stringByAppendingPathComponent:claimantFolder];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        [self createClaimantFolder:claimId];
    }
    return [[self getClaimantsFolder] stringByAppendingPathComponent:claimantFolder];
}

+ (NSString *)getAttachmentFolder:(NSString *)claimId {
    NSString *claimPath = [self getClaimFolder:claimId];
    NSString *path = [claimPath stringByAppendingPathComponent:_ATTACHMENT_FOLDER];
    BOOL isDirectory;
    NSString *fullPath = [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:path];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory]) {
        [self createFolder:fullPath];
    }
    return path;
}

+ (NSString *)getCompressClaim:(NSString *)claimId {
    NSString *openTenurePath = [self getOpentenureFolder];
    NSString *compressedClaim = [@"claim_" stringByAppendingString:claimId];
    NSString *compressedClaimPath = [openTenurePath stringByAppendingPathComponent:compressedClaim];
    NSString *path = [compressedClaimPath stringByAppendingPathExtension:@"zip"];
    return path;
}

+ (NSString *)getOpentenureFolder {
    NSString *docDir = [[self applicationDocumentsDirectory] path];
    NSString *path = [docDir stringByAppendingPathComponent:_OPEN_TENURE_FOLDER];
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        [self createOpenTenureFolder];
    }
    return path;
}

+ (BOOL)copyFileInAttachFolder:(NSString *)destination source:(NSString *)source {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *sourceURL = [[NSURL alloc] initFileURLWithPath:source];
    NSURL *destinationURL = [[NSURL alloc] initFileURLWithPath:destination];
    NSError *errorCopy;
    
    // For the purposes of testing, remove any esisting file at the destination.
    [fileManager removeItemAtURL:destinationURL error:NULL];
    BOOL success = [fileManager copyItemAtURL:sourceURL toURL:destinationURL error:&errorCopy];
    ALog(@"Error %@", errorCopy.description);
    return success;
}

+ (NSString *)getJsonClaim:(NSString *)claimId {
    NSString *claimFolder = [self getClaimFolder:claimId];
    NSString *jsonFile = [claimFolder stringByAppendingPathComponent:@"claim.json"];
    NSString *jsonString = [NSString stringWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    return [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:jsonString];
}

+ (NSString *)getJsonAttachment:(NSString *)attachmentId {
    
    return nil;
}

+ (NSString *)matchTypeCode:(NSString *)original {
    
    return nil;
}

/**
 *
 * Returns the path to the application's documents directory.
 *
 * **/

+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

/**
 *
 * Returns the Private Documents path to the application's Library directory.
 *
 * **/

+ (NSURL *)applicationHiddenDocumentsDirectory {
    NSURL *libUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *hiddenUrl = [libUrl URLByAppendingPathComponent:@"Private Documents"];
    
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:hiddenUrl.path isDirectory:&isDirectory]) {
        if (isDirectory)
            return hiddenUrl;
        else {
            [NSException raise:@".data exists, and is a file" format:@"Path: %@", hiddenUrl];
        }
    }
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtURL:hiddenUrl withIntermediateDirectories:YES attributes:nil error:&error]) {
        // Handle error.
        [NSException raise:@"Failed creating directory" format:@"[%@], %@", hiddenUrl, error];
    }
    return hiddenUrl;
}

+ (BOOL)copyFileFromSource:(NSURL *)source toDestination:(NSURL *)destination {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *errorCopy;
    // For the purposes of testing, remove any esisting file at the destination.
    [fileManager removeItemAtURL:destination error:NULL];
    BOOL success = [fileManager copyItemAtURL:source toURL:destination error:&errorCopy];
    return success;
}

@end
