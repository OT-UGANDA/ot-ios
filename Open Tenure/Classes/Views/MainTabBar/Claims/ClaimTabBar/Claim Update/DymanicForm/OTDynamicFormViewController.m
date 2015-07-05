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

#import "OTDynamicFormViewController.h"
#import "OTFormUpdateViewController.h"
#import "OTFormTabBarViewController.h"

@interface OTDynamicFormViewController () <UIAlertViewDelegate>

@end

@implementation OTDynamicFormViewController

- (id)init {
    if (self = [super init]) {
        _tableView.tableFooterView = [UIView new];
        _tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
        _tableView.backgroundColor = [UIColor otLightGreen];
        _tableView.separatorColor = [UIColor otGreen];
        _tableView.tintColor = [UIColor otLightGreen];
    }
    return self;
}

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
    return @"SectionElementPayloadCache";
}

- (NSArray *)sortKeys {
    return @[@"attributeId"];
}

- (NSString *)entityName {
    return @"SectionElementPayload";
}

- (BOOL)showIndexes {
    return NO;
}

- (NSUInteger)fetchBatchSize {
    return 30;
}

- (NSPredicate *)frcPredicate {
    return [NSPredicate predicateWithFormat:@"(sectionPayload.sectionTemplate = %@) and (sectionPayload.formPayload.claim = %@)", _sectionPayload.sectionTemplate, _claim];
}

- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope {
    return nil;
}

- (NSUInteger)noOfLettersInSearch {
    return 1;
}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    SectionElementPayload *sectionElementPayload;
    
    if (_filteredObjects == nil)
        sectionElementPayload = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        sectionElementPayload = [_filteredObjects objectAtIndex:indexPath.row];

    cell.textLabel.text = [NSString stringWithFormat:@"%@", sectionElementPayload.attributeId];
}

#pragma Bar Buttons Action

- (IBAction)done:(id)sender {
    if ([_claim.managedObjectContext hasChanges] && _claim.getViewType == OTViewTypeEdit) {
        [UIAlertView showWithTitle:NSLocalizedStringFromTable(@"title_save_dialog", @"Additional", nil)
                           message:NSLocalizedStringFromTable(@"message_save_dialog", @"Additional", nil) style:UIAlertViewStyleDefault cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"action_save", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                [self.navigationController dismissViewControllerAnimated:NO completion:^{
                    [_claim.managedObjectContext save:nil];
                }];
            } else {
                [self.navigationController dismissViewControllerAnimated:NO completion:^{
                    [self performSelector:@selector(rollback) withObject:nil afterDelay:0];
                }];
            }
            
        }];
    } else {
        [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)rollback {
    [_claim.managedObjectContext rollback];
}

- (IBAction)addFormSection:(id)sender {
    SectionElementPayloadEntity *sectionElementPayloadEntity = [SectionElementPayloadEntity new];
    [sectionElementPayloadEntity setManagedObjectContext:_claim.managedObjectContext];
    FieldPayloadEntity *fieldPayloadEntity = [FieldPayloadEntity new];
    [fieldPayloadEntity setManagedObjectContext:_claim.managedObjectContext];

    // Tạo sectionElementPayload
    SectionElementPayload *sectionElementPayload = [sectionElementPayloadEntity createObject];
    sectionElementPayload.sectionPayload = _sectionPayload;
    // Tạo các fieldPayload theo danh sách fieldTemplate của sectionTemplate
    for (FieldTemplate *fieldTemplate in _sectionPayload.sectionTemplate.fieldTemplateList) {
        FieldPayload *fieldPayload = [fieldPayloadEntity createObject];
        if ([fieldTemplate.fieldType isEqualToString:@"BOOL"]) {
            fieldPayload.fieldValueType = @"BOOL";
            fieldPayload.booleanPayload = [NSNumber numberWithBool:NO];
        } else if ([fieldTemplate.fieldType isEqualToString:@"DECIMAL"] ||
                   [fieldTemplate.fieldType isEqualToString:@"INTEGER"]) {
            fieldPayload.fieldValueType = @"NUMBER";
        } else {
            fieldPayload.fieldValueType = @"TEXT";
            fieldPayload.stringPayload = @"";
        }
        fieldPayload.fieldTemplate = fieldTemplate;
        fieldPayload.sectionElementPayload = sectionElementPayload;
    }
    
    OTFormUpdateViewController *formUpdateViewController = [[OTFormUpdateViewController alloc] init];
    [formUpdateViewController setSectionPayload:_sectionPayload];
    [formUpdateViewController setSectionElementPayload:sectionElementPayload];
    [formUpdateViewController setClaim:_claim];
    [formUpdateViewController setTitle:_sectionPayload.sectionTemplate.elementDisplayName];
    
    OTFormTabBarViewController *formTabBar = [[OTFormTabBarViewController alloc] init];
    [formTabBar setDynamicForm:formUpdateViewController];
    [formTabBar.view setBackgroundColor:[UIColor whiteColor]];
    
    NSString *buttonTitle = [NSString stringWithFormat:@"%@", NSLocalizedString(@"app_name", nil)];
    UIBarButtonItem *logo = [OT logoButtonWithTitle:buttonTitle];
    formTabBar.navigationItem.leftBarButtonItems = @[logo];
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:formUpdateViewController action:@selector(done:)];
    formTabBar.navigationItem.rightBarButtonItem = done;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:formTabBar];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [nav setNavigationBarHidden:NO];
    [nav setToolbarHidden:NO];
    
    //    [nav setModalPresentationStyle:UIModalPresentationFormSheet];
    if (nav != nil) {
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    }
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SectionElementPayload *sectionElementPayload;
    if (_filteredObjects == nil)
        sectionElementPayload = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        sectionElementPayload = [_filteredObjects objectAtIndex:indexPath.row];

    OTFormUpdateViewController *formUpdateViewController = [[OTFormUpdateViewController alloc] init];
    [formUpdateViewController setSectionPayload:_sectionPayload];
    [formUpdateViewController setSectionElementPayload:sectionElementPayload];
    [formUpdateViewController setClaim:_claim];
    [formUpdateViewController setTitle:sectionElementPayload.sectionPayload.sectionTemplate.elementDisplayName];
    
    OTFormTabBarViewController *formTabBar = [[OTFormTabBarViewController alloc] init];
    [formTabBar setDynamicForm:formUpdateViewController];
    [formTabBar.view setBackgroundColor:[UIColor whiteColor]];
    
    NSString *buttonTitle = [NSString stringWithFormat:@"%@", NSLocalizedString(@"app_name", nil)];
    UIBarButtonItem *logo = [OT logoButtonWithTitle:buttonTitle];
    formTabBar.navigationItem.leftBarButtonItems = @[logo];
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:formUpdateViewController action:@selector(done:)];
    formTabBar.navigationItem.rightBarButtonItem = done;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:formTabBar];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [nav setNavigationBarHidden:NO];
    [nav setToolbarHidden:NO];

//    [nav setModalPresentationStyle:UIModalPresentationFormSheet];
    if (nav != nil) {
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return !_claim.getViewType == OTViewTypeView;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        SectionElementPayload *sectionElementPayload = [_fetchedResultsController objectAtIndexPath:indexPath];
        [self.managedObjectContext deleteObject:sectionElementPayload];
    }
}

@end
