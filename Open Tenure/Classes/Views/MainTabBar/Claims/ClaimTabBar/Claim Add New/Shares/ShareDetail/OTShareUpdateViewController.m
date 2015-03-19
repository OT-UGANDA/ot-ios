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

#import "OTShareUpdateViewController.h"
#import "OTSelectionTabBarViewController.h"

@interface OTShareUpdateViewController () <OTSelectionTabBarViewControllerDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *pickerViewBackground;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) NSMutableArray *pickerItems;

@property (nonatomic, strong) IBOutlet UITextField *textField;
@property (nonatomic, strong) IBOutlet UILabel *shareLabel;

@end
@implementation OTShareUpdateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
    singleTap.delegate = self;
    singleTap.numberOfTapsRequired = 1;
    [_tableView addGestureRecognizer:singleTap];

    
    [self loadData];
    _share = [Share getFromTemporary];
    
    _pickerItems = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 100; i++)
        [_pickerItems addObject:[@(i) stringValue]];

    [_tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"Header"];
    
    // Add percentage value

    CGFloat cellSpace = 16;
    CGFloat headerWidth = 320;
    CGFloat headerHeight = 88;

    CGFloat labelHeight = 18;
    CGFloat labelWidth = 160;
    
    CGRect frame = CGRectMake(0, 0, headerWidth, headerHeight);
    UIView *headerView = [[UIView alloc] initWithFrame:frame];
    
    // Col 1
    frame.origin.x = cellSpace;
    frame.origin.y = cellSpace;
    frame.size.height = labelHeight;
    frame.size.width = labelWidth;
    UILabel *label1 = [[UILabel alloc] initWithFrame:frame];
    label1.font = [UIFont systemFontOfSize:14];
    label1.text = NSLocalizedString(@"Percentage value", nil);
    [headerView addSubview:label1];

    UIButton *pickerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *pickerImage = [UIImage imageNamed:@"ic_action_picker"];
    [pickerButton setImage:pickerImage forState:UIControlStateNormal];
    [pickerButton addTarget:self action:@selector(pickerButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
    frame.origin.x = cellSpace;
    frame.origin.y += labelHeight + cellSpace;
    frame.size.width = pickerImage.size.width;
    frame.size.height = pickerImage.size.height;
    pickerButton.frame = frame;
    [headerView addSubview:pickerButton];

    frame.origin.x += pickerButton.frame.size.width + 2;
    frame.origin.y -= 2.0f;
    frame.size.width = 88.0f;
    frame.size.height = 23.0f;
    _shareLabel = [[UILabel alloc] initWithFrame:frame];
    _shareLabel.layer.backgroundColor = [[UIColor whiteColor] CGColor];
    _shareLabel.layer.borderColor = [[UIColor otGreen] CGColor];
    _shareLabel.layer.borderWidth = 1;
    _shareLabel.textAlignment = NSTextAlignmentCenter;
    _shareLabel.font = [UIFont systemFontOfSize:14];
    _shareLabel.text = [@([_share.nominator integerValue]) stringValue];
    [headerView addSubview:_shareLabel];
    
    // Col 2
    frame.origin.x = label1.frame.size.width + cellSpace;
    frame.origin.y = cellSpace;
    frame.size.height = labelHeight;
    frame.size.width = labelWidth;
    UILabel *label2 = [[UILabel alloc] initWithFrame:frame];
    label2.font = [UIFont systemFontOfSize:14];
    label2.text = NSLocalizedString(@"Add another owner", nil);
    [headerView addSubview:label2];

    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *addButtonImage = [UIImage imageNamed:@"ic_action_add_claimant"];
    [addButton setImage:addButtonImage forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(addPerson:) forControlEvents:UIControlEventTouchUpInside];
    frame.origin.y += labelHeight + cellSpace;
    frame.size.width = addButtonImage.size.width;
    frame.size.height = addButtonImage.size.height;
    addButton.frame = frame;
    [headerView addSubview:addButton];

    _tableView.tableHeaderView = headerView;
    _tableView.tableFooterView = [UIView new];

    [_tableView setSeparatorInset:UIEdgeInsetsMake(0, 16, 0, 16)];
//    [_tableView setSeparatorColor:[UIColor otGreen]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)singleTapAction:(id)sender {
    [_pickerViewBackground removeFromSuperview];
    _pickerViewBackground = nil;
}

- (IBAction)pickerButtonTapped:(id)sender event:(id)event {
    if (_share.claim.getViewType == OTViewTypeView) return;
    if (_pickerViewBackground != nil) {
        [_pickerViewBackground removeFromSuperview];
        _pickerViewBackground = nil;
        return;
    }
    
    CGRect frame = _shareLabel.frame;
    
    _pickerViewBackground = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, _shareLabel.frame.origin.y + _shareLabel.frame.size.height, frame.size.width, 200)];
    _pickerViewBackground.layer.borderColor = [[UIColor otGreen] CGColor];
    _pickerViewBackground.layer.borderWidth = 1;
//        _pickerViewBackground.layer.cornerRadius = 4.0f;
    _pickerViewBackground.backgroundColor = [UIColor whiteColor];
    
    _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 200)];
    _pickerView.delegate = self;
//
//    _pickerClaimTypeShowing = YES;
//    [_pickerView reloadAllComponents];

    [_pickerView selectRow:[_share.nominator integerValue]-1 inComponent:0 animated:YES];
    
    [_pickerViewBackground addSubview:_pickerView];
    [self.view addSubview:_pickerViewBackground];
