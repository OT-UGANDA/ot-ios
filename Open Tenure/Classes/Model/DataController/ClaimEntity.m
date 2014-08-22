//
//  ClaimEntity.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/6/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

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
    return [NSPredicate predicateWithFormat:@"(claimId == %@)", searchText];
}

#pragma ClaimEntity methods

+ (Claim *)create {
    NSManagedObjectContext *context = [[[self sharedClaimEntity] fetchedResultsController] managedObjectContext];
    NSEntityDescription *entity = [[[[self sharedClaimEntity] fetchedResultsController] fetchRequest] entity];
    
    Claim *newObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    newObject.claimId = [[[NSUUID UUID] UUIDString] lowercaseString];
    newObject.statusCode = kClaimStatusCreated;
    return newObject;
}

- (Claim *)create {
    Claim *entityObject = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:self.managedObjectContext];
    entityObject.claimId = [[[NSUUID UUID] UUIDString] lowercaseString];
    entityObject.statusCode = kClaimStatusCreated;
    return entityObject;
}

+ (BOOL)insertFromResponseObject:(ResponseClaim *)responseObject {
    NSManagedObjectContext *context = [[[self sharedClaimEntity] fetchedResultsController] managedObjectContext];
    NSEntityDescription *entity = [[[[self sharedClaimEntity] fetchedResultsController] fetchRequest] entity];
    
    Claim *entityObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    entityObject.claimId = responseObject.claimId;
    entityObject.statusCode = responseObject.statusCode;
    NSError *error = nil;
    return [entityObject.managedObjectContext save:&error];
}

+ (BOOL)updateFromResponseObject:(ResponseClaim *)responseObject {
    [[self sharedClaimEntity] filterContentForSearchText:responseObject.claimId scope:0];
    if ([self sharedClaimEntity]->_filteredObjects.count > 0) {
        
        Claim *entityObject = [[self sharedClaimEntity]->_filteredObjects firstObject];
        
        if (![entityObject.statusCode isEqualToString:responseObject.statusCode])
            entityObject.statusCode = responseObject.statusCode;
        
        if ([entityObject.managedObjectContext hasChanges]) {
            return [entityObject.managedObjectContext save:nil];
        }
        // Trường hợp lỗi cập nhật của lần trước đó
        if (entityObject.claimName == nil) return YES;
        
        return NO;
    } else {
        return [self insertFromResponseObject:responseObject];
    }
}

+ (Claim *)updateDetailFromResponseObject:(ResponseClaim *)responseObject {
    // Delete last filtered results
    [self sharedClaimEntity]->_filteredResults = nil;
    
    [[self sharedClaimEntity] filterContentForSearchText:responseObject.claimId scope:0];
    if ([self sharedClaimEntity]->_filteredObjects.count > 0) {
        Claim *entityObject = [[self sharedClaimEntity]->_filteredObjects firstObject];
        
        entityObject.mappedGeometry = responseObject.mappedGeometry;
        entityObject.claimName = responseObject.claimName;
        entityObject.gpsGeometry = responseObject.gpsGeometry;
        entityObject.startDate = responseObject.startDate;
        entityObject.claimNumber = responseObject.nr;
        entityObject.northAdjacency = responseObject.northAdjacency;
        entityObject.shouthAdjacency = responseObject.shouthAdjacency;
        entityObject.eastAdjacency = responseObject.eastAdjacency;
        entityObject.westAdjacency = responseObject.westAdjacency;
        entityObject.notes = responseObject.notes;
 
        if ([entityObject.managedObjectContext hasChanges]) {
            if ([entityObject.managedObjectContext save:nil]) return entityObject;
        }
        return nil;
    } else {
        // Error
        return nil;
    }
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
