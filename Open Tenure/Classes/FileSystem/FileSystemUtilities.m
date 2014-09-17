//
//  FileSystemUtilities.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 7/27/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

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
    
    if ([self createFolder:path]) {
        path = [path stringByAppendingPathComponent:_ATTACHMENT_FOLDER];
        return [self createFolder:path];
    }
    return NO;
}

+ (BOOL)createClaimantFolder:(NSString *)personId {
    NSString *claimantsPath = [self getClaimantsFolder];
    NSString *claimantFolder = [_CLAIMANT_PREFIX stringByAppendingString:personId];
    NSString *path = [claimantsPath stringByAppendingPathComponent:claimantFolder];
    return [self createFolder:path];
}

+ (BOOL)removeClaimantFolder:(NSString *)personId {
    NSString *claimantsPath = [self getClaimantsFolder];
    NSString *claimantFolder = [_CLAIMANT_PREFIX stringByAppendingString:personId];
    NSString *path = [claimantsPath stringByAppendingPathComponent:claimantFolder];
    return [self deleteFile:path];
}

+ (BOOL)deleteClaim:(NSString *)claimId {
    NSString *claimsPath = [self getClaimsFolder];
    NSString *claimFolder = [_CLAIM_PREFIX stringByAppendingString:claimId];
    NSString *path = [claimsPath stringByAppendingPathComponent:claimFolder];
    return [self deleteFile:path];
}

+ (BOOL)deleteClaimant:(NSString *)personId {
    NSString *claimantsPath = [self getClaimantsFolder];
    NSString *claimantFolder = [_CLAIMANT_PREFIX stringByAppendingString:personId];
    NSString *path = [claimantsPath stringByAppendingPathComponent:claimantFolder];
    return [self deleteFile:path];
}

+ (BOOL)deleteFile:(NSString *)file {
    if (![[NSFileManager defaultManager] fileExistsAtPath:file])
        return YES;
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:file error: &error]) {
        [NSException raise:@"Unable to remove file: error" format:@"[%@], %@", file, error];
        return NO;
    }
    return YES;
}

+ (BOOL)deleteCompressedClaim:(NSString *)claimId {
    return [self deleteFile:[self getCompressClaim:claimId]];
}

+ (int)getUploadProgress:(Claim *)claim {
    // TODO: After create model
    return 0;
}

+ (NSString *)getClaimsFolder {
    NSString *docDir = [[self applicationDocumentsDirectory] path];
    NSString *path = [docDir stringByAppendingPathComponent:_CLAIMS_FOLDER];
    return path;
}

+ (NSString *)getClaimantsFolder {
    NSString *docDir = [[self applicationDocumentsDirectory] path];
    NSString *path = [docDir stringByAppendingPathComponent:_CLAIMANTS_FOLDER];
    return path;
}

+ (NSString *)getClaimFolder:(NSString *)claimId {
    NSString *docDir = [[self applicationDocumentsDirectory] path];
    NSString *claimsPath = [docDir stringByAppendingPathComponent:_CLAIMS_FOLDER];
    NSString *claimFolder = [_CLAIM_PREFIX stringByAppendingString:claimId];
    NSString *path = [claimsPath stringByAppendingPathComponent:claimFolder];
    return path;
}

+ (NSString *)getAttachmentFolder:(NSString *)claimId {
    NSString *claimPath = [self getClaimFolder:claimId];
    NSString *path = [claimPath stringByAppendingPathComponent:_ATTACHMENT_FOLDER];
    return path;
}

+ (NSString *)getCompressClaim:(NSString *)claimId {
    NSString *openTenurePath = [self getOpentenureFolder];
    NSString *compressedClaim = [@"Claim_" stringByAppendingString:claimId];
    NSString *compressedClaimPath = [openTenurePath stringByAppendingPathComponent:compressedClaim];
    NSString *path = [compressedClaimPath stringByAppendingPathExtension:@"zip"];
    return path;
}

+ (NSString *)getOpentenureFolder {
    NSString *docDir = [[self applicationDocumentsDirectory] path];
    NSString *path = [docDir stringByAppendingPathComponent:_OPEN_TENURE_FOLDER];
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
    return jsonString;
}

+ (NSString *)getJsonAttachment:(NSString *)attachmentId {
    
    return nil;
}

+ (NSString *)matchTypeCode:(NSString *)original {
    
    return nil;
}

+ (NSString *)getClaimantImagePath:(NSString *)personId {
    NSString *claimantsPath = [self getClaimantsFolder];
    NSString *claimantFolder = [_CLAIMANT_PREFIX stringByAppendingString:personId];
    NSString *path = [[claimantsPath stringByAppendingPathComponent:claimantFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", personId]];
    return path;
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
