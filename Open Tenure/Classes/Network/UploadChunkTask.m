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

#import "UploadChunkTask.h"

@interface UploadChunkTask () {
    int totalChunksTobeUploaded;
    int chunksUploadedSuccessfully;
}

@property (nonatomic, strong) NSInputStream *fileStream;
@property (nonatomic, assign) uint8_t *buffer;

- (void)uploadChunkData:(NSData*)chunkData withPayload:(NSMutableDictionary *)payloadDict;

@end

@implementation UploadChunkTask

- (id)initWithAttachment:(Attachment *)attachment {
    if (self = [super init]) {
        _attachment = attachment;
        _buffer = malloc(kChunkSize);
    }
    return self;
}

- (void)uploadChunkData:(NSData *)chunkData withPayload:(NSMutableDictionary *)payloadDict {
    [CommunityServerAPI uploadChunk:payloadDict chunk:chunkData completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        ALog(@"descriptor %@", payloadDict.description);
        ALog(@"Response: %tu", httpResponse.statusCode);
        id returnedData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        ALog(@"Result: %@", [returnedData description]);
        switch (httpResponse.statusCode) {
            case 200: {
                chunksUploadedSuccessfully++;
                dispatch_async(dispatch_get_main_queue(), ^{
                    ALog(@"Delegate gửi về viewHolder để xử lý progress");
                    [_delegate uploadChunk:self didFinishChunkCount:chunksUploadedSuccessfully];
                });
                NSInteger bytesRead = [_fileStream read:_buffer maxLength:kChunkSize];
                NSInteger rsz = [[payloadDict valueForKey:@"startPosition"] integerValue];
                NSInteger size = [[payloadDict valueForKey:@"size"] integerValue];
                rsz += size;
                if (bytesRead > 0) {
                    ALog(@"send next Chunck To server");
                    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
                    NSData *chunk = [NSData dataWithBytes:(const void *)_buffer length:bytesRead];
                    [payload setObject:_attachment.attachmentId forKey:@"attachmentId"];
                    [payload setObject:_attachment.claim.claimId forKey:@"claimId"];
                    [payload setObject:[NSNumber numberWithInteger:rsz] forKey:@"startPosition"];
                    [payload setObject:chunk.md5 forKey:@"md5"];
                    [payload setObject:[[[NSUUID UUID] UUIDString] lowercaseString]  forKey:@"id"];
                    [payload setObject:[NSNumber numberWithInteger:bytesRead] forKey:@"size"];
                    
                    [self uploadChunkData:chunk withPayload:[payload mutableCopy]];
                } else {
                    ALog(@"stop no more data to upload");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate uploadChunk:self didFinishWithSuccess:YES];
                    });
                }
                break;
            }
            default:
                ALog(@"Retry resending same chuck");
                // TODO set timeout
                [self uploadChunkData:chunkData withPayload:payloadDict];
                
                break;
        }
    }];
}

- (void)main {
    NSString *attachmentFolder = [FileSystemUtilities getAttachmentFolder:_attachment.claim.claimId];
    NSString *attachmentPath = [attachmentFolder stringByAppendingPathComponent:_attachment.fileName];
    
    NSData *fileData = [NSData dataWithContentsOfFile:attachmentPath];
    NSUInteger totalFileSize = [fileData length];
    int totalChunks = round((totalFileSize/kChunkSize)+0.5);
    totalChunksTobeUploaded = totalChunks;
    chunksUploadedSuccessfully = 0;

    _fileStream = [NSInputStream inputStreamWithFileAtPath:attachmentPath];
    [_fileStream open];
    
    NSInteger bytesRead = [_fileStream read:_buffer maxLength:kChunkSize];

    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    NSData *chunk = [NSData dataWithBytes:(const void *)_buffer length:bytesRead];
    [payload setObject:_attachment.attachmentId forKey:@"attachmentId"];
    [payload setObject:_attachment.claim.claimId forKey:@"claimId"];
    [payload setObject:[NSNumber numberWithInteger:0] forKey:@"startPosition"];
    [payload setObject:chunk.md5 forKey:@"md5"];
    [payload setObject:[[[NSUUID UUID] UUIDString] lowercaseString]  forKey:@"id"];
    [payload setObject:[NSNumber numberWithInteger:bytesRead] forKey:@"size"];
    
    ALog(@"send first Chunck To server");
    [self uploadChunkData:chunk withPayload:payload];
    
    free(_buffer);
}

@end
