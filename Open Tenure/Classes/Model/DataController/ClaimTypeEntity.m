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

#import "ClaimTypeEntity.h"

@implementation ClaimTypeEntity

#pragma mark - Data

- (id)init {
    if (self = [super init]) {
        [self loadData];
    }
    return self;
}

+ (ClaimTypeEntity *)sharedClaimTypeEntity {
    static dispatch_once_t once;
    __strong static ClaimTypeEntity *sharedClaimTypeEntity = nil;
    dispatch_once(&once, ^{
        sharedClaimTypeEntity = [self new];
    });
    return sharedClaimTypeEntity;
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
    return @"ClaimType";
}

- (NSString *)mainTableSectionNameKeyPath {
    return @"status";
}

- (NSString *)mainTableCache {
    return @"ClaimTypeCache";
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

+ (BOOL)insertFromResponseObject:(ResponseClaimType *)responseObject {
    NSManagedObjectContext *context = [[[self sharedClaimTypeEntity] fetchedResultsController] managedObjectContext];
    NSEntityDescription *entity = [[[[self sharedClaimTypeEntity] fetchedResultsController] fetchRequest] entity];
    
    ClaimType *entityObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    entityObject.code = responseObject.code;
    entityObject.displayValue = responseObject.displayValue;
    entityObject.note = responseObject.description;
    entityObject.status = responseObject.status;
    entityObject.rrrGroupTypeCode = responseObject.rrrGroupTypeCode;
    entityObject.primary = [NSString stringWithFormat:@"%@", responseObject.primary];
    entityObject.shareCheck = [NSString stringWithFormat:@"%@", responseObject.shareCheck];
    entityObject.partyRequired = [NSString stringWithFormat:@"%@", responseObject.partyRequired];
    entityObject.rrrPanelCode = [NSString stringWithFormat:@"%@", responseObject.rrrPanelCode];;
    NSError *error = nil;
    return [entityObject.managedObjectContext save:&error];
}

+ (BOOL)updateFromResponseObject:(ResponseClaimType *)responseObject {
    [[self sharedClaimTypeEntity] filterContentForSearchText:responseObject.code scope:0];
    if ([self sharedClaimTypeEntity]->_filteredObjects.count == 1) {
        ClaimType *entityObject = [[self sharedClaimTypeEntity]->_filteredObjects firstObject];
        if (![entityObject.displayValue isEqualToString:responseObject.displayValue])
            entityObject.displayValue = responseObject.displayValue;
        if (![entityObject.note isEqualToString:responseObject.description])
            entityObject.note = responseObject.description;
        if (![entityObject.status isEqualToString:responseObject.status])
            entityObject.status = responseObject.status;
        if (![entityObject.rrrGroupTypeCode isEqualToString:responseObject.rrrGroupTypeCode])
            entityObject.rrrGroupTypeCode = responseObject.rrrGroupTypeCode;
        if (![entityObject.primary isEqualToString:responseObject.primary])
            entityObject.primary = responseObject.primary;
        if (![entityObject.shareCheck isEqualToString:responseObject.shareCheck])
            entityObject.shareCheck = responseObject.shareCheck;
        if (![entityObject.rrrPanelCode isEqualToString:responseObject.rrrPanelCode])
            entityObject.rrrPanelCode = responseObject.rrrPanelCode;
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
    [[self sharedClaimTypeEntity] displayData];
    return [[[self sharedClaimTypeEntity] fetchedResultsController] fetchedObjects];
}

+ (ClaimType *)claimTypeByCode:(NSString *)code {
    // Delete last filtered results
    [self sharedClaimTypeEntity]->_filteredResults = nil;
    
    [[self sharedClaimTypeEntity] filterContentForSearchText:code scope:0];
    if ([self sharedClaimTypeEntity]->_filteredObjects.count > 0) {
        return [[self sharedClaimTypeEntity]->_filteredObjects firstObject];
    }
    return nil;
}

+ (ClaimType *)claimTypeByDisplayValue:(NSString *)displayValue {
    [[self sharedClaimTypeEntity] filterContentForSearchText:displayValue scope:1];
    if ([self sharedClaimTypeEntity]->_filteredObjects.count > 0) {
        return [[self sharedClaimTypeEntity]->_filteredObjects firstObject];
    }
    return nil;
}

@end
