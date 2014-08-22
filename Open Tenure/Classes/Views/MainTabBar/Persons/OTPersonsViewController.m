//
//  OTPersonsViewController.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 7/16/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

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
    return @"personType";
}

- (NSString *)mainTableCache {
    return @"PersonCache";
}

- (NSArray *)sortKeys {
    return @[@"personType", @"lastName", @"firstName"];
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
        return [NSPredicate predicateWithFormat:@"(lastName CONTAINS[cd] %@) OR (firstName CONTAINS[cd] %@) AND (claim = nil)", searchText, searchText];
    } else {
        // Default
        return [NSPredicate predicateWithFormat:@"(lastName CONTAINS[cd] %@) OR (firstName CONTAINS[cd] %@)", searchText, searchText];
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

    
    if ([person.personType isEqualToString:kPersonTypeGroup]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", person.firstName];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [person fullNameType:OTFullNameTypeDefault]];
    }
    cell.detailTextLabel.text = person.idType.displayValue;
    
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
                              [self insertNewPersonWithType:kPersonTypeGroup];
                          } else {
                              [self insertNewPersonWithType:kPersonTypePhysical];
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

- (void)insertNewPersonWithType:(NSString *)personType {

    NSManagedObjectContext *context = [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] temporaryContext];
    PersonEntity *personEntity = [PersonEntity new];
    [personEntity setManagedObjectContext:context];
    Person *newPerson = [personEntity create];
    newPerson.personId = [[[NSUUID UUID] UUIDString] lowercaseString];
    newPerson.personType = personType;
    // Save person to temporary
    [newPerson setToTemporary];
}

#pragma mark Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
}

#pragma mark - Table View

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
