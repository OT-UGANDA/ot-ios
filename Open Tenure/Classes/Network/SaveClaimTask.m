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

#import "SaveClaimTask.h"
#import "SaveAttachmentTask.h"
#import "UploadChunkTask.h"

@interface SaveClaimTask ()

@property (nonatomic, strong) Claim *claim;

@property (nonatomic) NSOperationQueue *saveAttachmentQueue;

@property (nonatomic, assign) NSUInteger totalAttachment;
@property (nonatomic, assign) NSUInteger totalAttachmentDownloaded;

@property (nonatomic, strong) id viewHolder;

@end

static NSURLSessionUploadTask *uploadTask;

@implementation SaveClaimTask

- (id)initWithClaim:(Claim *)claim viewHolder:(id)viewHolder {
    if (self = [super init]) {
        _claim = claim;
        _claim.lodgementDate = [[[OT dateFormatter] stringFromDate:[NSDate date]] substringToIndex:10];
        _viewHolder = viewHolder;
    }
    return self;
}

- (void)main {
    
    NSDictionary *jsonObject = _claim.dictionary;
    
    if ([NSJSONSerialization isValidJSONObject:jsonObject]) {

        self.saveAttachmentQueue = [NSOperationQueue new];

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        ALog(@"%@", jsonString);
        
        [CommunityServerAPI saveClaim:jsonData completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
            if (error != nil) {
                [OT handleError:error];
            } else {
                if ([[httpResponse MIMEType] isEqual:@"application/json"]) {
                    NSError *parseError = nil;
                    id returnedData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&parseError];
                    
                    if (!returnedData) {
                        NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        [OT handleErrorWithMessage:[NSString stringWithFormat:@"%@\nMessage: '%@'", parseError.localizedDescription, message]];
                    } else {
                        ALog(@"Response code: %tu; Error: %@", httpResponse.statusCode, error.localizedDescription);
                        switch (httpResponse.statusCode) {
                            case 100: /* UnknownHostException: */
                                ALog(@"Error 100");
                                if (([_claim.statusCode isEqualToString:kClaimStatusCreated]
                                     || [_claim.statusCode isEqualToString:kClaimStatusUploadIncomplete])
                                    && [_claim.statusCode isEqualToString:kClaimStatusUploadError]) {
                                    _claim.statusCode = kClaimStatusUploadIncomplete;
                                }
                                if ([_claim.statusCode isEqualToString:kClaimStatusUnmoderated]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUpdateError]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUpdateIncomplete]) {
                                    _claim.statusCode = kClaimStatusUpdateIncomplete;
                                }
                                [OT handleErrorWithMessage:[returnedData objectForKey:@"message"]];
                                break;
                                
                            case 105: /* IOException: */
                                ALog(@"Error 105");
                                if (([_claim.statusCode isEqualToString:kClaimStatusCreated]
                                     || [_claim.statusCode isEqualToString:kClaimStatusUploadIncomplete])
                                    && [_claim.statusCode isEqualToString:kClaimStatusUploadError]) {
                                    _claim.statusCode = kClaimStatusUploadError;
                                }
                                if ([_claim.statusCode isEqualToString:kClaimStatusUnmoderated]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUpdateError]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUpdateIncomplete]) {
                                    _claim.statusCode = kClaimStatusUpdateError;
                                }
                                [OT handleErrorWithMessage:[returnedData objectForKey:@"message"]];
                                break;
                                
                            case 110:
                                ALog(@"Error 110");
                                if (([_claim.statusCode isEqualToString:kClaimStatusCreated]
                                     || [_claim.statusCode isEqualToString:kClaimStatusUploadIncomplete])
                                    && [_claim.statusCode isEqualToString:kClaimStatusUploadError]) {
                                    _claim.statusCode = kClaimStatusUploadError;
                                }
                                if ([_claim.statusCode isEqualToString:kClaimStatusUnmoderated]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUpdateError]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUpdateIncomplete]) {
                                    _claim.statusCode = kClaimStatusUpdateError;
                                }
                                [OT handleErrorWithMessage:[returnedData objectForKey:@"message"]];
                                break;
                                
                            case 200: { /* OK */
                                ALog(@"return: %@", [returnedData description]);
                                NSDateFormatter *dateFormatter = [NSDateFormatter new];
                                [dateFormatter setDateFormat:[[OT dateFormatter] dateFormat]];
                                NSTimeZone *utc = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
                                [dateFormatter setTimeZone:utc];
                                NSDate *date = [dateFormatter dateFromString:[returnedData objectForKey:@"challengeExpiryDate"]];
                                _claim.challengeExpiryDate = [[[OT dateFormatter] stringFromDate:date] substringToIndex:10];
                                
                                _claim.nr = [returnedData objectForKey:@"nr"];
                                
                                _claim.statusCode = kClaimStatusUnmoderated;
                                
                                _claim.recorderName = [OTAppDelegate userName];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"message_submitted", nil)];
                                });
                                break;
                            }
                                
                            case 403:
                            case 404:{ /* Error Login */
                                ALog(@"Error 403, 404");
                                [OT handleErrorWithMessage:NSLocalizedString(@"message_login_no_more_valid", nil)];
                                [OT login];
                                break;
                            }

                            case 452: { /* Missing Attachments */
                                ALog(@"Error 452");
                                if (([_claim.statusCode isEqualToString:kClaimStatusCreated]
                                     || [_claim.statusCode isEqualToString:kClaimStatusUploadIncomplete])
                                     && [_claim.statusCode isEqualToString:kClaimStatusUploadError]) {
                                    _claim.statusCode = kClaimStatusUploading;
                                }
                                if ([_claim.statusCode isEqualToString:kClaimStatusUnmoderated]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUpdateError]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUpdateIncomplete]) {
                                    _claim.statusCode = kClaimStatusUpdating;
                                }
                                if ([_claim.managedObjectContext hasChanges])
                                    [_claim.managedObjectContext save:nil];
                                
                                ALog(@"Uploading attachments");
                                
                                NSInteger totalChunks = 0;
                                NSInteger totalAttachments = 0;
                                NSMutableArray *saveAttachmentTaskList = [NSMutableArray array];
                                for (Attachment *attachment in _claim.attachments) {
                                    if (![attachment.statusCode isEqualToString:kAttachmentStatusUploaded]) {
                                        totalAttachments++;
                                        // calculate total chunks
                                        NSString *attachmentFolder = [FileSystemUtilities getAttachmentFolder:_claim.claimId];
                                        NSString *attachmentPath = [attachmentFolder stringByAppendingPathComponent:attachment.fileName];

                                        NSData *fileData = [NSData dataWithContentsOfFile:attachmentPath];
                                        NSUInteger totalFileSize = [fileData length];
                                        totalChunks += round((totalFileSize/kChunkSize)+0.5);

                                        SaveAttachmentTask *saveAttachmentTask = [[SaveAttachmentTask alloc] initWithAttachment:attachment viewHolder:_viewHolder];
                                        saveAttachmentTask.delegate = _viewHolder;
                                        [saveAttachmentTaskList addObject:saveAttachmentTask];
                                    }
                                }
                                
                                [_delegate saveClaimTask:self didSaveWithTotalChunksTobeUploaded:totalChunks totalAttachments:totalAttachments];
                                
                                _totalAttachment = saveAttachmentTaskList.count;
                                [self.saveAttachmentQueue addOperations:saveAttachmentTaskList waitUntilFinished:NO];
                                break;
                            }
                            case 450: {
                                ALog(@"Error 450");
                                if ([_claim.statusCode isEqualToString:kClaimStatusCreated]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUploading]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUploadIncomplete]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUploadError]) {
                                    _claim.statusCode = kClaimStatusUploadError;
                                } else {
                                    _claim.statusCode = kClaimStatusUpdateError;
                                }
                                
                                [OT handleErrorWithMessage:[returnedData objectForKey:@"message"]];
                                break;
                            }
                            case 400:
                                ALog(@"Error 400");
                                if ([_claim.statusCode isEqualToString:kClaimStatusCreated]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUploading]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUploadIncomplete]
                                    || [_claim.statusCode isEqualToString:kClaimStatusUploadError]) {
                                    _claim.statusCode = kClaimStatusUploadError;
                                } else {
                                    _claim.statusCode = kClaimStatusUpdateError;
                                }
                                [OT handleErrorWithMessage:[returnedData objectForKey:@"message"]];
                                break;
                            default:
                                break;
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
                if ([_claim.managedObjectContext hasChanges]) [_claim.managedObjectContext save:nil];
            }
        }];
    }
}

@end
