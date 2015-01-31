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

#import "OTSharesUpdateViewController.h"
#import "OTSelectionTabBarViewController.h"

@interface OTSharesUpdateViewController () <OTSelectionTabBarViewControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>

@property  NSInteger *selectedRow;
@property BOOL tapped;

@end

@implementation OTSharesUpdateViewController

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
     NSMutableArray *items = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 100; i++)
    {
        [items addObject:[@(i) stringValue]];
    }
    
    [self configureGestureRecognizer];
    
    _tableView.tableFooterView = [UIView new];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_tableView reloadData];
}

- (void)configureGestureRecognizer {
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] init];
    gestureRecognizer.delegate = self;
    [_tableView addGestureRecognizer:gestureRecognizer];
    gestureRecognizer.cancelsTouchesInView = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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
    return @"ShareCache";
}

- (NSArray *)sortKeys {
    return @[@"denominator"];
}

- (NSString *)entityName {
    return @"Share";
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
    [super configureCell:cell forTableView:tableView atIndexPath:indexPath];

    cell.tintColor = [UIColor otDarkBlue];
    
    Share *share;

    if (_filteredObjects == nil)
        share = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        share = [_filteredObjects objectAtIndex:indexPath.row];
//    
//    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 64, 32)];
//    [container setUserInteractionEnabled:YES];
//
//    ///
//    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 64, 32)];
//    textField.text = [@([share.nominator integerValue]) stringValue];
//    textField.delegate = self;
//    CALayer *bottomBorder = [CALayer layer];
//    bottomBorder.borderColor = [UIColor otDarkBlue].CGColor;
//    bottomBorder.borderWidth = 1;
//    bottomBorder.frame = CGRectMake(0, textField.frame.size.height-1, textField.frame.size.width, 1);
//    [textField.layer addSublayer:bottomBorder];
//    UIImageView *comboView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"combo"]];
//    textField.rightView = comboView;
//    textField.rightViewMode = UITextFieldViewModeAlways;
//    textField.font = [UIFont systemFontOfSize:15];
//    textField.textAlignment = NSTextAlignmentRight;
//    textField.tag = indexPath.row;
//    [container addSubview:textField];
//    
//    //
//    UIButton *button = [[UIButton alloc] initWithFrame:textField.frame];
//    if (_claim.getViewType != OTViewTypeView) {
//        [button addTarget:self action:@selector(checkButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
//    }
//    [container addSubview:button];
//    //
//    cell.accessoryView = container;
    
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text = [NSString stringWithFormat:@"Share %tu : %tu/%tu", indexPath.row + 1, [share.nominator integerValue], [share.denominator integerValue]];
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\nOwners : %tu", share.shareId, share.owners.count];
}

- (void)checkButtonTapped:(id)sender event:(id)event{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:_tableView];
    NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint: currentTouchPosition];
    if (indexPath != nil){
        [self tableView:_tableView accessoryButtonTappedForRowWithIndexPath: indexPath];
    }
}

#pragma Bar Buttons Action

- (IBAction)addShare:(id)sender {
    NSInteger freeShare = [self getFreeShare];
    if (freeShare <= 0) {
        //If number of owner
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_no_available_shares", nil)];
   } else {
       ShareEntity *shareEntity = [ShareEntity new];
       [shareEntity setManagedObjectContext:_claim.managedObjectContext];
       Share *share = [shareEntity create];
       share.shareId = [[[NSUUID UUID] UUIDString] lowercaseString];
       share.denominator = [NSNumber numberWithInteger:100];
       share.nominator = [NSNumber numberWithInteger:[self getFreeShare]];
       share.claim = _claim;
       [share setToTemporary];
       
       [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:OTShareViewDetail] forKey:@"OTSelectionAction"];
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
    for (Share *share in _claim.shares) {
        scale += ([share.nominator doubleValue] / [share.denominator doubleValue]);
    }
    return roundf((1.0 - scale) * 100.0);
}

#pragma UITableViewDelegate methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
//    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    cell.tintColor = [UIColor otDarkBlue];
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
  
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    Share *share;
    share = [_fetchedResultsController objectAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UITextField *textField;
    for (id view in cell.accessoryView.subviews) {
        if ([view isKindOfClass:[UITextField class]]) {
            textField = view;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Share *share;
    share = [_fetchedResultsController objectAtIndexPath:indexPath];
    [share setToTemporary];

    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:OTShareViewDetail] forKey:@"OTSelectionAction"];
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return !_claim.getViewType == OTViewTypeView;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Share *share = [_fetchedResultsController objectAtIndexPath:indexPath];
        [self.managedObjectContext deleteObject:share];
        [self.managedObjectContext save:nil];
    }
}

#pragma UITextFieldDelegate methods

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    NSInteger tag = textField.tag;
    NSArray *shares = [_claim.shares allObjects];
    Share *share = shares[tag];

    double scale = 0.0;
    for (Share *sh in _claim.shares) {
        if (sh != share)
            scale += ([sh.nominator doubleValue] / [sh.denominator doubleValue]);
    }
    NSInteger freeAvaiable = roundf((1.0 - scale) * 100.0);
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *nominator = [numberFormatter numberFromString:textField.text];
    
    if ([nominator integerValue] > freeAvaiable) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_no_available_shares", nil)];
        textField.text = [@([share.nominator integerValue]) stringValue];
    } else {
        share.nominator = nominator;
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return NO;
}

@end
