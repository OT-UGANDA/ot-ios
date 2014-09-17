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

#import "OTAbstractListViewController.h"
#import "UIColor+OT.h"

@interface OTAbstractListViewController ()

//@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation OTAbstractListViewController

@synthesize fetchedResultsController = _fetchedResultsController;

- (id)init {
    if (self = [super init]) {
        [self setupTableView];
    }
    return self;
}

- (void)setupTableView {
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    tableView.separatorColor = [UIColor otGreen];
    tableView.delegate = self;
    tableView.dataSource = self;
    
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _tableView = tableView;
    self.view = _tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _filteredResults = [NSMutableDictionary new];
}

- (void)viewDidUnload
{
    _fetchedResultsController = nil;
    
    [super viewDidUnload];
}

- (void)displayData {
    [NSFetchedResultsController deleteCacheWithName:[self mainTableCache]];
    
    NSError *error = nil;
    
    if ([self.fetchedResultsController performFetch:&error]) {
        [_tableView reloadData];
    }
    else {
        ALog(@"%@", error);
        abort();
    }
}

#pragma mark - Getters

- (NSManagedObjectContext *)managedObjectContext {
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

- (NSUInteger)noOfLettersInSearch {
    return 0;
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
    
    _fetchedResultsController.delegate = self;
    return _fetchedResultsController;
}

#pragma mark Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [_tableView setEditing:editing animated:YES];
    if (![self isEditing]) {
        NSError *error = nil;
		if (![self.managedObjectContext save:&error]) {
			ALog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _filteredObjects == nil ? [[_fetchedResultsController sections] count] : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (_filteredObjects == nil) {
        id sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
    else {
        return [_filteredObjects count];
    }

}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    cell.separatorInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UIView *selectionColor = [[UIView alloc] init];
    selectionColor.backgroundColor = [UIColor otGreen];
    cell.selectedBackgroundView = selectionColor;
    cell.textLabel.highlightedTextColor = [UIColor whiteColor];
    cell.detailTextLabel.highlightedTextColor = [UIColor whiteColor];
    cell.backgroundColor = [UIColor otLightGreen];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    // Background color
    view.tintColor = [UIColor otLightGrey];
    
    // Text Color
    // UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    // [header.textLabel setTextColor:[UIColor otDarkBlue]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_filteredObjects != nil)
        return nil;
    
    NSArray *sections = [_fetchedResultsController sections];
    
    if (sections.count <= section)
        return nil;
    
    return [[sections objectAtIndex:section] name];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [[_fetchedResultsController sectionIndexTitles] indexOfObject:title];
}

#pragma mark - Table view delegate

#pragma mark Editing rows

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *rowToSelect = indexPath;
    
    // If editing, don't allow row to be selected
    if ([self isEditing]) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        rowToSelect = nil;
    }
    
	return rowToSelect;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Content Filtering

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSInteger)scope {
    if ([searchText length] != 0 && [searchText length] >= [self noOfLettersInSearch]) {
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
        
        _noResultsLabel.text = @"No Results";
    }
    else {
        _filteredObjects = nil;
        
        _noResultsLabel.text = [NSString stringWithFormat:@"Enter %tu letters or more.", [self noOfLettersInSearch]];
    }
    
    [_tableView reloadData];
}

#pragma mark - UISearchDisplayDelegate

#pragma UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    // When the search string changes, filter the recents list accordingly.
    [self filterContentForSearchText:searchText
                               scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = nil;
    _filteredObjects = nil;
    [_tableView reloadData];
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
    _filteredObjects = nil;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    if (!_noResultsLabel) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.001), dispatch_get_main_queue(), ^(void) {
            for (UIView *v in self.searchDisplayController.searchResultsTableView.subviews)
            {
                if ([v isKindOfClass: [UILabel class]] && [[(UILabel*)v text] isEqualToString:@"No Results"])
                {
                    _noResultsLabel = (UILabel *)v;
                    
                    if ([searchString length] < [self noOfLettersInSearch])
                    {
                        _noResultsLabel.text = [NSString stringWithFormat:@"Enter %tu letters or more.", [self noOfLettersInSearch]];
                    }
                    
                    break;
                }
            }
        });
    }
    
    [self filterContentForSearchText:searchString
                               scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text]
                               scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
    
    return YES;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    _filteredObjects = nil;
    _filteredResults = [NSMutableDictionary new];
    
    [_tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[_tableView cellForRowAtIndexPath:indexPath] forTableView:_tableView atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [_tableView deleteRowsAtIndexPaths:[NSArray
                                                arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [_tableView insertRowsAtIndexPaths:[NSArray
                                                arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [_tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [_tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [_tableView endUpdates];
}

@end