//
//  ZipUtilities.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 7/27/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSZipArchive.h"

@interface ZipUtilities : NSObject

/**
 *
 * This code support the AES encryption.
 *
 **/

+ (BOOL)addFilesWithAESEncryption:(NSString *)password claimId:(NSString *)claimId;

@end
