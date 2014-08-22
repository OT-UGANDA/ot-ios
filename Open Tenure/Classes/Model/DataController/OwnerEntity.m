//
//  OwnerEntity.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/15/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OwnerEntity.h"

@implementation OwnerEntity

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
 Tạo sharedEntity chia sẻ thông tin trong static class
 */
+ (OwnerEntity *)sharedEntity {
    static dispatch_once_t once;
    __strong static OwnerEntity *sharedEntity = nil;
    dispatch_once(&once, ^{
        sharedEntity = [self new];
    });
    return sharedEntity;
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
    return @"Owner";
}

/*!
 Override trường dữ liệu làm section
 */
- (NSString *)mainTableSectionNameKeyPath {
    return nil;
}

/*!
 Override cache cho table
 */
- (NSString *)mainTableCache {
    return @"OwnerCache";
}

/*!
 Override tên trường sẽ được sắp xếp
 */
- (NSArray *)sortKeys {
    return @[@"nominator"];
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
    return [NSPredicate predicateWithFormat:@"(ownerId == %@)", searchText];
}

- (Owner *)create {
    Owner *newObject = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]];
    return newObject;
}

+ (Owner *)create {
    Owner *newObject = [NSEntityDescription insertNewObjectForEntityForName:[[self sharedEntity] entityName] inManagedObjectContext:[[self sharedEntity] managedObjectContext]];
    return newObject;
}

+ (Owner *)createFromDictionary:(NSDictionary *)dictionary {
    dictionary = dictionary.deserialize;
    
    Owner *newObject = [self create];

    newObject.ownerId = [dictionary objectForKey:@"ownerId"];
    newObject.nominator = [dictionary objectForKey:@"nominator"];
    newObject.denominator = [dictionary objectForKey:@"denominator"];
    
    NSString *claimId = [dictionary objectForKey:@"claimId"];
    
    if (claimId != nil) {
        Claim *claim = [ClaimEntity getClaimByClaimId:claimId];
        if (claim) {
            newObject.claim = claim;
        }
    }
    
    NSString *personId = [dictionary objectForKey:@"personId"];
    if (personId != nil) {
        Person *person = [PersonEntity getPersonByPersonId:personId];
        if (person) {
            newObject.person = person;
        }
    }
    return newObject;
}

@end
