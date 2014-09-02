//
//  OTAdditionalUpdateViewController.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/9/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTAdditionalUpdateViewController.h"

@interface OTAdditionalUpdateViewController () <UIAlertViewDelegate>

@end

@implementation OTAdditionalUpdateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadData];
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
    return @"AdditionalInfoCache";
}

- (NSArray *)sortKeys {
    return @[@"key"];
}

- (NSString *)entityName {
    return @"AdditionalInfo";
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
    
    AdditionalInfo *additionalInfo;
    
    if (_filteredObjects == nil)
        additionalInfo = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        additionalInfo = [_filteredObjects objectAtIndex:indexPath.row];

    cell.textLabel.text = [NSString stringWithFormat:@"%@ = %@", additionalInfo.key, additionalInfo.value];
}

#pragma Bar Buttons Action

- (IBAction)addAdditionalInfo:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"new_additional_info", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"confirm", nil), nil];
    
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    
    UITextField *textFieldKey = [alertView textFieldAtIndex:0];
    UITextField *textFieldValue = [alertView textFieldAtIndex:1];
    
    [textFieldKey setPlaceholder:NSLocalizedString(@"add_key", nil)];
    [textFieldValue setPlaceholder:NSLocalizedString(@"add_value", nil)];
    [textFieldValue setSecureTextEntry:NO];
    
    [alertView show];
}

#pragma UIAlertViewDelegate method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        UITextField *textFieldKey = [alertView textFieldAtIndex:0];
        UITextField *textFieldValue = [alertView textFieldAtIndex:1];
        [self validateKey:textFieldKey.text andValue:textFieldValue.text];
    }
}

#pragma Function

- (void)validateKey:(NSString *)key andValue:(NSString *)value {
    
    BOOL valid = YES;
    if ([[_claim objectID] isTemporaryID]) {
        valid = NO;
        [OT handleErrorWithMessage:NSLocalizedString(@"message_save_claim_before_adding_content", nil)];
        return;
    } else {
        if (key == nil || key.length == 0) valid = NO;
        if (value == nil || value.length == 0) valid = NO;
    }
    
    if (valid) {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    key, @"key",
                                    value, @"value", nil];
        AdditionalInfo *newAdditionalInfo = [AdditionalInfoEntity create];
        [newAdditionalInfo importFromJSON:dictionary];
        if (newAdditionalInfo != nil) {
            newAdditionalInfo.claim = _claim;
            [newAdditionalInfo.managedObjectContext save:nil];
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"saved", nil)];
        } else
            [OT handleErrorWithMessage:NSLocalizedString(@"message_error_creating_additional_info", nil)];
    } else
        [OT handleErrorWithMessage:NSLocalizedString(@"message_error_creating_additional_info", nil)];
}

#pragma UITableViewDelegate methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        AdditionalInfo *additionalInfo = [_fetchedResultsController objectAtIndexPath:indexPath];
        [self.managedObjectContext deleteObject:additionalInfo];
    }
}

@end
