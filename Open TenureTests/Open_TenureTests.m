//
//  Open_TenureTests.m
//  Open TenureTests
//
//  Created by Chuyen Trung Tran on 7/16/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSDictionary+OT.h"

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
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@"abcbcbcbcbcbc" forKey:@"uuid"];
    [dict setValue:@"Claim 1" forKey:@"claim"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
    ALog(@"upload");
    [CommunityServerAPI uploadChunk:data chunk:data completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        id obj = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        ALog(@"%@", [obj description]);
        
    }];
    
//    while(true) {
//    }
    
}


@end
