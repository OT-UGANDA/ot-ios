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

    NSString *urlString = [NSString stringWithFormat:HTTPS_LOGIN, username, password];
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

    NSURL *url = [NSURL URLWithString:HTTPS_LOGOUT];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

- (NSString *)getCoockieStore {
    
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    return [[NSHTTPCookie requestHeaderFieldsWithCookies:[cookieStorage cookies]] objectForKey:@"Cookie"];
}

+ (void)getAllClaimsWithCompletionHandler:(CompletionHandler)completionHandler {
    
    NSURL *url = [NSURL URLWithString:HTTPS_GETALLCLAIMS];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getAllClaimsByBox:(NSArray *)coordinates completionHandler:(CompletionHandler)completionHandler {

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:HTTPS_GETALLCLAIMSBYBOX, coordinates[0], coordinates[1], coordinates[2], coordinates[3], @"100"]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)withdrawClaim:(NSString *)claimId completionHandler:(CompletionHandler)completionHandler {

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:HTTPS_WITHDRAWCLAIM, claimId]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setValue:[[self controller] getCoockieStore] forHTTPHeaderField:@"Cookie"];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getClaim:(NSString *)claimId completionHandler:(CompletionHandler)completionHandler {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:HTTPS_GETCLAIM, claimId]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

- (void)getClaim:(NSString *)claimId completionHandler:(CompletionHandler)completionHandler {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:HTTPS_GETCLAIM, claimId]];
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
    successfulStatus = NSLocalizedString(@"message_attachment_downloaded", @"Downloaded attachment");
    destinationPath = path;
    _session = [[self controller] backgroundSession];
    
    if (_downloadTask != nil) return;
    
    [SVProgressHUD showProgress:0.0 status:downloadingStatus];
    
    // Create a new download task using the URL session. Tasks start in the “suspended” state; to start a task you need to explicitly call -resume on a task after creating it.
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:HTTPS_GETATTACHMENT, attachmentId]];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	_downloadTask = [_session downloadTaskWithRequest:request];
    [_downloadTask resume];
}

+ (void)getLandUsesWithCompletionHandler:(CompletionHandler)completionHandler {
    NSURL *url = [NSURL URLWithString:HTTPS_GETLANDUSE];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getIdTypesWithCompletionHandler:(CompletionHandler)completionHandler {
    
    NSURL *url = [NSURL URLWithString:HTTPS_GETIDTYPES];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getClaimTypesWithCompletionHandler:(CompletionHandler)completionHandler {

    NSURL *url = [NSURL URLWithString:HTTPS_GETCLAIMTYPES];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)getDocumentTypesWithCompletionHandler:(CompletionHandler)completionHandler {

    NSURL *url = [NSURL URLWithString:HTTPS_GETDOCUMENTYPES];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error, httpResponse, data);
        });
    }];
}

+ (void)saveClaim:(NSString *)claimId completionHandler:(CompletionHandler)completionHandler {
    
}

+ (void)uploadChunk:(NSString *)payload chunk:(NSData *)chunk completionHandler:(CompletionHandler)completionHandler {
    
}

#pragma Response methods
/**
 * Add new response claims to claimList
 * Return new response claims
 */
+ (NSMutableArray *)addResponseClaimsToClaimList:(NSMutableArray *)objects {
    NSMutableArray *newResponseClaims = [NSMutableArray array];
    for (NSDictionary *object in objects) {
        ResponseClaim *claim = [[ResponseClaim alloc] initWithDictionary:object];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"claimId = %@ AND statusCode = %@", claim.claimId, claim.statusCode];
        
        NSArray *filteredItems = [claimList filteredArrayUsingPredicate:predicate];
        if (filteredItems.count == 0) {
            // we found no duplicate claim, so insert this new one
            [claimList addObject:claim];
            [newResponseClaims addObject:claim];
        }
    }
    return newResponseClaims;
}

#pragma Background sessions

- (NSURLSession *)backgroundSession {
    // Using disptach_once here ensures that multiple background sessions with the same identifier are not created in this instance of the application. If you want to support multiple background sessions within a single process, you should create each session with its own identifier.
	static NSURLSession *session = nil;
	static dispatch_once_t onceToken;
    NSString *sessionConfiguration = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@".BackgroundSession"];
	dispatch_once(&onceToken, ^{
		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionConfiguration];
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
//        NSLog(@"NSURLSessionTaskDelegate %f", progress);
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
    
    NSLog(@"All tasks are finished");
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}

@end
