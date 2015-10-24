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

#import "MapBookmarkEntity.h"

@implementation MapBookmarkEntity

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
+ (MapBookmarkEntity *)sharedEntity {
    static dispatch_once_t once;
    __strong static MapBookmarkEntity *sharedEntity = nil;
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
    return @"MapBookmark";
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
    return @"MapBookmarkCache";
}

/*!
 Override tên trường sẽ được sắp xếp
 */
- (NSArray *)sortKeys {
    return @[@"name"];
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
    return [NSPredicate predicateWithFormat:@"(mapBookmarkId CONTAINS[cd] %@)", searchText];
}

- (MapBookmark *)create {
    MapBookmark *newObject = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]];
    newObject.mapBookmarkId = [[[NSUUID UUID] UUIDString] lowercaseString];
    return newObject;
}

+ (MapBookmark *)create {
    MapBookmark *newObject = [NSEntityDescription insertNewObjectForEntityForName:[[self sharedEntity] entityName] inManagedObjectContext:[[self sharedEntity] managedObjectContext]];
    return newObject;
}

+ (MapBookmark *)createFromDictionary:(NSDictionary *)dictionary {
    dictionary = dictionary.deserialize;
    
    MapBookmark *newObject = [self create];
    
    newObject.mapBookmarkId = [dictionary objectForKey:@"mapBookmarkId"];
    newObject.name = [dictionary objectForKey:@"name"];
    newObject.lat = [dictionary objectForKey:@"lat"];
    newObject.lon = [dictionary objectForKey:@"lon"];
    return newObject;
}

+ (NSArray *)getCollection {
    [[self sharedEntity] displayData];
    return [[[self sharedEntity] fetchedResultsController] fetchedObjects];
}

+ (MapBookmark *)getMapBookmarkByMapBookmarkId:(NSString *)mapBookmarkId {
    [self sharedEntity]->_filteredResults = nil;
    
    [[self sharedEntity] filterContentForSearchText:mapBookmarkId scope:0];
    if ([self sharedEntity]->_filteredObjects.count > 0) {
        return [[self sharedEntity]->_filteredObjects firstObject];
    }
    return nil;
}

@end