//    } else [self hidePickers];
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
    return _share.managedObjectContext;
}

- (NSString *)mainTableSectionNameKeyPath {
    return nil;
}

- (NSString *)mainTableCache {
    return @"PersonCache";
}

- (NSArray *)sortKeys {
    return @[@"name"];
}

- (NSString *)entityName {
    return @"Person";
}

- (BOOL)showIndexes {
    return NO;
}

- (NSUInteger)fetchBatchSize {
    return 30;
}

- (NSPredicate *)frcPredicate {
    return [NSPredicate predicateWithFormat:@"(owner = %@)", _share];
}

- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope {
    return nil;
}

- (NSUInteger)noOfLettersInSearch {
    return 1;
}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    Person *person;
    
    person = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    if (![person.person boolValue]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", person.name];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [person fullNameType:OTFullNameTypeDefault]];
    }
    cell.detailTextLabel.text = person.idTypeCode;
    
    NSString *imagePath;
    NSString *imageFile = [person.personId stringByAppendingPathExtension:@"jpg"];
    if (person.claim == nil) { // owner
        imagePath = [FileSystemUtilities getClaimantFolder:person.owner.claim.claimId];
    } else {
        imagePath = [FileSystemUtilities getClaimantFolder:person.claim.claimId];
    }
    imageFile = [imagePath stringByAppendingPathComponent:imageFile];

    UIImage *personPicture = [UIImage imageWithContentsOfFile:imageFile];
    if (personPicture == nil) personPicture = [UIImage imageNamed:@"ic_person_picture"];
    cell.imageView.image = personPicture;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Person *person;
    
    if (_filteredObjects == nil)
        person = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        person = [_filteredObjects objectAtIndex:indexPath.row];
    
    // Save person to temporary
    [person setToTemporary];
    
    UINavigationController *nav = [[self storyboard] instantiateViewControllerWithIdentifier:@"PersonTabBar"];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Person *person;
    
    if (_filteredObjects == nil)
        person = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        person = [_filteredObjects objectAtIndex:indexPath.row];
    if ([person.owner.claim.statusCode isEqualToString:kClaimStatusCreated]) {
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
    
    //    // Only allow editing claim.
    //    if (?) {
    //        style = UITableViewCellEditingStyleDelete;
    //    }
    style = UITableViewCellEditingStyleDelete;
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"Header"];
    headerView.tintColor = [UIColor otGreen];
    CGRect frame = tableView.frame;
    frame.origin.x = 10;
    frame.size.height = 20;
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.font = [UIFont boldSystemFontOfSize:14];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 0;
    label.text = NSLocalizedString(@"owners", nil);
    [headerView addSubview:label];
    return headerView;;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Background color
    view.tintColor = [UIColor otGreen];
    // Text Color
}

- (IBAction)addPerson:(id)sender {
    if (_share.claim.getViewType == OTViewTypeView) return;
    if (_pickerViewBackground != nil) {
        [_pickerViewBackground removeFromSuperview];
        _pickerViewBackground = nil;
        return;
    }

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

- (void)insertNewPersonWithType:(BOOL)physical {
    
    PersonEntity *personEntity = [PersonEntity new];
    [personEntity setManagedObjectContext:_share.managedObjectContext];
    Person *newPerson = [personEntity create];
    newPerson.personId = [[[NSUUID UUID] UUIDString] lowercaseString];
    newPerson.person = [NSNumber numberWithBool:physical];
    // Save person to temporary
    [newPerson setToTemporary];
    
    newPerson.owner = _share;
}

- (IBAction)save:(id)sender {
    if ([_share.managedObjectContext hasChanges]) {
        [_share.managedObjectContext save:nil];
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"message_saved", nil)];
    }
}

- (IBAction)cancel:(id)sender {
    if (![_share isSaved]) {
        [self.navigationController dismissViewControllerAnimated:NO completion:^{
            [_share.managedObjectContext deleteObject:_share];
        }];
    } else {
        if ([_share.managedObjectContext hasChanges] &&
            [_share.claim.statusCode isEqualToString:kClaimStatusCreated]) {
            [UIAlertView showWithTitle:NSLocalizedStringFromTable(@"title_save_dialog", @"Additional", nil) message:NSLocalizedStringFromTable(@"message_save_dialog", @"Additional", nil) style:UIAlertViewStyleDefault cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"action_save", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex == 1) {
                    [self.navigationController dismissViewControllerAnimated:NO completion:^{
                        [self save:nil];
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
}

- (IBAction)done:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)rollback {
    [_share.managedObjectContext rollback];
}

- (NSInteger)getFreeShare {
    double scale = 0.0;
    for (Share *share in _share.claim.shares) {
        if (share != _share)
            scale += ([share.nominator doubleValue] / [share.denominator doubleValue]);
    }
    return roundf((1.0 - scale) * 100.0);
}

#pragma UITextFieldDelegate methods

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *nominator = [numberFormatter numberFromString:textField.text];
    if ([nominator integerValue] > [self getFreeShare]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_no_available_shares", nil)];
        textField.text = [@([_share.nominator integerValue]) stringValue];
    } else {
        _share.nominator = nominator;
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

#pragma mark - UIPickerViewDelegate methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    _share.nominator = [NSNumber numberWithInteger:row+1];
    _shareLabel.text = [_pickerItems objectAtIndex:row];
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 100;
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [_pickerItems objectAtIndex:row];
}

#pragma mark UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    BOOL result = ![NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"] && ![NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellEditControl"];
    return result;
}

@end
