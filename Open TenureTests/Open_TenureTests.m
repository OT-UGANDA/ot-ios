//
//  Open_TenureTests.m
//  Open TenureTests
//
//  Created by Chuyen Trung Tran on 7/16/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSDictionary+OT.h"
#import "NSData+Md5.h"
#import "NSString+Md5.h"

@interface Open_TenureTests : XCTestCase

@end

@implementation Open_TenureTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    [self Md5];
}


- (void)Md5{
    NSString *str = @"Trần Trung Chuyên";

    NSLog(@"%@", [str MD5]);
}

//
//- (void)tDocType {
//    NSArray *collection = [DocumentTypeEntity getCollection];
//    for (DocumentType *docType in collection) {
//        NSLog(@"Doc: %@", docType.displayValue);
//    }
//    
//}
//
//- (void)testAPI {
//    //    [CommunityServerAPI withdrawClaim:@"5ac56a97-ee4a-43e9-8d62-7a101c7bb645"];
//    //    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//    //    NSDictionary *cookieHeaders = [NSHTTPCookie requestHeaderFieldsWithCookies:[cookieStorage cookies]];
//    //    NSLog(@"%@", [cookieHeaders objectForKey:@"Cookie"]);
//    //    for (NSHTTPCookie *each in [cookieStorage cookies]) {
//    //        NSLog(@"%@", [each description]);
//    //    }
//    //    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//    //    for (NSHTTPCookie *each in [cookieStorage cookiesForURL:[NSURL URLWithString:HTTP_LOGOUT]]) {
//    //        [cookieStorage deleteCookie:each];
//    //    }
//    
//    //    [ZipUtilities addFilesWithAESEncryption:@"password" claimId:@"abc"];
//    //    CommunityServerAPI *comm = [[CommunityServerAPI alloc] init];
//    //    [CommunityServerAPI getAllClaims];
//    //    [CommunityServerAPI getClaim:@"9ab491c1-5d18-4a9d-a49d-d837e380b947"];
//    
//    // Test getAttachment
//    [FileSystemUtilities createClaimFolder:@"9ab491c1-5d18-4a9d-a49d-d837e380b947"];
//    NSString *destinationPath = [FileSystemUtilities getAttachmentFolder:@"9ab491c1-5d18-4a9d-a49d-d837e380b947"];
//    destinationPath = [destinationPath stringByAppendingPathComponent:@"file.jpg"];
//    [CommunityServerAPI getAttachment:@"b425adcd-04d5-4ee8-8c9e-56d5a9363d08" saveToPath:destinationPath];
//    
//    //    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
//    //    [request addValue:[OTUser sessionId] forHTTPHeaderField:@"Set-Cookie"];
//    //    NSLog(@"%d\n%@", [OTUser authenticated], [OTUser sessionId]);
//   
//}

@end
