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

#import "OTNewsViewController.h"

#import "CDRTranslucentSideBar.h"
#import "OTSideBarItems.h"
#import "OTShowcase.h"

@interface OTNewsViewController () {
    OTShowcase *showcase;
    BOOL multipleShowcase;
    NSInteger currentShowcaseIndex;
}

@property (nonatomic, strong) CDRTranslucentSideBar *sideBarMenu;
@property (nonatomic, strong) OTSideBarItems *sideBarItems;

@end

@implementation OTNewsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);

    [self configureSideBarMenu];
    
    _searchBar.placeholder = NSLocalizedString(@"hint_type_to_filter", @"Search");
    
    if (self.cells == nil) {
        NSURL *csUrl = [[NSURL alloc] initWithString:[OTSetting getCommunityServerURL]];
        NSString *homePath = [[csUrl URLByAppendingPathComponent:@"home"] absoluteString];
        self.cells = @[@{@"title" : csUrl.absoluteString,
                         @"subtitle" : @"OpenTenure Community: visit the OpenTenure Community web site and tell us what you think."},
                       @{@"title" : homePath,
                         @"subtitle" : @"FLOSS SOLA: look at the latest news on FLOSS SOLA web site."}
                       ];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [showcase setShowing:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.sideBarMenu dismiss];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope {
    return [NSPredicate predicateWithFormat:@"(title contains[cd] %@) OR (subtitle contains[cd] %@)", searchText, searchText];
}

#pragma mark - OTShowcase & OTShowcaseDelegate methods
- (void)configureShowcase {
    showcase = [[OTShowcase alloc] init];
    showcase.delegate = self;
    [showcase setBackgroundColor:[UIColor otDarkBlue]];
    [showcase setTitleColor:[UIColor greenColor]];
    [showcase setDetailsColor:[UIColor whiteColor]];
    [showcase setHighlightColor:[UIColor whiteColor]];
    [showcase setContainerView:[[[[[UIApplication sharedApplication] delegate] window] subviews] objectAtIndex:0]];
    __strong typeof(showcase) showcase_ = showcase;
    showcase.nextActionBlock = ^(void){
        [showcase_ setShowing:YES];
        [showcase_ showcaseTapped];
    };
    showcase.skipActionBlock = ^(void) {
        [showcase_ setShowing:NO];
        [showcase_ showcaseTapped];
    };
}

- (IBAction)defaultShowcase:(id)sender {
    [self configureShowcase];
    if (sender != nil) {
        multipleShowcase = ![[sender objectForKey:@"action"] isEqualToString:@"close"];
    } else {
        multipleShowcase = YES;
    }
    if (_showcaseTargetList.count == 0 || [showcase isShowing]) return;
    NSDictionary *item = [_showcaseTargetList objectAtIndex:0];
    [showcase setIType:[[item objectForKey:@"type"] intValue]];
    [showcase setupShowcaseForTarget:[item objectForKey:@"target"]  title:[item objectForKey:@"title"] details:[item objectForKey:@"detail"]];
    [showcase show];
}

#pragma mark - OTShowcaseDelegate methods
- (void)OTShowcaseShown{
    if (currentShowcaseIndex == _showcaseTargetList.count - 1 && !multipleShowcase) {
        NSString *title = NSLocalizedStringFromTable(@"close", @"Showcase", nil);
        [showcase.nextButton setTitle:title forState:UIControlStateNormal];
        [showcase.nextButton setTitle:title forState:UIControlStateHighlighted];
        
        [showcase.skipButton removeFromSuperview];
    }
}

- (void)OTShowcaseDismissed {
    currentShowcaseIndex++;
    if (![showcase isShowing]) {
        currentShowcaseIndex = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:kSetMainTabBarIndexNotificationName object:[NSNumber numberWithInteger:0] userInfo:nil];
    } else {
        if (currentShowcaseIndex < _showcaseTargetList.count) {
            NSDictionary *item = [_showcaseTargetList objectAtIndex:currentShowcaseIndex];
            [showcase setIType:[[item objectForKey:@"type"] intValue]];
            [showcase setupShowcaseForTarget:[item objectForKey:@"target"]  title:[item objectForKey:@"title"] details:[item objectForKey:@"detail"]];
            [showcase show];
        } else {
            currentShowcaseIndex = 0;
            [showcase setShowing:NO];
            if (multipleShowcase)
                [[NSNotificationCenter defaultCenter] postNotificationName:kSetMainTabBarIndexNotificationName object:[NSNumber numberWithInteger:1] userInfo:@{@"action":@"showcase"}];
        }
    }
}

