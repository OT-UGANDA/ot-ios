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
#import "ChunkPayLoad.h"
#import "UploadChunk.h"

#define kChunkSize 500000

@interface SaveAttachmentTask ()

@property (nonatomic) NSOperationQueue *uploadChunkQueue;

@property (nonatomic, strong) Attachment *attachment;
@property (nonatomic, strong) ChunkPayLoad* payload;


@end

@implementation SaveAttachmentTask

- (id)initWithAttachment:(Attachment *)attachment {
    if (self = [super init]) {
        _attachment = attachment;
    }
    return self;
}

- (void)main {
    NSDictionary *jsonObject = _attachment.dictionary;
    
    
    if ([NSJSONSerialization isValidJSONObject:jsonObject]) {
        
        //self.uploadChunkQueue = [NSOperationQueue new];
        
        NSLog(@"%@", jsonObject.description);
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:nil];
        
        [CommunityServerAPI saveAttachment:jsonData completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
            NSLog(@"Response code: %tu; Error: %@", httpResponse.statusCode, error.localizedDescription);
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
                                if ([_attachment.statusCode isEqualToString:kAttachmentStatusUploading])
                                    _attachment.statusCode = kAttachmentStatusUploadIncomplete;
                                if ([_attachment.claim.statusCode isEqualToString:kClaimStatusUploading])
                                    _attachment.claim.statusCode = kClaimStatusUploadIncomplete;
                                if ([_attachment.claim.statusCode isEqualToString:kClaimStatusUpdating])
                                    _attachment.claim.statusCode = kClaimStatusUpdateIncomplete;
                                
                                [OT handleErrorWithMessage:[returnedData message]];
                                break;
                                
                            case 200: { /* OK */
                                
                                break;
                            }
                                
                            case 403:
                            case 404:{ /* Error Login */
                                [OT handleErrorWithMessage:NSLocalizedString(@"message_login_no_more_valid", nil)];
                                [OT login];
                                break;
                            }
                                
                            case 456: { /* Attachment chunks not found. */
                                
                                [SVProgressHUD showProgress:0.0 status:NSLocalizedString(@"message_uploading", nil)];
                                NSLog(@"Uploading chunk");
                                
                                NSString *attachmentFolder = [FileSystemUtilities getAttachmentFolder:_attachment.claim.claimId];
                                NSString *attachmentPath = [attachmentFolder stringByAppendingPathComponent:_attachment.fileName];
                                NSLog(@"attachment file %@", attachmentPath);
                                NSInputStream *fileStream = [NSInputStream inputStreamWithFileAtPath:attachmentPath];
                                NSLog(@"input stream %@", fileStream.description);
                                [fileStream open];
                                uint8_t *buffer = malloc(kChunkSize);
                                NSInteger bytesRead = [fileStream read:buffer maxLength:kChunkSize];
                                NSInteger startPos = 0;
                                NSLog(@"%tu", bytesRead);
                                 NSLog(@"Keys:");
                                //NSLog(@"Keys: %@ %@ %@",[[[NSUUID UUID] UUIDString] lowercaseString],_attachment.claim.claimId,_attachment.attachmentId);
                                while (bytesRead != 0) {
                                    NSData *data = [NSData dataWithBytes:(const void *)buffer length:kChunkSize];
                                    
                                   // NSLog(@"%@", data.description);
                                    //TODO: create a ChunkPayLoad
                                    
                                    NSLog(@"Keys: %@ %@ %@",[[[NSUUID UUID] UUIDString] lowercaseString],_attachment.claim.claimId,_attachment.attachmentId);
                                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                                    [dict setObject:[[[NSUUID UUID] UUIDString] lowercaseString] forKey:@"id"];
                                    [dict setObject:_attachment.claim.claimId forKey:@"claimId"];
                                    [dict setObject:_attachment.attachmentId  forKey:@"attachmentId"];
                                    [dict setObject:[NSString stringWithFormat: @"%d", (int)startPos] forKey:@"startPosition"];
                                    [dict setObject:[NSString stringWithFormat: @"%d", (int)bytesRead]forKey:@"size"];
                                    [dict setObject:data.md5 forKey:@"md5"];
                                     NSLog(@"Dict: %@",dict);
                                    
                                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
                                    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                                    NSLog(@"JSON String: %@",jsonString);
                                    
                                   /* _payload = [[ChunkPayLoad alloc] init];
                                    _payload.chunkId = [[[NSUUID UUID] UUIDString] lowercaseString];
                                    _payload.claimId = _attachment.claim.claimId;
                                    _payload.attachmentId = _attachment.attachmentId;
                                    _payload.startPosition = [NSString stringWithFormat: @"%d", (int)startPos];
                                    _payload.size = [NSString stringWithFormat: @"%d", (int)bytesRead];
                                    _payload.md5 = data.md5;
                                    NSLog(@"%@%@", @"claim ID: ",_payload.claimId);
                                    //test JSON of PayLoad
                                    NSDictionary *jsonObject = _payload.dictionary;
                                    
                                    if ([NSJSONSerialization isValidJSONObject:jsonObject]) {
                                        NSLog(@"%@", jsonObject.description);
                                    }
                                    */
                                    //use UploadChunk to send
                                    UploadChunk* uploadChunk = [[UploadChunk alloc] initWithPayload:jsonData chunk:data];
                                   
                                    self.uploadChunkQueue = [NSOperationQueue new];
                                    [_uploadChunkQueue addOperation:uploadChunk];
                                    
                                    //read the next chunk
                                    startPos +=  bytesRead;
                                    bytesRead = [fileStream read:buffer maxLength:kChunkSize];
                                    
                                }
                                
//                                NSMutableArray *chunkList = [NSMutableArray array];
//                                for (Attachment *attachment in _attachment.attachments) {
//                                    if (attachment.status != kAttachmentStatusUploaded
//                                        && attachment.status != kAttachmentStatusUploading) {
//                                        SaveAttachmentTask *saveAttachmentTask = [[SaveAttachmentTask alloc] initWithAttachment:attachment];
//                                        saveAttachmentTask.delegate = self;
//                                        [saveAttachmentTaskList addObject:saveAttachmentTask];
//                                    }
//                                }
//                                _totalAttachment = saveAttachmentTaskList.count;
//                                [self.saveAttachmentQueue addOperations:saveAttachmentTaskList waitUntilFinished:NO];
                                
                                break;
                            }
                            default:
                                NSLog(@"Default: %@", [returnedData description]);
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
                if ([_attachment.managedObjectContext hasChanges]) [_attachment.managedObjectContext save:nil];
            }
        }];
    }
}

// observe the queue's operationCount, stop activity indicator if there is no operatation ongoing.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.uploadChunkQueue && [keyPath isEqualToString:@"uploadChunkCount"]) {
        if (self.uploadChunkQueue.operationCount == 0) {
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"message_uploaded", nil)];
            [self removeObserver:self forKeyPath:@"uploadChunkCount" context:nil];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
