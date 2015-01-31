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
        return [NSPredicate predicateWithFormat:@"(code CONTAINS[cd] %@)", searchText];
    else
        return [NSPredicate predicateWithFormat:@"(displayValue CONTAINS[cd] %@)", searchText];
}

+ (DocumentType *)create {
    DocumentType *entityObject = [NSEntityDescription insertNewObjectForEntityForName:[[self sharedEntity] entityName] inManagedObjectContext:[[self sharedEntity] managedObjectContext]];
    return entityObject;
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
