//
//  ZipUtilities.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 7/27/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "ZipUtilities.h"

@implementation ZipUtilities

+ (BOOL)addFilesWithAESEncryption:(NSString *)password claimId:(NSString *)claimId {
    NSString *zipFile = [FileSystemUtilities getCompressClaim:claimId];
    return [SSZipArchive createZipFileAtPath:zipFile withContentsOfDirectory:[FileSystemUtilities getClaimFolder:claimId] password:password];}
                                                      
@end
