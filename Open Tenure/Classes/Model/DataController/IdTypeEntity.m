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

- (NSArray *)getCollectionWithProperties:(NSArray *)properties {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:self.managedObjectContext]];
    
    if (properties) // Specifies which properties should be returned by the fetch. If properties is nil, all properties should be returned by fetch
        [fetchRequest setPropertiesToFetch:properties];
    [fetchRequest setResultType:NSDictionaryResultType];
    
    // Make sure the results are sorted as well.
    NSMutableArray *sortDescriptors = [NSMutableArray array];
    for (NSString *key in properties) {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Execute the fetch.
    return [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
}

@end
