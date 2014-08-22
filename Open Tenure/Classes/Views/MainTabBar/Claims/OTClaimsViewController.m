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

#import "OTClaimsViewController.h"
#import "OTClaimTabBarController.h"

@interface OTClaimsViewController ()

@property (nonatomic, strong) NSString *rootViewClassName;

@end

@implementation OTClaimsViewController

#pragma View

- (void)viewDidLoad {
    [super viewDidLoad];
    _searchBar.placeholder = NSLocalizedString(@"action_search", @"Search");
    _searchBar.placeholder = [[_searchBar.placeholder stringByAppendingString:@" "] stringByAppendingString:NSLocalizedString(@"title_claims", @"Claims")];
    
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
    return @"statusCode";
}

- (NSString *)mainTableCache {
    return @"ClaimCache";
}

- (NSArray *)sortKeys {
    return @[@"statusCode", @"claimName"];
}

- (NSString *)entityName {
    return @"Claim";
}

- (BOOL)showIndexes {
    return YES;
}

- (NSUInteger)fetchBatchSize {
    return 30;
}

- (NSPredicate *)frcPredicate {
    if ([_rootViewClassName isEqualToString:@"OTSelectionTabBarViewController"]) {
        // for claim select challenged
        return [NSPredicate predicateWithFormat:@"(statusCode = 'moderated') OR (statusCode = 'unmoderated') OR (statusCode = 'reviewed')"];
    }
    return nil;
}

- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope {
    if ([_rootViewClassName isEqualToString:@"OTSelectionTabBarViewController"]) {
        // for claim select person
        return [NSPredicate predicateWithFormat:@"(claimName CONTAINS[cd] %@) AND ((statusCode = 'moderated') OR (statusCode = 'unmoderated') OR (statusCode = 'reviewed'))", searchText];
    } else {
        // Default
        return [NSPredicate predicateWithFormat:@"(claimName CONTAINS[cd] %@)", searchText];
    }
}

- (NSUInteger)noOfLettersInSearch {
    return 1;
}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    [super configureCell:cell forTableView:tableView atIndexPath:indexPath];
    Claim *object;
    
    if (_filteredObjects == nil)
        object = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        object = [_filteredObjects objectAtIndex:indexPath.row];
    
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"claim_status_%@", object.statusCode]];
    cell.textLabel.text = [NSString stringWithFormat:@"%@, By: %@", object.claimName, [object.person fullNameType:OTFullNameTypeDefault]];
    cell.detailTextLabel.text = object.notes;
}

#pragma Bar Buttons Action

- (IBAction)showMenu:(id)sender {
    
}

- (IBAction)cancel:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table View

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Claim *claim;
    
    if (_filteredObjects == nil)
        claim = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        claim = [_filteredObjects objectAtIndex:indexPath.row];
    
    if ([_rootViewClassName isEqualToString:@"OTSelectionTabBarViewController"]) {
        [_delegate claimSelection:self didSelectClaim:claim];
    } else {
        [claim setToTemporary];
        
        UINavigationController *nav = [[self storyboard] instantiateViewControllerWithIdentifier:@"ClaimTabBar"];
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Claim *claim;
    
    if (_filteredObjects == nil)
        claim = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        claim = [_filteredObjects objectAtIndex:indexPath.row];
    
//    if (claim can edit) {
//        return YES;
//    }
    
    return YES; // or NO
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;
    
    Claim *claim;
    
    if (_filteredObjects == nil)
        claim = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        claim = [_filteredObjects objectAtIndex:indexPath.row];
    
//    // Only allow editing claim.
//    if (?) {
//        style = UITableViewCellEditingStyleDelete;
//    }
    style = UITableViewCellEditingStyleDelete;
    return style;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Claim *claim;
    
    if (_filteredObjects == nil)
        claim = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        claim = [_filteredObjects objectAtIndex:indexPath.row];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.managedObjectContext deleteObject:claim];
        [self.managedObjectContext save:nil];
    }
}

#pragma Bar Buttons Action

- (IBAction)addClaim:(id)sender {
    NSManagedObjectContext *context = [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] temporaryContext];
    ClaimEntity *claimEntity = [ClaimEntity new];
    [claimEntity setManagedObjectContext:context];
    Claim *claim = [claimEntity create];
    
    [claim setToTemporary];
    UINavigationController *nav = [[self storyboard] instantiateViewControllerWithIdentifier:@"ClaimTabBar"];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (IBAction)login:(id)sender {

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"title_activity_login_activity_test", @"Log in") message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel")  otherButtonTitles:NSLocalizedString(@"action_sign_in_short", @"Log in"), nil];
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [alertView show];
}

- (IBAction)logout:(id)sender {
    [SVProgressHUD show];
    [CommunityServerAPI logoutWithCompletionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"message_logout_ok", @"You have succefully Logout")];
                // Clear session
                NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                for (NSHTTPCookie *cookie in [cookieStorage cookies])
                    [cookieStorage deleteCookie:cookie];
                
                [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] setAuthenticated:NO];
                [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutSuccessNotificationName object:self userInfo:nil];
            } else {
                NSString *errorString = NSLocalizedString(@"error_generic_conection", @"An error has occurred during connection");
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

- (void)submitClaim:(id)claim {
    
    if (![OTAppDelegate authenticated]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_login_before", @"Do login before")];
        return;
    }
    // TODO: Submit claim
    
}

#pragma UIAlertView Delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"login_progress_signing_in", @"Loggin in...")];
        [CommunityServerAPI loginWithUsername:[[alertView textFieldAtIndex:0] text] andPassword:[[alertView textFieldAtIndex:1] text] completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
            if (error != nil) {
                [OT handleError:error];
            } else {
                if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"message_login_ok", @"You have succefully Login")];
                    
                    // Store session
                    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:[NSHTTPCookie cookieWithProperties:[httpResponse allHeaderFields]]];
                    
                    [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] setAuthenticated:YES];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kLoginSuccessNotificationName object:self userInfo:nil];
                } else {
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(@"error_generic_conection", @"An error has occurred during connection")};
                    [OT handleError:[NSError errorWithDomain:@"HTTP"
                                                        code:[httpResponse statusCode]
                                                    userInfo:userInfo]];
                }
            }
        }];
    }
}

@end
