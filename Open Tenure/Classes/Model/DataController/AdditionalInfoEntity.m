//
//  AdditionalInfoEntity.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/13/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "AdditionalInfoEntity.h"

@implementation AdditionalInfoEntity

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
+ (AdditionalInfoEntity *)sharedEntity {
    static dispatch_once_t once;
    __strong static AdditionalInfoEntity *sharedEntity = nil;
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
    return @"AdditionalInfo";
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
    return @"AdditionalInfoCache";
}

/*!
 Override tên trường sẽ được sắp xếp
 */
- (NSArray *)sortKeys {
    return @[@"key"];
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
    return [NSPredicate predicateWithFormat:@"(key == %@)", searchText];
}

+ (AdditionalInfo *)create {
    AdditionalInfo *newObject = [NSEntityDescription insertNewObjectForEntityForName:[[self sharedEntity] entityName] inManagedObjectContext:[[self sharedEntity] managedObjectContext]];
    return newObject;
}

- (AdditionalInfo *)create {
    id entityObject = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:self.managedObjectContext];
    return entityObject;
}

+ (AdditionalInfo *)createFromDictionary:(NSDictionary *)dictionary {
    dictionary = dictionary.deserialize;
    
    AdditionalInfo *newObject = [self create];
    
    newObject.key = [dictionary objectForKey:@"key"];
    newObject.value = [dictionary objectForKey:@"value"];
    
    NSString *claimId = [dictionary objectForKey:@"claimId"];
    if (claimId != nil) {
        Claim *claim = [ClaimEntity getClaimByClaimId:claimId];
        if (claim) {
            newObject.claim = claim;
        }
    }
    return newObject;
}

@end
