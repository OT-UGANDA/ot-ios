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

#import "AbstractEntity.h"

@implementation AbstractEntity

@synthesize fetchedResultsController = _fetchedResultsController;

- (id)init {
    if (self = [super init]) {
        _filteredResults = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    _fetchedResultsController = nil;
}

- (void)displayData {
    [NSFetchedResultsController deleteCacheWithName:[self mainTableCache]];
    
    NSError *error = nil;
    
    if (![self.fetchedResultsController performFetch:&error]) {
        ALog(@"%@", error);
        abort();
    }
}

#pragma mark - Getters

- (void)setManagedObjectContext:(id)context {
    _managedObjectContext = context;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil)
        return _managedObjectContext;
    
    return dataContext;
}

- (NSString *)entityName {
    return nil;
}

- (NSArray *)sortDescriptors {
    return nil;
}

- (NSArray *)sortKeys {
    return nil;
}

- (NSString *)mainTableSectionNameKeyPath {
    return nil;
}

- (NSString *)mainTableCache {
    return nil;
}

- (NSPredicate *)frcPredicate {
    return nil;
}

- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope {
    return nil;
}

- (BOOL)showIndexes {
    return NO;
}

- (NSUInteger)fetchBatchSize {
    return 30;
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) return _fetchedResultsController;
    
    //delete cache
    [NSFetchedResultsController deleteCacheWithName:[self mainTableCache]];
    
    //request
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    
    //entity
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    //predicate
    NSPredicate *predicate = [self frcPredicate];
    if (predicate)
        [fetchRequest setPredicate:predicate];
    
    //sort descriptors
    NSArray *sortDescriptors = [self sortDescriptors];
    
    if (!sortDescriptors || [sortDescriptors count] == 0) {
        NSArray *sortKeys = [self sortKeys];
        
        if (sortKeys && [sortKeys count] > 0) {
            NSMutableArray *descriptors = [NSMutableArray new];
            
            for (NSString *key in sortKeys) {
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
                [descriptors addObject:sortDescriptor];
            }
            
            sortDescriptors = [NSArray arrayWithArray:descriptors];
        }
    }
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    //batch size
    [fetchRequest setFetchBatchSize:[self fetchBatchSize]];
    
    //fetched results controller
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:self.managedObjectContext
                                                                      sectionNameKeyPath:[self mainTableSectionNameKeyPath]
                                                                               cacheName:[self mainTableCache]];
    return _fetchedResultsController;
}

#pragma mark - Content Filtering

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSInteger)scope {

    _filteredObjects = [_filteredResults objectForKey:searchText];
    
    if (!_filteredObjects) {
        NSPredicate *predicate = [self searchPredicateWithSearchText:searchText scope:scope];
        
        for (NSString *cachedSearchText in [[_filteredResults allKeys] sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"length" ascending:NO]]]) {
            if ([searchText hasPrefix:cachedSearchText]) {
                _filteredObjects = [[_filteredResults objectForKey:cachedSearchText] filteredArrayUsingPredicate:predicate];
                break;
            }
        }
        
        if (!_filteredObjects) {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            
            NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:self.managedObjectContext];
            fetchRequest.entity = entity;
            
            fetchRequest.predicate = predicate;
            
            NSMutableArray *sortDescriptors = [NSMutableArray new];
            
            for (NSString *key in [self sortKeys]) {
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
                [sortDescriptors addObject:sortDescriptor];
            }
            
            if ([sortDescriptors count] > 0)
                fetchRequest.sortDescriptors = [NSArray arrayWithArray:sortDescriptors];
            
            _filteredObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
        }
        
        [_filteredResults setObject:_filteredObjects forKey:searchText];
    }
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