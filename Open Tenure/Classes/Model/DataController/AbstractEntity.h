//
//  AbstractEntity.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/5/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AbstractEntity : NSObject {
    NSFetchedResultsController *_fetchedResultsController;
    NSArray *_filteredObjects;
    NSMutableDictionary *_filteredResults;
    NSManagedObjectContext *_managedObjectContext;
}

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

- (void)setManagedObjectContext:(id)context;
- (NSManagedObjectContext *)managedObjectContext;
- (void)displayData;
- (void)filterContentForSearchText:(NSString *)searchText scope:(NSInteger)scope;
- (NSString *)entityName;
- (NSArray *)sortDescriptors;
- (NSArray *)sortKeys;
- (NSPredicate *)frcPredicate;
- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope;
- (NSUInteger)fetchBatchSize;
- (NSString *)mainTableSectionNameKeyPath;
- (NSString *)mainTableCache;

@end