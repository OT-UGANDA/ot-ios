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

#import "CommunityServerAPI.h"

static NSMutableArray *claimList;

static NSURLSession *_session;
static NSURLSessionDownloadTask *_downloadTask;
static NSString *downloadingStatus;
static NSString *successfulStatus;

static NSString *destinationPath;

@implementation CommunityServerAPI

+ (CommunityServerAPI *)controller {
    static dispatch_once_t once;
    static CommunityServerAPI *controller;
    dispatch_once(&once, ^{
        controller = [[self alloc] init];
    });
    return controller;
}

+ (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password completionHandler:(CompletionHandler)completionHandler{

    NSString *urlString = [NSString stringWithFormat:HTTPS_LOGIN, [OTSetting getCommunityServerURL], [OT getLocalization], username, password];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)logoutWithCompletionHandler:(CompletionHandler)completionHandler {

    NSString *urlString = [NSString stringWithFormat:HTTPS_LOGOUT, [OTSetting getCommunityServerURL], [OT getLocalization]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getAllClaimsWithCompletionHandler:(CompletionHandler)completionHandler {
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_GETALLCLAIMS, [OTSetting getCommunityServerURL], [OT getLocalization]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getAllClaimsByBox:(NSArray *)coordinates completionHandler:(CompletionHandler)completionHandler {
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_GETALLCLAIMSBYBOX, [OTSetting getCommunityServerURL], [OT getLocalization], coordinates[0], coordinates[1], coordinates[2], coordinates[3], @"100"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)withdrawClaim:(NSString *)claimId completionHandler:(CompletionHandler)completionHandler {
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_WITHDRAWCLAIM, [OTSetting getCommunityServerURL], [OT getLocalization], claimId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setValue:[OT getCookie] forHTTPHeaderField:@"Cookie"];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getClaim:(NSString *)claimId completionHandler:(CompletionHandler)completionHandler {
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_GETCLAIM, [OTSetting getCommunityServerURL], [OT getLocalization], claimId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getAttachment:(NSString *)attachmentId saveToPath:(NSString *)path {
    downloadingStatus = NSLocalizedString(@"message_downloading_attachment", @"Downloading the attachment");
    successfulStatus = [NSString stringWithFormat:NSLocalizedString(@"message_attachment_downloaded", @"Downloaded attachment"), [[[path pathComponents] lastObject] UTF8String]];
    destinationPath = path;
    _session = [[self controller] backgroundSession];
    
    if (_downloadTask != nil) return;
    
    [SVProgressHUD showProgress:0.0 status:downloadingStatus];
    
    // Create a new download task using the URL session. Tasks start in the “suspended” state; to start a task you need to explicitly call -resume on a task after creating it.
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_GETATTACHMENT, [OTSetting getCommunityServerURL], attachmentId];
    NSURL *url = [NSURL URLWithString:urlString];
    ALog(@"%@", urlString);
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	_downloadTask = [_session downloadTaskWithRequest:request];
    [_downloadTask resume];
}

+ (void)getClaimantPhoto:(NSString *)claimId personId:(NSString *)personId {
    NSString *urlString = [NSString stringWithFormat:HTTPS_GETATTACHMENT, [OTSetting getCommunityServerURL], personId];
    NSURL *url = [NSURL URLWithString:urlString];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
        if (!error) {
            NSString *imagePath = [FileSystemUtilities getClaimantFolder:claimId];
            NSString *imageFile = [personId stringByAppendingPathExtension:@"jpg"];
            imageFile = [imagePath stringByAppendingPathComponent:imageFile];

            [data writeToFile:imageFile atomically:YES];
        }
    }];
}

+ (void)getLandUsesWithCompletionHandler:(CompletionHandler)completionHandler {
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_GETLANDUSE, [OTSetting getCommunityServerURL], [OT getLocalization]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getIdTypesWithCompletionHandler:(CompletionHandler)completionHandler {
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_GETIDTYPES, [OTSetting getCommunityServerURL], [OT getLocalization]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getClaimTypesWithCompletionHandler:(CompletionHandler)completionHandler {
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_GETCLAIMTYPES, [OTSetting getCommunityServerURL], [OT getLocalization]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getDocumentTypesWithCompletionHandler:(CompletionHandler)completionHandler {
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_GETDOCUMENTYPES, [OTSetting getCommunityServerURL], [OT getLocalization]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)saveClaim:(NSData *)jsonData completionHandler:(CompletionHandler)completionHandler {
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_SAVECLAIM, [OTSetting getCommunityServerURL], [OT getLocalization]];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[jsonData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setValue:[OT getCookie] forHTTPHeaderField:@"Cookie"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)saveAttachment:(NSData *)jsonData completionHandler:(CompletionHandler)completionHandler {
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_SAVEATTACHMENT, [OTSetting getCommunityServerURL], [OT getLocalization]];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSString *postLength = [NSString stringWithFormat:@"%tu", [jsonData length]];
    ALog(@"File size: %tu (%@)", [jsonData length], postLength);
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    postLength = [NSString stringWithFormat:@"%tu", [jsonString length]];
    ALog(@"String size: %tu (%@)", [jsonString length], jsonString);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setValue:[OT getCookie] forHTTPHeaderField:@"Cookie"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)uploadChunk:(NSDictionary *)payload chunk:(NSData *)chunk completionHandler:(CompletionHandler)completionHandler {
    /*
     POST /ws/claim/it-IT/uploadChunk HTTP/1.1
     Host: ot.flossola.org:443
     Connection: keep-alive
     Content-Type: multipart/form-data; boundary=---------------------------41184676334
     Content-Length: (according to actual content)
     
     -----------------------------41184676334
     Content-Disposition: form-data; name="descriptor"
     Content-Type: application/json
     {
     "id":"74c166ba-cf58-11e3-9ccc-f7ef76b09620",
     "attachmentId":"63528f80-cf58-11e3-8ca3-07ca7b0c8647",
     "claimId":"6ac47e0e-cf58-11e3-b644-a373dca3cc04",
     "startPosition":0,
     "size":1622293,
     "md5":"a106695a4fe8020fb27c745b340cd7b3"
     }
     -----------------------------41184676334
     Content-Disposition: form-data; name="chunk";
     Content-Type: application/octet-stream
     
     (Binary data not shown)
     -----------------------------41184676334--
     */
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_UPLOADCHUNK, [OTSetting getCommunityServerURL], [OT getLocalization]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSString *boundaryStringPrefix =  @"\r\n-----------------------------41184676334\r\n";
    NSString *boundaryStringPostfix = @"\r\n-----------------------------41184676334--";

    NSString *contentType = @"multipart/form-data; boundary=---------------------------41184676334";
//    NSString *postLength = [NSString stringWithFormat:@"%d",[chunk length]];
    

    [request setValue:[OT getCookie] forHTTPHeaderField:@"Cookie"];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
//    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    
    NSMutableData *body = [NSMutableData data];
    
    [body appendData:[boundaryStringPrefix dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"descriptor\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/json\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSData *payloadData = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingPrettyPrinted error:nil];
    [body appendData:payloadData];
    
    [body appendData:[boundaryStringPrefix dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[@"Content-Disposition: form-data; name=\"chunk\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:chunk];
    [body appendData:[boundaryStringPostfix dataUsingEncoding:NSUTF8StringEncoding]];

    // setting the body of the post to the reqeust
    [request setHTTPBody:body];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        ALog(@"Upload Start Position: %tu", [[payload objectForKey:@"startPosition"] integerValue]);
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];

}

+ (void)getCommunityArea:(CompletionHandler)completionHandler {
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_GETCOMMUNITYAREA, [OTSetting getCommunityServerURL], [OT getLocalization]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getDefaultFormTemplate:(CompletionHandler)completionHandler {
    
    NSString *urlString = [NSString stringWithFormat:HTTPS_GETDEFAULTFORMTEMPLATE, [OTSetting getCommunityServerURL], [OT getLocalization]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

#pragma for upload chunk
+ (NSString *)generateBoundaryString {
    CFUUIDRef       uuid;
    CFStringRef     uuidStr;
    NSString *      result;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFUUIDCreateString(NULL, uuid);
    assert(uuidStr != NULL);
    
    result = [NSString stringWithFormat:@"Boundary-%@", uuidStr];
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    
    return result;
}

#pragma Background sessions

- (NSURLSession *)backgroundSession {
    // Using disptach_once here ensures that multiple background sessions with the same identifier are not created in this instance of the application. If you want to support multiple background sessions within a single process, you should create each session with its own identifier.
	static NSURLSession *session = nil;
	static dispatch_once_t onceToken;
    NSString *sessionConfiguration = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@".BackgroundSessionForDownloadDocuments"];
	dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            #ifdef __IPHONE_8_0
            configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionConfiguration];
            #endif
        } else {
            configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionConfiguration];
        }
		session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
	});
	return session;
}

#pragma NSURLSessionDownloadDelegate methods

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    // Report progress on the task.
    // If you created more than one task, you might keep references to them and report on them individually.
    if (downloadTask == _downloadTask) {
        double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showProgress:progress status:downloadingStatus maskType:SVProgressHUDMaskTypeGradient];
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL
{
    // The download completed, you need to copy the file at targetPath before the end of this block.
    // As an example, copy the file to the Documents directory of your app.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *destinationURL = [[NSURL alloc] initFileURLWithPath:destinationPath];
    NSError *errorCopy;
    
    // For the purposes of testing, remove any esisting file at the destination.
    [fileManager removeItemAtURL:destinationURL error:NULL];
    BOOL success = [fileManager copyItemAtURL:downloadURL toURL:destinationURL error:&errorCopy];
    
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showSuccessWithStatus:successfulStatus];
        });
    } else {
        // In the general case, what you might do in the event of failure depends on the error and the specifics of your application.
        [SVProgressHUD showErrorWithStatus:[errorCopy localizedDescription]];
    }
}

#pragma NSURLSessionTaskDelegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error == nil) {
        [SVProgressHUD dismiss];
    } else {
        [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
    }
	
//    double progress = (double)task.countOfBytesReceived / (double)task.countOfBytesExpectedToReceive;
//	dispatch_async(dispatch_get_main_queue(), ^{
//        ALog(@"NSURLSessionTaskDelegate %f", progress);
//        //[SVProgressHUD showProgress:progress status:downloadingStatus];
//	});
//    
    _downloadTask = nil;
}


#pragma NSURLSessionDelegate methods

/**
 * If an application has received an -application:handleEventsForBackgroundURLSession:completionHandler: message, the session 
 * delegate will receive this message to indicate that all messages previously enqueued for this session have been delivered. 
 * At this time it is safe to invoke the previously stored completion handler, or to begin any internal updates that will 
 * result in invoking the completion handler.
 **/

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    OTAppDelegate *appDelegate = (OTAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.backgroundSessionCompletionHandler) {
        void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
        appDelegate.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }
    
    ALog(@"All tasks are finished");
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}

@end
