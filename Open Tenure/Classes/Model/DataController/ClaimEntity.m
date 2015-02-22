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

#import "ClaimEntity.h"

@implementation ClaimEntity

#pragma mark - Data

/*!
 Khởi tạo bảng và nạp dữ liệu vào bộ nhớ
 */
- (id)init {
    if (self = [super init]) {
        [self loadData];
    }
    return self;
}

/*!
 Tạo sharedClaimEntity chia sẻ thông tin trong static class
 */
+ (ClaimEntity *)sharedClaimEntity {
    static dispatch_once_t once;
    __strong static ClaimEntity *sharedClaimEntity = nil;
    dispatch_once(&once, ^{
        sharedClaimEntity = [self new];
    });
    return sharedClaimEntity;
}

- (void)loadData {
    __weak typeof(self) weakSelf = self;
    // TODO: Progress start
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [weakSelf displayData];
        // TODO Progress dismiss
    });
}

#pragma mark - Overridden getters

/*!
 Override tên bảng dữ liệu vào abstract class
 */
- (NSString *)entityName {
    return @"Claim";
}

/*!
 Override trường dữ liệu làm section
 */
- (NSString *)mainTableSectionNameKeyPath {
    return @"statusCode";
}

/*!
 Override cache cho table
 */
- (NSString *)mainTableCache {
    return @"ClaimCache";
}

/*!
 Override tên trường sẽ được sắp xếp
 */
- (NSArray *)sortKeys {
    return @[@"statusCode"];
}

/*!
 Override kích thước khối dữ liệu
 */
- (NSUInteger)fetchBatchSize {
    return 30;
}

/*!
 Override predicate mặc định
 */
- (NSPredicate *)frcPredicate {
    return nil;
}

/*
 Override định nghĩa câu truy vấn
 */
- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope {
    return [NSPredicate predicateWithFormat:@"(claimId CONTAINS[cd] %@)", searchText];
}

#pragma ClaimEntity methods

+ (Claim *)create {
    NSManagedObjectContext *context = [[[self sharedClaimEntity] fetchedResultsController] managedObjectContext];
    NSEntityDescription *entity = [[[[self sharedClaimEntity] fetchedResultsController] fetchRequest] entity];
    
    Claim *newObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    newObject.claimId = [[[NSUUID UUID] UUIDString] lowercaseString];
    newObject.statusCode = kClaimStatusUpdating;
    newObject.nr = @"Z"; // sort by nr
    return newObject;
}

- (Claim *)create {
    Claim *entityObject = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:self.managedObjectContext];
    entityObject.claimId = [[[NSUUID UUID] UUIDString] lowercaseString];
    entityObject.statusCode = kClaimStatusUpdating;
    
    NSDate *currentDate = [NSDate date];
    entityObject.lodgementDate = [[[OT dateFormatter] stringFromDate:currentDate] substringToIndex:10];
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setMonth:1];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *challengeExpiryDate = [calendar dateByAddingComponents:dateComponents toDate:currentDate options:0];
    entityObject.challengeExpiryDate = [[[OT dateFormatter] stringFromDate:challengeExpiryDate] substringToIndex:10];
    entityObject.nr = @"Z"; // sort by nr
    return entityObject;
}

+ (NSArray *)getCollection {
    [[self sharedClaimEntity] displayData];
    return [[[self sharedClaimEntity] fetchedResultsController] fetchedObjects];
}

+ (Claim *)getClaimByClaimId:(NSString *)claimId {
    [self sharedClaimEntity]->_filteredResults = nil;
    
    [[self sharedClaimEntity] filterContentForSearchText:claimId scope:0];
    if ([self sharedClaimEntity]->_filteredObjects.count > 0) {
        return [[self sharedClaimEntity]->_filteredObjects firstObject];
    }
    return nil;
}

@end