- (void)configureSideBarMenu {
    _sideBarItems = [[OTSideBarItems alloc] initWithStyle:UITableViewStylePlain];
    NSArray *cells = @[@{@"title" : NSLocalizedString(@"action_settings", nil)},
                       @{@"title" : NSLocalizedStringFromTable(@"action_showcase", @"Showcase", nil)},
                       @{@"title" : NSLocalizedString(@"action_export_log", nil)}];
    
    [_sideBarItems setCells:cells];
    __strong typeof(self) self_ = self;
    _sideBarItems.itemAction = ^void(NSInteger section, NSInteger itemIndex) {
        switch (itemIndex) {
            case 0:
                [self_ showSettings:nil];
                break;
                
            case 1:
                [self_ defaultShowcase:nil];
                break;
                
            case 2:
                [OTSetting exportLog];
                break;
        }
        [self_.sideBarMenu dismiss];
    };
    
    self.sideBarMenu = [[CDRTranslucentSideBar alloc] initWithDirectionFromRight:YES];
    [self.sideBarMenu setTranslucent:YES];
    self.sideBarMenu.translucentStyle = UIBarStyleDefault;
    self.sideBarMenu.tag = 1;
    [self.sideBarMenu setSideBarWidth:260];
    [self.sideBarMenu setContentViewInSideBar:_sideBarItems.tableView];
}

#pragma Bar Buttons Action

- (IBAction)showMenu:(UIBarButtonItem *)sender {
    if ([self.sideBarMenu hasShown])
        [self.sideBarMenu dismiss];
    else
        [self.sideBarMenu showInViewController:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_filteredObjects == nil)
        return _cells.count;
    else
        return _filteredObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSDictionary *object;
    if (_filteredObjects == nil) {
        object = [_cells objectAtIndex:indexPath.row];
    } else {
        object = [_filteredObjects objectAtIndex:indexPath.row];
    }
    cell.textLabel.text = [object objectForKey:@"title"];
    cell.detailTextLabel.text = [object objectForKey:@"subtitle"];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UIView *selectionColor = [[UIView alloc] init];
    selectionColor.backgroundColor = [UIColor otGreen];
    cell.selectedBackgroundView = selectionColor;
    cell.textLabel.highlightedTextColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    
    cell.detailTextLabel.font = [UIFont systemFontOfSize:16];
    cell.detailTextLabel.highlightedTextColor = [UIColor whiteColor];
    cell.detailTextLabel.numberOfLines = 0;
    cell.backgroundColor = [UIColor otLightGreen];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (_filteredObjects == nil) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cell.textLabel.text]];
    } else {
        NSDictionary *object = [_filteredObjects objectAtIndex:indexPath.row];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[object objectForKey:@"title"]]];
    }
}

#pragma filter
- (void)filterContentForSearchText:(NSString *)searchText scope:(NSInteger)scope {
    if ([searchText length] != 0) {
        _filteredObjects = [_cells filteredArrayUsingPredicate:[self searchPredicateWithSearchText:searchText scope:0]];
    } else {
        _filteredObjects = nil;
    }
    [self.tableView reloadData];
}

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
    [self.tableView reloadData];
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
    _filteredObjects = nil;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text]
                               scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
    
    return YES;
}

#pragma Actions
- (IBAction)showSettings:(id)sender {
    UINavigationController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingViewController"];
    settingViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:settingViewController animated:YES completion:nil];
}

@end
