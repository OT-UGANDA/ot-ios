//
//  IdTypeEntity.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/5/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "IdTypeEntity.h"
#import "ResponseIdType.h"
#import "IdType.h"

@interface IdTypeEntity ()

@end

@implementation IdTypeEntity

#pragma mark - Data

- (id)init {
    if (self = [super init]) {
        [self loadData];
    }
    return self;
}

+ (IdTypeEntity *)sharedIdTypeEntity {
    static dispatch_once_t once;
    __strong static IdTypeEntity *sharedIdTypeEntity = nil;
    dispatch_once(&once, ^{
        sharedIdTypeEntity = [self new];
    });
    return sharedIdTypeEntity;
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

- (NSString *)entityName {
    return @"IdType";
}

- (NSString *)mainTableSectionNameKeyPath {
    return @"status";
}

- (NSString *)mainTableCache {
    return @"IdTypeCache";
}

- (NSArray *)sortKeys {
    return @[@"displayValue"];
}

- (NSUInteger)fetchBatchSize {
    return 30;
}

- (NSPredicate *)frcPredicate {
    return nil;
}

- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope {
    if (scope == 0)
        return [NSPredicate predicateWithFormat:@"(code == %@)", searchText];
    else
        return [NSPredicate predicateWithFormat:@"(displayValue == %@)", searchText];
}

+ (BOOL)insertFromResponseObject:(ResponseIdType *)responseObject {
    NSManagedObjectContext *context = [[[self sharedIdTypeEntity] fetchedResultsController] managedObjectContext];
    NSEntityDescription *entity = [[[[self sharedIdTypeEntity] fetchedResultsController] fetchRequest] entity];
    
    IdType *entityObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    entityObject.code = responseObject.code;
    entityObject.displayValue = responseObject.displayValue;
    entityObject.note = responseObject.description;
    entityObject.status = responseObject.status;
    NSError *error = nil;
    return [entityObject.managedObjectContext save:&error];
}

+ (BOOL)updateFromResponseObject:(ResponseIdType *)responseObject {
    [[self sharedIdTypeEntity] filterContentForSearchText:responseObject.code scope:0];
    if ([self sharedIdTypeEntity]->_filteredObjects.count == 1) {
        IdType *entityObject = [[self sharedIdTypeEntity]->_filteredObjects firstObject];
        if (![entityObject.displayValue isEqualToString:responseObject.displayValue])
            entityObject.displayValue = responseObject.displayValue;
        if (![entityObject.note isEqualToString:responseObject.description])
            entityObject.note = responseObject.description;
        if (![entityObject.status isEqualToString:responseObject.status])
            entityObject.status = responseObject.status;
        if (![entityObject.managedObjectContext hasChanges]) return NO;
        NSError *error = nil;
        return [entityObject.managedObjectContext save:&error];
    } else {
        return [self insertFromResponseObject:responseObject];
    }
}

+ (NSArray *)getCollection {
    [[self sharedIdTypeEntity] displayData];
    return [[[self sharedIdTypeEntity] fetchedResultsController] fetchedObjects];
}

- (NSArray *)getCollection {
    [self displayData];
    return [[self fetchedResultsController] fetchedObjects];
}


+ (IdType *)idTypeByCode:(NSString *)code {
    // Delete last filtered results
    [self sharedIdTypeEntity]->_filteredResults = nil;
    
    [[self sharedIdTypeEntity] filterContentForSearchText:code scope:0];
    if ([self sharedIdTypeEntity]->_filteredObjects.count > 0) {
        return [[self sharedIdTypeEntity]->_filteredObjects firstObject];
    }
    return nil;
}

+ (IdType *)idTypeByDisplayValue:(NSString *)displayValue {
    [[self sharedIdTypeEntity] filterContentForSearchText:displayValue scope:1];
    if ([self sharedIdTypeEntity]->_filteredObjects.count > 0) {
        return [[self sharedIdTypeEntity]->_filteredObjects firstObject];
    }
    return nil;
}

@end
