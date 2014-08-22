//
//  LandUseEntity.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/6/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "LandUseEntity.h"
#import "ResponseLandUse.h"

@implementation LandUseEntity

#pragma mark - Data

- (id)init {
    if (self = [super init]) {
        [self loadData];
    }
    return self;
}

+ (LandUseEntity *)sharedLandUseEntity {
    static dispatch_once_t once;
    __strong static LandUseEntity *sharedLandUseEntity = nil;
    dispatch_once(&once, ^{
        sharedLandUseEntity = [self new];
    });
    return sharedLandUseEntity;
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
    return @"LandUse";
}

- (NSString *)mainTableSectionNameKeyPath {
    return @"status";
}

- (NSString *)mainTableCache {
    return @"LandUseCache";
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

+ (BOOL)insertFromResponseObject:(ResponseLandUse *)responseObject {
    NSManagedObjectContext *context = [[[self sharedLandUseEntity] fetchedResultsController] managedObjectContext];
    NSEntityDescription *entity = [[[[self sharedLandUseEntity] fetchedResultsController] fetchRequest] entity];
    
    LandUse *entityObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    entityObject.code = responseObject.code;
    entityObject.displayValue = responseObject.displayValue;
    entityObject.note = responseObject.description;
    entityObject.status = responseObject.status;
    NSError *error = nil;
    return [entityObject.managedObjectContext save:&error];
}

+ (BOOL)updateFromResponseObject:(ResponseLandUse *)responseObject {
    [[self sharedLandUseEntity] filterContentForSearchText:responseObject.code scope:0];
    if ([self sharedLandUseEntity]->_filteredObjects.count == 1) {
        LandUse *entityObject = [[self sharedLandUseEntity]->_filteredObjects firstObject];
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

- (NSArray *)getCollection {
    [self displayData];
    return [[self fetchedResultsController] fetchedObjects];
}

+ (NSArray *)getCollection {
    [[self sharedLandUseEntity] displayData];
    return [[[self sharedLandUseEntity] fetchedResultsController] fetchedObjects];
}

+ (LandUse *)landUseByCode:(NSString *)code {
    // Delete last filtered results
    [self sharedLandUseEntity]->_filteredResults = nil;
    
    [[self sharedLandUseEntity] filterContentForSearchText:code scope:0];
    if ([self sharedLandUseEntity]->_filteredObjects.count > 0) {
        return [[self sharedLandUseEntity]->_filteredObjects firstObject];
    }
    return nil;
}

+ (LandUse *)landUseByDisplayValue:(NSString *)displayValue {
    [[self sharedLandUseEntity] filterContentForSearchText:displayValue scope:1];
    if ([self sharedLandUseEntity]->_filteredObjects.count > 0) {
        return [[self sharedLandUseEntity]->_filteredObjects firstObject];
    }
    return nil;
}

@end
