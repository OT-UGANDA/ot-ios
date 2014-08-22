//
//  AbstractEntity.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/5/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

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
        NSLog(@"%@", error);
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

@end