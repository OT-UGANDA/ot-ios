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

#import "OTMapBookmarkViewController.h"

@interface OTMapBookmarkViewController ()

@end

@implementation OTMapBookmarkViewController

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

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableView.tableFooterView = [UIView new];
    _tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
    
    _searchBar.placeholder = NSLocalizedString(@"hint_type_to_filter", @"Search");

    [self loadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//#pragma mark - OTShowcase & OTShowcaseDelegate methods
//- (void)configureShowcase {
//    showcase = [[OTShowcase alloc] init];
//    showcase.delegate = self;
//    [showcase setBackgroundColor:[UIColor otDarkBlue]];
//    [showcase setTitleColor:[UIColor greenColor]];
//    [showcase setDetailsColor:[UIColor whiteColor]];
//    [showcase setHighlightColor:[UIColor whiteColor]];
//    [showcase setContainerView:self.navigationController.navigationBar.superview];
//    __strong typeof(showcase) showcase_ = showcase;
//    showcase.nextActionBlock = ^(void){
//        [showcase_ showcaseTapped];
//    };
//    showcase.skipActionBlock = ^(void) {
//        [showcase_ setShowing:NO];
//        [showcase_ showcaseTapped];
//    };
//}
//
//- (IBAction)defaultShowcase:(id)sender {
//    [self configureShowcase];
//    if (_showcaseTargetList.count == 0 || [showcase isShowing]) return;
//    NSDictionary *item = [_showcaseTargetList objectAtIndex:0];
//    [showcase setIType:[[item objectForKey:@"type"] intValue]];
//    [showcase setupShowcaseForTarget:[item objectForKey:@"target"]  title:[item objectForKey:@"title"] details:[item objectForKey:@"detail"]];
//    [showcase show];
//}
//
//#pragma mark - OTShowcaseDelegate methods
//- (void)OTShowcaseShown{}
//
//- (void)OTShowcaseDismissed {
//    currentShowcaseIndex++;
//    if (![showcase isShowing]) {
//        currentShowcaseIndex = 0;
//        [[NSNotificationCenter defaultCenter] postNotificationName:kSetClaimTabBarIndexNotificationName object:[NSNumber numberWithInteger:0] userInfo:nil];
//    } else {
//        if (currentShowcaseIndex < _showcaseTargetList.count) {
//            NSDictionary *item = [_showcaseTargetList objectAtIndex:currentShowcaseIndex];
//            [showcase setIType:[[item objectForKey:@"type"] intValue]];
//            [showcase setupShowcaseForTarget:[item objectForKey:@"target"]  title:[item objectForKey:@"title"] details:[item objectForKey:@"detail"]];
//            [showcase show];
//        } else {
//            currentShowcaseIndex = 0;
//            [showcase setShowing:NO];
//            [[NSNotificationCenter defaultCenter] postNotificationName:kSetClaimTabBarIndexNotificationName object:[NSNumber numberWithInteger:5] userInfo:@{@"action":@"showcase"}];
//        }
//    }
//}

- (IBAction)cancel:(id)sender {
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

- (NSString *)mainTableSectionNameKeyPath {
    return nil;
}

- (NSString *)mainTableCache {
    return @"MapBookmarkCache";
}

- (NSArray *)sortKeys {
    return @[@"name"];
}

- (NSString *)entityName {
    return @"MapBookmark";
}

- (BOOL)showIndexes {
    return NO;
}

- (NSUInteger)fetchBatchSize {
    return 30;
}

- (NSPredicate *)frcPredicate {
    return nil;
}

- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope {
    return [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@)", searchText];
}

- (NSUInteger)noOfLettersInSearch {
    return 1;
}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    [super configureCell:cell forTableView:tableView atIndexPath:indexPath];
    MapBookmark *object;
    if (_filteredObjects == nil)
        object = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        object = [_filteredObjects objectAtIndex:indexPath.row];

    //cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"claim_status_%@", object.statusCode]];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", object.mapBookmarkId];
    cell.detailTextLabel.text = object.name;
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
    MapBookmark *object;
    
    if (_filteredObjects == nil)
        object = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        object = [_filteredObjects objectAtIndex:indexPath.row];
    [_delegate mapBookmark:self didSelectMapBookmark:object];
    [self cancel:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    MapBookmark *object;
    
    if (_filteredObjects == nil)
        object = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        object = [_filteredObjects objectAtIndex:indexPath.row];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (_filteredObjects != nil) {
            [_filteredObjects removeObject:object];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        NSString *mapBookmarkId = object.mapBookmarkId;
        [object.managedObjectContext deleteObject:object];
        NSError *error;
        if (![object.managedObjectContext save:&error]) {
            ALog(@"Error: %@", error.description);
        } else {
            [_delegate mapBookmark:self didDeleteMapBookmarkId:mapBookmarkId];
        }
    }
}

@end
