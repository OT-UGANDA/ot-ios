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

#import "CDRTranslucentSideBar.h"
#import "OTSideBarItems.h"


@interface OTClaimsViewController () <UploadChunkTaskDelegate, SaveClaimTaskDelegate, SaveAttachmentTaskDelegate, UploadChunkTaskDelegate> {
       BOOL multipleShowcase;
    BOOL customShowcases;
    NSInteger currentShowcaseIndex;
}

@property (nonatomic, strong) CDRTranslucentSideBar *sideBarMenu;
@property (nonatomic, strong) OTSideBarItems *sideBarItems;

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

    _tableView.tableFooterView = [UIView new];
    _tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);

    [self configureSideBarMenu];
    
    
    
    _searchBar.placeholder = NSLocalizedString(@"hint_type_to_filter", @"Search");
    
    _rootViewClassName = NSStringFromClass([[[self.navigationController viewControllers] lastObject] class]);
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.sideBarMenu dismiss];
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - OTShowcase & OTShowcaseDelegate methods



#pragma mark - OTShowcaseDelegate methods




- (void)configureSideBarMenu {
    _sideBarItems = [[OTSideBarItems alloc] initWithStyle:UITableViewStylePlain];
    NSArray *cells = @[@{@"title" : NSLocalizedString(@"action_settings", nil)},
                       @{@"title" : NSLocalizedStringFromTable(@"action_showcase", @"Showcase", nil)}];
    
    [_sideBarItems setCells:cells];
    __strong typeof(self) self_ = self;
    _sideBarItems.itemAction = ^void(NSInteger section, NSInteger itemIndex) {
        switch (itemIndex) {
            case 0:
                [self_ showSettings:nil];
                break;
                
            case 1:
                [[NSNotificationCenter defaultCenter] postNotificationName:kSetMainTabBarIndexNotificationName object:[NSNumber numberWithInteger:0] userInfo:@{@"action":@"showcase"}];
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
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    Claim *object;
    if (_filteredObjects == nil)
        object = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        object = [_filteredObjects objectAtIndex:indexPath.row];
    cell.tintColor = [UIColor otDarkBlue];
    
    // Tạo một UIView chứa Claimant image và Action button
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 110, 44)];
    [container setUserInteractionEnabled:YES];
    
    // Tạo claimant image
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    NSString *imageFile = [FileSystemUtilities getClaimantImagePath:object.person.personId];
    UIImage *personPicture = [UIImage imageWithContentsOfFile:imageFile];
    if (personPicture == nil) personPicture = [UIImage imageNamed:@"ic_person_picture"];
    imageView.image = personPicture;
    imageView.backgroundColor = [UIColor whiteColor];
    
    [container addSubview:imageView];

    UIButton *actionBtn = [UIButton  buttonWithType:UIButtonTypeCustom];
    actionBtn.frame = CGRectMake(60, 0, 50, 40);
    [actionBtn setBackgroundImage:[UIImage imageNamed:@"ic_submit_big"]
                         forState:UIControlStateNormal];
    actionBtn.backgroundColor = [UIColor clearColor];
    
    actionBtn.layer.borderColor = [UIColor otDarkBlue].CGColor;
    actionBtn.layer.borderWidth = 0.2;
    actionBtn.layer.cornerRadius = 5;
    
    actionBtn.tag = indexPath.row;
    [actionBtn addTarget:self action:@selector(checkButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
    
    [container addSubview:actionBtn];
    
    cell.accessoryView = container;
    
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;
    
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"claim_status_%@", object.statusCode]];
   // cell.textLabel.text = [NSString stringWithFormat:@"%@, By: %@", object.claimName, [object.person fullNameType:OTFullNameTypeDefault]];
    if([object.recorderName isEqualToString:@""] || (object.recorderName == nil) )
        cell.textLabel.text = [NSString stringWithFormat:@"%@, Created by:%@ ", object.claimName, [object.person fullNameType:OTFullNameTypeDefault]];
    
    else
        cell.textLabel.text = [NSString stringWithFormat:@"%@, Created by:%@, Uploaded by: %@", object.claimName, [object.person fullNameType:OTFullNameTypeDefault],object.recorderName];
    
    cell.detailTextLabel.text = object.notes;
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

- (IBAction)showMenu:(id)sender {
    if ([self.sideBarMenu hasShown])
        [self.sideBarMenu dismiss];
    else
        [self.sideBarMenu showInViewController:self];
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

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell != nil) {
        Claim *claim;
        
        if (_filteredObjects == nil)
            claim = [_fetchedResultsController objectAtIndexPath:indexPath];
        else
            claim = [_filteredObjects objectAtIndex:indexPath.row];
        CGRect frame = cell.accessoryView.frame;
        frame.origin.x += 60;
        [UIActionSheet showFromRect:frame inView:cell animated:YES withTitle:@"Claim Actions" cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@[@"Submit claim", @"Withdraw", @"Action 3"] tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                [self submitClaim:claim];
            } else if(buttonIndex == 1){
                [self withdrawClaim:claim];
            }
            
        }];
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
        [_filteredObjects removeObject:claim];
        if (_filteredObjects != nil)
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [claim setChallenged:nil]; // Fixed delete challeged claim
        [claim.managedObjectContext deleteObject:claim];
        NSError *error;
        if (![claim.managedObjectContext save:&error]) {
            ALog(@"Error: %@", error.description);
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

#pragma Bar Buttons Action

- (IBAction)addClaim:(id)sender {
    if (![OTSetting getInitialization]) {
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"message_app_not_yet_initialized", nil)];
        return;
    }

    ClaimEntity *claimEntity = [ClaimEntity new];
    [claimEntity setManagedObjectContext:temporaryContext];
    Claim *claim = [claimEntity create];
    
    FormPayloadEntity *formPayloadEntity = [FormPayloadEntity new];
    [formPayloadEntity setManagedObjectContext:temporaryContext];
    FormPayload *formPayload = [formPayloadEntity createObject];

    FormTemplateEntity *formTemplateEntity = [FormTemplateEntity new];
    [formTemplateEntity setManagedObjectContext:temporaryContext];
    FormTemplate *formTemplate = [formTemplateEntity getDefaultTemplate];
    formPayload.formTemplate = formTemplate;
    
    SectionPayloadEntity *sectionPayloadEntity = [SectionPayloadEntity new];
    [sectionPayloadEntity setManagedObjectContext:temporaryContext];
    SectionElementPayloadEntity *sectionElementPayloadEntity = [SectionElementPayloadEntity new];
    [sectionElementPayloadEntity setManagedObjectContext:temporaryContext];
    FieldPayloadEntity *fieldPayloadEntity = [FieldPayloadEntity new];
    [fieldPayloadEntity setManagedObjectContext:temporaryContext];
    // Tạo danh sách các sectionPayload (các tab) dựa trên sectiontemplate của formtemplate
    for (SectionTemplate *sectionTemplate in formTemplate.sectionTemplateList) {
        SectionPayload *sectionPayload = [sectionPayloadEntity createObject];
        sectionPayload.formPayload = formPayload;
        sectionPayload.sectionTemplate = sectionTemplate;
        // Tạo sectionElementPayload (nếu maxOccurrences = 1).
        // Nếu maxOccurrences > 1 sẽ tạo trong class OTDynamicFormViewController
        if ([sectionTemplate.maxOccurrences integerValue] == 1) {
            SectionElementPayload *sectionElementPayload = [sectionElementPayloadEntity createObject];
            sectionElementPayload.sectionPayload = sectionPayload;
            // Tạo các fieldPayload theo danh sách fieldTemplate của sectionTemplate
            for (FieldTemplate *fieldTemplate in sectionTemplate.fieldTemplateList) {
                FieldPayload *fieldPayload = [fieldPayloadEntity createObject];
                if ([fieldTemplate.fieldType isEqualToString:@"BOOL"]) {
                    fieldPayload.fieldValueType = @"BOOL";
                    fieldPayload.booleanPayload = [NSNumber numberWithBool:NO];
                } else if ([fieldTemplate.fieldType isEqualToString:@"DECIMAL"]) {
                    fieldPayload.fieldValueType = @"NUMBER";
                } else {
                    fieldPayload.fieldValueType = @"TEXT";
                    fieldPayload.stringPayload = @"";
                }
                fieldPayload.fieldTemplate = fieldTemplate;
                fieldPayload.sectionElementPayload = sectionElementPayload;
            }
        }
    }
    
    claim.dynamicForm = formPayload;
    
    [claim setToTemporary];
    UINavigationController *nav = [[self storyboard] instantiateViewControllerWithIdentifier:@"ClaimTabBar"];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (IBAction)login:(id)sender {
    if ([OTSetting getInitialization]) {
        [OT login];
    } else {
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"message_app_not_yet_initialized", nil)];
    }
}

- (IBAction)logout:(id)sender {
    [OT login];
}

- (IBAction)withdrawClaim:(Claim *)claim {
    if (![OTAppDelegate authenticated]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedStringFromTable(@"message_login_before", @"ActivityLogin", nil)];
        return;
    }
    
    [claim withDraw];

}

- (IBAction)submitClaim:(Claim *)claim {
    
//    NSError *error;
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:claim.dynamicForm.dictionary
//                                                       options:NSJSONWritingPrettyPrinted
//                                                         error:&error];
//    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    ALog(@"%@", jsonString);
    
    if (![OTAppDelegate authenticated]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedStringFromTable(@"message_login_before", @"ActivityLogin", nil)];
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

#pragma Actions
- (IBAction)showSettings:(id)sender {
    UINavigationController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingViewController"];
    settingViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:settingViewController animated:YES completion:nil];
}

@end
