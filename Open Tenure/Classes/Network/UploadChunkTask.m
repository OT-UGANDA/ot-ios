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
@property (nonatomic, strong) NSMutableArray *chunks;
@property (nonatomic, strong) NSMutableArray *payloads;
@property (nonatomic, assign) NSUInteger resendingCounter;

@end

@implementation UploadChunkTask

- (id)initWithAttachment:(Attachment *)attachment {
    if (self = [super init]) {
        _attachment = attachment;
        _buffer = malloc(kChunkSize);
        _chunks = [@[] mutableCopy];
        _payloads = [@[] mutableCopy];
    }
    return self;
}

- (void)uploadChunksAndPayloads {
    if (_chunks.count == 0) return;
    NSData *chunkData = [_chunks objectAtIndex:0];
    NSMutableDictionary *payloadDict = [_payloads objectAtIndex:0];
    [CommunityServerAPI uploadChunk:payloadDict chunk:chunkData completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        ALog(@"descriptor %@", payloadDict.description);
        ALog(@"Response: %tu", httpResponse.statusCode);
        id returnedData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        ALog(@"Result: %@", [returnedData description]);
        switch (httpResponse.statusCode) {
            case 200: {
                _resendingCounter = 0;
                [_chunks removeObject:[[_chunks objectAtIndex:0] copy]];
                [_payloads removeObject:[[_payloads objectAtIndex:0] copy]];
                
                chunksUploadedSuccessfully++;
                dispatch_async(dispatch_get_main_queue(), ^{
                    ALog(@"Delegate gửi về viewHolder để xử lý progress");
                    [_delegate uploadChunk:self didFinishChunkCount:chunksUploadedSuccessfully];
                });
                ALog(@"Chunk count: %tu", _chunks.count);
                if (_chunks.count > 0) {
                    [self uploadChunksAndPayloads];
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
                _resendingCounter++;
                if (_resendingCounter < 3)
                    [self uploadChunksAndPayloads];
                else
                    [OT handleErrorWithMessage:@"Timeout"];
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

    NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:attachmentPath];
    _fileStream = [[NSInputStream alloc] initWithURL:fileUrl];
    [_fileStream open];

    NSInteger bytesRead = [_fileStream read:_buffer maxLength:kChunkSize];
    NSInteger startPosition = 0;
    while (bytesRead > 0) {
        NSMutableDictionary *payload = [NSMutableDictionary dictionary];
        NSData *chunk = [NSData dataWithBytes:(const void *)_buffer length:bytesRead];
        [payload setObject:_attachment.attachmentId forKey:@"attachmentId"];
        [payload setObject:_attachment.claim.claimId forKey:@"claimId"];
        [payload setObject:[NSNumber numberWithInteger:startPosition] forKey:@"startPosition"];
        [payload setObject:chunk.md5 forKey:@"md5"];
        [payload setObject:[[[NSUUID UUID] UUIDString] lowercaseString]  forKey:@"id"];
        [payload setObject:[NSNumber numberWithInteger:bytesRead] forKey:@"size"];
        
        [_chunks addObject:chunk];
        [_payloads addObject:payload];
        startPosition += bytesRead;
        bytesRead = [_fileStream read:_buffer maxLength:kChunkSize];
    }
    [self uploadChunksAndPayloads];
    
    free(_buffer);
}

@end
