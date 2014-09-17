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
#import "SaveClaimTask.h"
#import "UploadChunkTask.h"
#import "SaveAttachmentTask.h"

@interface OTClaimsViewController () <UploadChunkTaskDelegate, SaveClaimTaskDelegate, SaveAttachmentTaskDelegate, UploadChunkTaskDelegate>

@property (nonatomic, strong) NSString *rootViewClassName;

@property (nonatomic, assign, getter = isUploading) BOOL uploading;
@property (nonatomic, assign) NSInteger totalChunksTobeUploaded;
@property (nonatomic, assign) NSInteger chunksUploadedSuccessfully;
@property (nonatomic, assign) NSInteger totalAttachmentsTobeUploaded;

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
    _managedObjectContext = dataContext;
    return _managedObjectContext;
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
    
    cell.tintColor = [UIColor otDarkBlue];
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    
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

#pragma recursively iterate the sub views
// Hàm này đệ quy dùng để tìm subview theo class, không biết nên để ở đâu cho tiện

- (UIView *)getSubviewByClass:(Class)className ofView:(UIView *)view {
    
    // Get the subviews of the view
    NSArray *subviews = [view subviews];
    
    // Return if there are no subviews
    if ([subviews count] == 0) return nil;
    
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:className])
            return subview;
        if (subview.subviews.count > 0)
            [self getSubviewByClass:className ofView:subview];
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    Claim *claim;
    
    if (_filteredObjects == nil)
        claim = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        claim = [_filteredObjects objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    UIView *accessoryView = cell.accessoryView;
    if (accessoryView == nil) {
        UIView *cellContentView = nil;
        
        for (UIView *accView in [cell subviews]) {
            accessoryView = [self getSubviewByClass:[UIButton class] ofView:accView];
        }
        // if the UIButton doesn't exists, find cell contet view (UITableViewCellContentView)
        if (accessoryView == nil) {
            accessoryView   = cellContentView;
        }
        // if the cell contet view doesn't exists, use cell view
        if (accessoryView == nil) {
            accessoryView   = cell; 
        }
    }
    
    [UIActionSheet showFromRect:accessoryView.frame inView:cell.contentView animated:YES withTitle:@"Action" cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@[@"Submit claim", @"Action 2", @"Action 3"] tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [self submitClaim:claim];
        }
    }];
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
    ClaimEntity *claimEntity = [ClaimEntity new];
    [claimEntity setManagedObjectContext:temporaryContext];
    Claim *claim = [claimEntity create];
    
    [claim setToTemporary];
    UINavigationController *nav = [[self storyboard] instantiateViewControllerWithIdentifier:@"ClaimTabBar"];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (IBAction)login:(id)sender {
    [OT login];
}

- (IBAction)logout:(id)sender {
    [OT login];
}

- (IBAction)submitClaim:(Claim *)claim {
    
    if (![OTAppDelegate authenticated]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_login_before", @"Do login before")];
        return;
    }
    
    if (!claim.canBeUploaded) return;

    ALog(@"Submitting claim");
    [SVProgressHUD showWithStatus:NSLocalizedString(@"message_uploading", nil)];

    claim.recorderName = [OTAppDelegate userName];
    [claim.managedObjectContext save:nil];
    
    [self saveClaim:claim];
}

// Save claim to server
- (void)saveClaim:(Claim *)claim {
    SaveClaimTask *saveClaimTask = [[SaveClaimTask alloc] initWithClaim:claim viewHolder:self];
    saveClaimTask.delegate = self;
    NSOperationQueue *saveClaimQueue = [NSOperationQueue new];
    [saveClaimQueue addOperation:saveClaimTask];
}

- (void)saveAttachment:(Attachment *)attachment {
    SaveAttachmentTask *saveAttachmentTask = [[SaveAttachmentTask alloc] initWithAttachment:attachment viewHolder:self];
    saveAttachmentTask.delegate = self;
    NSOperationQueue *saveAttachmentTaskQueue = [NSOperationQueue new];
    [saveAttachmentTaskQueue addOperation:saveAttachmentTask];
}

#pragma UploadChunkTaskDelegate method
// Kết thúc thành công một chunk
- (void)uploadChunk:(UploadChunkTask *)controller didFinishChunkCount:(NSInteger)chunkCount {
    if (_totalChunksTobeUploaded == 0) return;
    _chunksUploadedSuccessfully++;
    double progress = (double)_chunksUploadedSuccessfully / (double)_totalChunksTobeUploaded;
    ALog(@"Upload progress: %f", progress);
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showProgress:progress status:NSLocalizedString(@"message_uploading", nil)];
    });
}

#pragma SaveClaimTaskDelegate method
// Tổng số chunks của attachments
- (void)saveClaimTask:(SaveClaimTask *)controller didSaveWithTotalChunksTobeUploaded:(NSInteger)totalChunks totalAttachments:(NSInteger)totalAttachments {
    _totalChunksTobeUploaded = totalChunks;
    _totalAttachmentsTobeUploaded = totalAttachments;
    ALog(@"Total chunks: %tu", totalChunks);
}

#pragma UploadChunkTaskDelegate method
// Kết thúc việc upload một attachment thành công
- (void)uploadChunk:(UploadChunkTask *)controller didFinishWithSuccess:(BOOL)success {
    Attachment *attachment = controller.attachment;
    if (success) {
        ALog(@"Kết quả trả về 454 là đã tồn tại attachment, đặt lại thuộc tính cho attachment là uploaded?");
        [self performSelector:@selector(saveAttachment:) withObject:attachment afterDelay:0.2];
    }
}

#pragma SaveAttachmentTaskDelegate method 

- (void)saveAttachment:(SaveAttachmentTask *)controller didSaveSuccess:(BOOL)success {
    if (success) {
        _totalAttachmentsTobeUploaded--;
        if (_totalAttachmentsTobeUploaded == 0) {
            // Nếu đã upload hết chunks
            if (_chunksUploadedSuccessfully == _totalChunksTobeUploaded) {
                _chunksUploadedSuccessfully = 0;
                _totalChunksTobeUploaded = 0;
                _totalAttachmentsTobeUploaded = 0;
                // Sau khi upload thành công các attachments, chờ 0.3 giây để server làm việc :D rồi saveClaim lần nữa
                [self performSelector:@selector(submitClaim:) withObject:controller.attachment.claim afterDelay:0.3];
            }
        }
    }
}

@end
