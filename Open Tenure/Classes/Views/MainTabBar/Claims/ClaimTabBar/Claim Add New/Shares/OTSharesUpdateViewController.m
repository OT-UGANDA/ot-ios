//
//  OTFormSharesViewController.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/9/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTSharesUpdateViewController.h"
#import "OTSelectionTabBarViewController.h"
#import "PickerView.h"

@interface OTSharesUpdateViewController () <OTSelectionTabBarViewControllerDelegate>
@property (nonatomic, strong) PickerView *pickerView;

@property  NSInteger *selectedRow;
@end

@implementation OTSharesUpdateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadData];
     NSMutableArray *items = [NSMutableArray array];
    for (NSUInteger i = 0; i < 100; i++)
    {
        [items addObject:@(i)];
    }
   
    self.pickerView = [[PickerView alloc] initWithPickItems:items];
    [_pickerView setPickType:PickTypeList];
    
}

- (void)didReceiveMemoryWarning
{
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

- (NSManagedObjectContext *)managedObjectContext {
    return _claim.managedObjectContext;
}

- (NSString *)mainTableSectionNameKeyPath {
    return nil;
}

- (NSString *)mainTableCache {
    return @"OwnerCache";
}

- (NSArray *)sortKeys {
    return @[@"nominator"];
}

- (NSString *)entityName {
    return @"Owner";
}

- (BOOL)showIndexes {
    return NO;
}

- (NSUInteger)fetchBatchSize {
    return 30;
}

- (NSPredicate *)frcPredicate {
    return [NSPredicate predicateWithFormat:@"(claim = %@)", _claim];
}

- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope {
    return nil;
}

- (NSUInteger)noOfLettersInSearch {
    return 1;
}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    
    Owner *owner;
    
    if (_filteredObjects == nil)
        owner = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        owner = [_filteredObjects objectAtIndex:indexPath.row];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text = [NSString stringWithFormat:@"%@\n%@", owner.person.personId, [owner.person fullNameType:OTFullNameTypeDefault]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%tu", [owner.nominator integerValue]];
}

#pragma Bar Buttons Action

- (IBAction)addShare:(id)sender {
    NSInteger freeShare = [self getFreeShare];
    if (freeShare <= 0) {
        //If number of owner
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_no_available_shares", nil)];
   } else {
        // TODO: Select person, create new Owner
        /*
         Owner *owner = [OwnerEntity create];
         owner.ownerId = [[[NSUUID UUID] UUIDString] lowercaseString];
         owner.person = person;
         owner.denominator = [NSNumber numberWithInteger:100];
         owner.nominator = [NSNumber numberWithInteger:freeShare];
         owner.claim = _claim;
         */
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:OTPersonSelectionAction] forKey:@"OTSelectionAction"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        OTAppDelegate* appDelegate = (OTAppDelegate*)[[UIApplication sharedApplication] delegate];
        id main = appDelegate.window.rootViewController;
        OTSelectionTabBarViewController *selectionViewController = (OTSelectionTabBarViewController *)[[main storyboard] instantiateViewControllerWithIdentifier:@"SelectionTabBarDetail"];
        selectionViewController.selectionDelegate = self;
        
        UINavigationController *nav = [[main storyboard] instantiateViewControllerWithIdentifier:@"SelectionTabBar"];
        nav = [nav initWithRootViewController:selectionViewController];
        
        if (nav != nil) {
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        }

  }
}

- (NSInteger)getFreeShare {
    double scale = 0.0;
    for (Owner *owner in _claim.owners) {
        scale += ([owner.nominator doubleValue] / [owner.denominator doubleValue]);
    }
    return (1 - scale) * 100;
}

#pragma UITableViewDelegate methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    cell.tintColor = [UIColor otDarkBlue];
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
  
    
    return cell;
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    // TODO: Free share
    // Test
    [UIAlertView showWithTitle:@"New share percentage" message:nil style:UIAlertViewStylePlainTextInput cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"OK", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            Owner *owner = [_fetchedResultsController objectAtIndexPath:indexPath];
            NSString *s = [[alertView textFieldAtIndex:0] text];
            NSInteger num = [s integerValue];
            // TODO check valid
            [owner setNominator:[NSNumber numberWithInteger:num]];
        }
    }];
//    
//   UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New share percentage"
//                                                        message:nil
//                                                       delegate:self
//                                              cancelButtonTitle:NSLocalizedString(@"cancel", nil)
//                                              otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
//
//    //NSLog(@"%i",[[tableView indexPathForSelectedRow] row]);
//    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
//    [[alertView textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"message_enter_description", nil)];
//    //[[alertView textFieldAtIndex:0] setDelegate:self];
//    [alertView show];
//    
//    //[[_claim.owners.allObjects firstObject] setNominator:[NSNumber numberWithInteger:60]];
   // [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Do free share %tu", [self getFreeShare]]];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Owner *owner = [_fetchedResultsController objectAtIndexPath:indexPath];
        [self.managedObjectContext deleteObject:owner];
    }
}
//
//- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
//    
//    //which button was pressed in the alert view
//    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
//    if ([buttonTitle isEqualToString:@"Ok"]){
//        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
//        [f setNumberStyle:NSNumberFormatterDecimalStyle];
//        NSNumber * myNumber = [f numberFromString:[[alertView textFieldAtIndex:0] text]];
//     
//        
//       // Person* p= _claim.owners.allObjects[(int)_selectedRow];
////       Person* p= [_claim.owners.allObjects[(int)_selectedRow] valueForKey:@"person"];
//      //  NSLog(@"%@ %@", p.lastName, );
//        [_claim.owners.allObjects[(int)_selectedRow] setNominator:myNumber];
//        //NSLog(@"%@",p.lastName );
//        [_tableView reloadData];
//    }
//    else if ([buttonTitle isEqualToString:@"Cancel"]){
//        NSLog(@"Cancel button was pressed.");
//    }
//}

#pragma OTSelectionTabBarViewControllerDelegate methods

- (void)personSelection:(OTSelectionTabBarViewController *)controller didSelectPerson:(Person *)person {
    // TODO: Thêm share ở đây
   // _claim.owners
   // _claim.person = person;
   // _claimantBlock.textField.text = [person fullNameType:OTFullNameTypeDefault];
   // _claimantBlock.validationState = BPFormValidationStateValid;
    
    OwnerEntity *ownerEntity = [OwnerEntity new];
    [ownerEntity setManagedObjectContext:_claim.managedObjectContext];
    Owner *owner = [ownerEntity create];
    owner.ownerId = [[[NSUUID UUID] UUIDString] lowercaseString];
    owner.person = person;
    owner.denominator = [NSNumber numberWithInteger:100];
    owner.nominator = [NSNumber numberWithInteger:[self getFreeShare]];
    owner.claim = _claim;

    [_claim.managedObjectContext save:nil];
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
