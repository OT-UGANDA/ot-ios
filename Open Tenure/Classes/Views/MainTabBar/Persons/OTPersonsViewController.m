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

#import "OTPersonsViewController.h"
#import "OTPersonTabBarController.h"

@interface OTPersonsViewController ()

@property (nonatomic, strong) NSString *rootViewClassName;

@property (nonatomic, strong) NSIndexPath *handlingIndexPath;

@end

@implementation OTPersonsViewController

#pragma View

- (void)viewDidLoad {
    [super viewDidLoad];
    _searchBar.placeholder = NSLocalizedString(@"action_search", @"Search");
    _searchBar.placeholder = [[_searchBar.placeholder stringByAppendingString:@" "] stringByAppendingString:NSLocalizedString(@"title_persons", @"Persons")];
    
    _rootViewClassName = NSStringFromClass([[[self.navigationController viewControllers] lastObject] class]);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data

- (void)loadData {
    __weak typeof(self) weakSelf = self;
    // TODO: Progress start
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [weakSelf displayData];
        // TODO Progress dismiss
    });
}

#pragma mark - Overridden getters

- (void)setManagedObjectContext:(id)context {
    _managedObjectContext = context;
}

- (NSManagedObjectContext *)managedObjectContext {
    if ([_rootViewClassName isEqualToString:@"OTSelectionTabBarViewController"]) {
        return [[Claim getFromTemporary] managedObjectContext];
    } else if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    return dataContext;
}

- (NSString *)mainTableSectionNameKeyPath {
    return @"person";
}

- (NSString *)mainTableCache {
    return @"PersonCache";
}

- (NSArray *)sortKeys {
    return @[@"person", @"lastName", @"name"];
}

- (NSString *)entityName {
    return @"Person";
}

- (BOOL)showIndexes {
    return YES;
}

- (NSUInteger)fetchBatchSize {
    return 30;
}

- (NSPredicate *)frcPredicate {
    if ([_rootViewClassName isEqualToString:@"OTSelectionTabBarViewController"]) {
        // for claim select person
        return [NSPredicate predicateWithFormat:@"(claim = nil)"];
    }
    return nil;
}

- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope {
    if ([_rootViewClassName isEqualToString:@"OTSelectionTabBarViewController"]) {
        // for claim select person
        return [NSPredicate predicateWithFormat:@"(lastName CONTAINS[cd] %@) OR (name CONTAINS[cd] %@) AND (claim = nil)", searchText, searchText];
    } else {
        // Default
        return [NSPredicate predicateWithFormat:@"(lastName CONTAINS[cd] %@) OR (name CONTAINS[cd] %@)", searchText, searchText];
    }
}

- (NSUInteger)noOfLettersInSearch {
    return 1;
}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    
    Person *person;
    
    if (_filteredObjects == nil)
        person = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        person = [_filteredObjects objectAtIndex:indexPath.row];

    
    if (![person.person boolValue]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", person.name];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [person fullNameType:OTFullNameTypeDefault]];
    }
    cell.detailTextLabel.text = person.idTypeCode;
    
    NSString *imageFile = [FileSystemUtilities getClaimantImagePath:person.personId];
    UIImage *personPicture = [UIImage imageWithContentsOfFile:imageFile];
    if (personPicture == nil) personPicture = [UIImage imageNamed:@"ic_person_picture"];
    cell.imageView.image = personPicture;
}

#pragma Bar Buttons Action

- (IBAction)addPerson:(id)sender {
    [UIAlertView showWithTitle:NSLocalizedString(@"new_entity", nil)
                       message:NSLocalizedString(@"message_entity_type", nil)
             cancelButtonTitle:NSLocalizedString(@"group", @"Group")
             otherButtonTitles:@[NSLocalizedString(@"person", nil)]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                          if (buttonIndex == 0) {
                              [self insertNewPersonWithType:NO];
                          } else {
                              [self insertNewPersonWithType:YES];
                          }
                          
                          UINavigationController *nav = [[self storyboard] instantiateViewControllerWithIdentifier:@"PersonTabBar"];
                          [self.navigationController presentViewController:nav animated:YES completion:nil];
                      }];
}

- (IBAction)showMenu:(id)sender {
    
}

- (IBAction)cancel:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)insertNewPersonWithType:(BOOL)physical {

    NSManagedObjectContext *context = [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] temporaryContext];
    PersonEntity *personEntity = [PersonEntity new];
    [personEntity setManagedObjectContext:context];
    Person *newPerson = [personEntity create];
    newPerson.personId = [[[NSUUID UUID] UUIDString] lowercaseString];
    newPerson.person = [NSNumber numberWithBool:physical];
    // Save person to temporary
    [newPerson setToTemporary];
}

#pragma mark Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
}

#pragma mark - Table View

#pragma mark Editing rows

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_filteredObjects != nil)
        return nil;
    
    NSArray *sections = [_fetchedResultsController sections];
    
    if (sections.count <= section)
        return nil;
    
    return [[[sections objectAtIndex:section] name] boolValue] ? @"Group" : @"Person";
}

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
    
    _handlingIndexPath = indexPath;
    
    Person *person;

    if (_filteredObjects == nil)
        person = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        person = [_filteredObjects objectAtIndex:indexPath.row];

    
    if ([_rootViewClassName isEqualToString:@"OTSelectionTabBarViewController"]) {
        [_delegate personSelection:self didSelectPerson:person];
    } else {
        // Save person to temporary
        [person setToTemporary];
        
        UINavigationController *nav = [[self storyboard] instantiateViewControllerWithIdentifier:@"PersonTabBar"];
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    Person *person;
    
    if (_filteredObjects == nil)
        person = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        person = [_filteredObjects objectAtIndex:indexPath.row];

    if ((person.claim == nil) || ([person.claim.statusCode isEqualToString:@"created"])) {
        return YES;
    }

    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;
    
    Person *person;
    
    if (_filteredObjects == nil)
        person = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        person = [_filteredObjects objectAtIndex:indexPath.row];
    
    // Only allow editing in the local person.
    if ((person.claim == nil) || ([person.claim.statusCode isEqualToString:@"created"])) {
        style = UITableViewCellEditingStyleDelete;
    }
    return style;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Person *person;
    
    if (_filteredObjects == nil)
        person = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        person = [_filteredObjects objectAtIndex:indexPath.row];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.managedObjectContext deleteObject:person];
        [self.managedObjectContext save:nil];
    }
}

@end
