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

#import "SaveAttachmentTask.h"
#import "UploadChunkTask.h"

@interface SaveAttachmentTask ()

@property (nonatomic) NSOperationQueue *uploadChunkTaskQueue;
@property (nonatomic) UploadChunkTask *uploadChunkTask;

@property (nonatomic, strong) id viewHolder;

@end

@implementation SaveAttachmentTask

- (id)initWithAttachment:(Attachment *)attachment viewHolder:(id)viewHolder {
    if (self = [super init]) {
        _attachment = attachment;
        _uploadChunkTaskQueue = [NSOperationQueue new];
        _viewHolder = viewHolder;
        _uploadChunkTask = [[UploadChunkTask alloc] initWithAttachment:attachment];
        _uploadChunkTask.delegate = _viewHolder;
    }
    return self;
}

- (void)saveAttachment:(Attachment *)attachment {
    NSDictionary *jsonObject = attachment.dictionary;
    
    if ([NSJSONSerialization isValidJSONObject:jsonObject]) {
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:nil];
        
        [CommunityServerAPI saveAttachment:jsonData completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
            ALog(@"Response code: %tu; Error: %@", httpResponse.statusCode, error.localizedDescription);
            if (error != nil) {
                [OT handleError:error];
            } else {
                if ([[httpResponse MIMEType] isEqual:@"application/json"]) {
                    NSError *parseError = nil;
                    id returnedData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&parseError];
                    
                    if (!returnedData) {
                        [OT handleError:parseError];
                    } else {
                        switch (httpResponse.statusCode) {
                            case 100: /* UnknownHostException: */
                            case 105: /* IOException: */
                            case 110:
                                if ([attachment.statusCode isEqualToString:kAttachmentStatusUploading])
                                    attachment.statusCode = kAttachmentStatusUploadIncomplete;
                                if ([attachment.claim.statusCode isEqualToString:kClaimStatusUploading])
                                    attachment.claim.statusCode = kClaimStatusUploadIncomplete;
                                if ([attachment.claim.statusCode isEqualToString:kClaimStatusUpdating])
                                    attachment.claim.statusCode = kClaimStatusUpdateIncomplete;
                                
                                [OT handleErrorWithMessage:[returnedData message]];
                                break;
                                
                            case 200: { /* OK */
                                int action = 0;
                                for (Attachment *att in attachment.claim.attachments) {
                                    if ([att.statusCode isEqualToString:kAttachmentStatusUploaded]) {
                                        action = 1;
                                    }
                                    if ([att.statusCode isEqualToString:kAttachmentStatusUploadIncomplete]) {
                                        action = 2;
                                        break;
                                    }
                                }
                                if (action == 2) {
                                    if ([attachment.claim.statusCode isEqualToString:kClaimStatusUploading]) {
                                        attachment.claim.statusCode = kClaimStatusUploadIncomplete;
                                    }
                                    if ([attachment.claim.statusCode isEqualToString:kClaimStatusUpdating]) {
                                        attachment.claim.statusCode = kClaimStatusUpdateIncomplete;
                                    }
                                } else {
                                    // DO NOTHING
                                }
                                attachment.statusCode = kAttachmentStatusUploaded;
                                [attachment.managedObjectContext save:nil];
                                [_delegate saveAttachment:self didSaveSuccess:YES];
                                break;
                            }
                                
                            case 403:
                            case 404:{ /* Error Login */
                                [OT handleErrorWithMessage:NSLocalizedString(@"message_login_no_more_valid", nil)];
                                [OT login];
                                break;
                            }
                            
                            case 454: { /* Object already exists */
                                ALog(@"Object already exists");
                                attachment.statusCode = kAttachmentStatusUploaded;
                                [attachment.managedObjectContext save:nil];
                                [_delegate saveAttachment:self didSaveSuccess:YES];
                                break;
                            }
                                
                            case 456: { /* Attachment chunks not found. */
                                
                                ALog(@"Uploading chunk");
                                
                                [_uploadChunkTaskQueue addOperation:_uploadChunkTask];
                                
                                break;
                            }
                            default:
                                ALog(@"Default: %@", [returnedData description]);
                                ALog(@"Attachment %@", attachment);
                                NSString *message = [returnedData objectForKey:@"message"];
                                if (message == nil) message = [returnedData description];
                                if (message == nil) message = @"Unknow error";
                                [OT handleErrorWithMessage:message];
                                break;
                        }
                    }
                    if ([attachment.managedObjectContext hasChanges]) [attachment.managedObjectContext save:nil];
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
}

- (void)main {
    [self saveAttachment:_attachment];
}


@end
