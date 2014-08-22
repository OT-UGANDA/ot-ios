//
//  DocumentTypeEntity.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/6/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "DocumentTypeEntity.h"

@implementation DocumentTypeEntity

#pragma mark - Data

- (id)init {
    if (self = [super init]) {
        [self loadData];
    }
    return self;
}

+ (DocumentTypeEntity *)sharedEntity {
    static dispatch_once_t once;
    __strong static DocumentTypeEntity *sharedEntity;
    dispatch_once(&once, ^{
        sharedEntity = [[self alloc] init];
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

- (NSString *)entityName {
    return @"DocumentType";
}

- (NSString *)mainTableSectionNameKeyPath {
    return @"status";
}

- (NSString *)mainTableCache {
    return @"DocumentTypeCache";
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

+ (DocumentType *)create {
    DocumentType *entityObject = [NSEntityDescription insertNewObjectForEntityForName:[[self sharedEntity] entityName] inManagedObjectContext:[[self sharedEntity] managedObjectContext]];
    return entityObject;
}

+ (BOOL)insertFromResponseObject:(ResponseDocumentType *)responseObject {
    DocumentType *entityObject = [self create];
    
    entityObject.code = responseObject.code;
    entityObject.displayValue = responseObject.displayValue;
    entityObject.note = responseObject.description;
    entityObject.status = responseObject.status;
    entityObject.forRegistration = responseObject.forRegistration;
    NSError *error = nil;
    return [entityObject.managedObjectContext save:&error];
}

+ (BOOL)updateFromResponseObject:(ResponseDocumentType *)responseObject {
    [[self sharedEntity] filterContentForSearchText:responseObject.code scope:0];
    if ([self sharedEntity]->_filteredObjects.count == 1) {
        DocumentType *entityObject = [[self sharedEntity]->_filteredObjects firstObject];
        if (![entityObject.displayValue isEqualToString:responseObject.displayValue])
            entityObject.displayValue = responseObject.displayValue;
        if (![entityObject.note isEqualToString:responseObject.description])
            entityObject.note = responseObject.description;
        if (![entityObject.status isEqualToString:responseObject.status])
            entityObject.status = responseObject.status;
        if (![entityObject.forRegistration isEqualToString:responseObject.forRegistration])
            entityObject.forRegistration = responseObject.forRegistration;
        if (![entityObject.managedObjectContext hasChanges]) return NO;
        NSError *error = nil;
        return [entityObject.managedObjectContext save:&error];
    } else {
        return [self insertFromResponseObject:responseObject];
    }
}

+ (NSArray *)getCollection {
    [[self sharedEntity] displayData];
    return [[[self sharedEntity] fetchedResultsController] fetchedObjects];
}

- (NSArray *)getCollection {
    [self displayData];
    return [[self fetchedResultsController] fetchedObjects];
}

+ (DocumentType *)getDocTypeByCode:(NSString *)code {
    
    [self sharedEntity]->_filteredResults = nil;
    
    [[self sharedEntity] filterContentForSearchText:code scope:0];
    if ([self sharedEntity]->_filteredObjects.count > 0) {
        return [[self sharedEntity]->_filteredObjects firstObject];
    }
    return nil;
}

+ (DocumentType *)getDocTypeByDisplayValue:(NSString *)displayValue {
    [[self sharedEntity] filterContentForSearchText:displayValue scope:1];
    if ([self sharedEntity]->_filteredObjects.count > 0) {
        return [[self sharedEntity]->_filteredObjects firstObject];
    }
    return nil;
}

@end
