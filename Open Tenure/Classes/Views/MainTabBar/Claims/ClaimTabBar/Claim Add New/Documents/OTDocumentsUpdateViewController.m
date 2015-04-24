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

#import "OTDocumentsUpdateViewController.h"
#import "OTFileChooserViewController.h"
#import <QuickLook/QuickLook.h>
#import "OTShowcase.h"

@interface OTDocumentsUpdateViewController () <OTFileChooserViewControllerDelegate, UITextFieldDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource, UIDocumentInteractionControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPickerViewDelegate> {
    NSURL *documentURL;
    
    OTShowcase *showcase;
    BOOL multipleShowcase;
    NSInteger currentShowcaseIndex;
}

@property (nonatomic, strong) UIPickerView *pickerView;

@property (nonatomic, strong) NSMutableDictionary *dictionary;
@property (nonatomic, strong) NSArray *docTypeCollection;
@property (nonatomic, strong) NSMutableArray *docTypeDisplayValue;
@property (nonatomic, strong) UITextField *textField;

@end

@implementation OTDocumentsUpdateViewController

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
    
    DocumentTypeEntity *docTypeEntity = [DocumentTypeEntity new];
    [docTypeEntity setManagedObjectContext:_claim.managedObjectContext];
    _docTypeCollection = [docTypeEntity getCollection];
    
    _docTypeDisplayValue = [NSMutableArray array];
    for (DocumentType *object in _docTypeCollection) {
        [_docTypeDisplayValue addObject:object.displayValue];
    }
    _pickerView = [[UIPickerView alloc] init];
    _pickerView.delegate = self;
    _pickerView.showsSelectionIndicator = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - OTShowcase & OTShowcaseDelegate methods
- (void)configureShowcase {
    showcase = [[OTShowcase alloc] init];
    showcase.delegate = self;
    [showcase setBackgroundColor:[UIColor otDarkBlue]];
    [showcase setTitleColor:[UIColor greenColor]];
    [showcase setDetailsColor:[UIColor whiteColor]];
    [showcase setHighlightColor:[UIColor whiteColor]];
    [showcase setContainerView:self.navigationController.navigationBar.superview];
    __strong typeof(showcase) showcase_ = showcase;
    showcase.nextActionBlock = ^(void){
        [showcase_ showcaseTapped];
    };
    showcase.skipActionBlock = ^(void) {
        [showcase_ setShowing:NO];
        [showcase_ showcaseTapped];
    };
}

- (IBAction)defaultShowcase:(id)sender {
    [self configureShowcase];
    if (_showcaseTargetList.count == 0 || [showcase isShowing]) return;
    NSDictionary *item = [_showcaseTargetList objectAtIndex:0];
    [showcase setIType:[[item objectForKey:@"type"] intValue]];
    [showcase setupShowcaseForTarget:[item objectForKey:@"target"]  title:[item objectForKey:@"title"] details:[item objectForKey:@"detail"]];
    [showcase show];
}

#pragma mark - OTShowcaseDelegate methods
- (void)OTShowcaseShown{}

- (void)OTShowcaseDismissed {
    currentShowcaseIndex++;
    if (![showcase isShowing]) {
        currentShowcaseIndex = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:kSetClaimTabBarIndexNotificationName object:[NSNumber numberWithInteger:0] userInfo:nil];
    } else {
        if (currentShowcaseIndex < _showcaseTargetList.count) {
            NSDictionary *item = [_showcaseTargetList objectAtIndex:currentShowcaseIndex];
            [showcase setIType:[[item objectForKey:@"type"] intValue]];
            [showcase setupShowcaseForTarget:[item objectForKey:@"target"]  title:[item objectForKey:@"title"] details:[item objectForKey:@"detail"]];
            [showcase show];
        } else {
            currentShowcaseIndex = 0;
            [showcase setShowing:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:kSetClaimTabBarIndexNotificationName object:[NSNumber numberWithInteger:3] userInfo:@{@"action":@"showcase"}];
        }
    }
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
    return @"AttachmentCache";
}

- (NSArray *)sortKeys {
    return @[@"documentDate"];
}

- (NSString *)entityName {
    return @"Attachment";
}

- (BOOL)showIndexes {
    return NO;
}

- (NSUInteger)fetchBatchSize {
    return 30;
}

- (NSPredicate *)frcPredicate {
//    return [NSPredicate predicateWithFormat:@"(claim == %@)", _claim];
    return [NSPredicate predicateWithFormat:@"(claim == %@) AND (typeCode.code <> %@)", _claim, @"personPhoto"];
}

- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope {
    return nil;
}

- (NSUInteger)noOfLettersInSearch {
    return 1;
}

- (void)configureCell:(UITableViewCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    
    Attachment *attachment;
    
    if (_filteredObjects == nil)
        attachment = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        attachment = [_filteredObjects objectAtIndex:indexPath.row];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text = [NSString stringWithFormat:@"%@\n%@", attachment.note, attachment.typeCode.displayValue];
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.text = attachment.mimeType;
}

#pragma Bar Buttons Action

- (IBAction)takePhotoDoc:(id)sender {
    [self showImagePickerAlert:sender];
}

- (IBAction)attachDoc:(id)sender {
    
    OTFileChooserViewController *fileChooser = [[OTFileChooserViewController alloc] initWithStyle:UITableViewStylePlain];
    fileChooser.delegate = self;
    [self.navigationController pushViewController:fileChooser animated:YES];
}

- (IBAction)done:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)fileChooserController:(OTFileChooserViewController *)controller didSelectFile:(NSString *)file uti:(NSString *)uti {
    
    unsigned long long size = [[[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil] fileSize];
    NSNumber *fileSize = [NSNumber numberWithUnsignedLongLong:size];
    NSData *fileData = [NSData dataWithContentsOfFile:file];
    NSString *md5 = [fileData md5];
    self.dictionary = [NSMutableDictionary dictionary];
    [_dictionary setValue:[[[OT dateFormatter] stringFromDate:[NSDate date]] substringToIndex:10] forKey:@"documentDate"];
    [_dictionary setValue:uti forKey:@"mimeType"];
    [_dictionary setValue:[file lastPathComponent] forKey:@"fileName"];
    [_dictionary setValue:[[file lastPathComponent] pathExtension] forKey:@"fileExtension"];
    [_dictionary setValue:[[[NSUUID UUID] UUIDString] lowercaseString] forKey:@"id"];
    [_dictionary setValue:fileSize forKey:@"size"];
    [_dictionary setValue:md5 forKey:@"md5"];
    [_dictionary setValue:kAttachmentStatusCreated forKey:@"status"];
    [_dictionary setValue:file forKey:@"filePath"];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"new_file", nil)
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"confirm", nil), nil];
    
    [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    // Alert style customization
    [[alertView textFieldAtIndex:1] setSecureTextEntry:NO];
    [[alertView textFieldAtIndex:1] setText:[_docTypeDisplayValue objectAtIndex:0]];
    
    [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeASCIICapable];
    [[alertView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
    [[alertView textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"message_enter_description", nil)];
    [[alertView textFieldAtIndex:1] setPlaceholder:NSLocalizedString(@"message_select_document_type", nil)];
    [[alertView textFieldAtIndex:1] setDelegate:self];
    [alertView show];
    
}

#pragma Function

- (void)validateDescription:(NSString *)description andTypeCode:(NSString *)typeCode {
    
    BOOL valid = YES;
    if ([[_claim objectID] isTemporaryID]) {
        valid = NO;
        [OT handleErrorWithMessage:NSLocalizedString(@"message_save_claim_before_adding_content", nil)];
        return;
    } else {
        if (description == nil || description.length == 0) valid = NO;
        if (typeCode == nil || typeCode.length == 0) valid = NO;
    }
    
    if (valid) {
        [_dictionary setValue:description forKey:@"description"];
        [_dictionary setValue:typeCode forKey:@"typeCode"];

        AttachmentEntity *attachmentEntity = [AttachmentEntity new];
        [attachmentEntity setManagedObjectContext:_claim.managedObjectContext];
        Attachment *attachment = [attachmentEntity create];
        [attachment importFromJSON:_dictionary];
        
        attachment.claim = _claim;
        NSString *typeCode = [_dictionary objectForKey:@"typeCode"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(displayValue CONTAINS[cd] %@)", typeCode];
        
        // Nạp lại sau khi claim đã save
        // Fix bug: một khi đã view thì _docTypeCollection được dùng managedObjectContext. Sau khi quay sang
        // map edit thì lúc này _claim.managedObjectContext đã thay đổi, cần phải set lại managedObjectContext
        DocumentTypeEntity *docTypeEntity = [DocumentTypeEntity new];
        [docTypeEntity setManagedObjectContext:_claim.managedObjectContext];
        _docTypeCollection = [docTypeEntity getCollection];

        DocumentType *docType = [[_docTypeCollection filteredArrayUsingPredicate:predicate] firstObject];
        attachment.typeCode = docType;
        
        if (attachment != nil) {
            NSString *destination = [[[FileSystemUtilities applicationDocumentsDirectory] path] stringByAppendingPathComponent:[FileSystemUtilities getAttachmentFolder:_claim.claimId]];
            destination = [destination stringByAppendingPathComponent:attachment.fileName];
            BOOL success = [FileSystemUtilities copyFileInAttachFolder:destination source:[_dictionary valueForKey:@"filePath"]];
            if (success) {
                attachment.claim = _claim;
                [attachment.managedObjectContext save:nil];
                
                [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"saved", nil)];
            }
        } else
            [OT handleErrorWithMessage:NSLocalizedString(@"message_error_creating_additional_info", nil)];
    } else
        [OT handleErrorWithMessage:NSLocalizedString(@"message_error_creating_additional_info", nil)];
}

#pragma UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _textField = textField;
    NSUInteger index = [_docTypeDisplayValue indexOfObject:_textField.text];
    [_pickerView selectRow:index inComponent:0 animated:NO];
    [_textField setInputView:_pickerView];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return NO;
}

#pragma UIAlertViewDelegate method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        UITextField *textFieldDescription = [alertView textFieldAtIndex:0];
        UITextField *textFieldTypeCode = [alertView textFieldAtIndex:1];
        [self validateDescription:textFieldDescription.text andTypeCode:textFieldTypeCode.text];
    }
}

#pragma UITableViewDelegate methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Attachment *attachment;
    
    if (_filteredObjects == nil)
        attachment = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        attachment = [_filteredObjects objectAtIndex:indexPath.row];

    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    NSString *fullPath = [FileSystemUtilities getAttachmentFolder:_claim.claimId];
    fullPath = [fullPath stringByAppendingPathComponent:[attachment.fileName lastPathComponent]];
    fullPath = [[[FileSystemUtilities applicationDocumentsDirectory] path] stringByAppendingPathComponent:fullPath];
    BOOL isFileExist = [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
    if (!isFileExist) {
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_menu_download_document"]];
    } else if (_claim.getViewType != OTViewTypeView) {
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        NSString *imageName = @"action_edit_document";
        UIImage *bgImage = [UIImage imageNamed:imageName];
        UIButton *actionBtn = [UIButton  buttonWithType:UIButtonTypeCustom];
        actionBtn.frame = CGRectMake(0, 0, bgImage.size.width, bgImage.size.height);
        [actionBtn setBackgroundImage:bgImage
                             forState:UIControlStateNormal];
        actionBtn.backgroundColor = [UIColor clearColor];
        
        actionBtn.tag = indexPath.row;
        [actionBtn addTarget:self action:@selector(checkButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
        
        cell.accessoryView = actionBtn;
    }
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    return cell;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Attachment *attachment;
    
    if (_filteredObjects == nil)
        attachment = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        attachment = [_filteredObjects objectAtIndex:indexPath.row];
    
    NSString *fullPath = [FileSystemUtilities getAttachmentFolder:_claim.claimId];
    fullPath = [fullPath stringByAppendingPathComponent:[attachment.fileName lastPathComponent]];
    fullPath = [[[FileSystemUtilities applicationDocumentsDirectory] path] stringByAppendingPathComponent:fullPath];
    NSURL *fileUrl = [NSURL fileURLWithPath:fullPath];
    
    BOOL isFileExist = [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
    if (!isFileExist) {
        NSString *title = NSLocalizedStringFromTable(@"title_download_document", @"Additional", nil);
        NSString *message = NSLocalizedStringFromTable(@"message_download_document", @"Additional", nil);
        [UIAlertView showWithTitle:title message:message cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"OK", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [FileSystemUtilities createClaimFolder:_claim.claimId];
                [CommunityServerAPI getAttachment:attachment.attachmentId saveToPath:fullPath];
            }
        }];
    } else {
        documentURL = fileUrl;
        QLPreviewController *previewController = [[QLPreviewController alloc] init];
        previewController.delegate = self;
        previewController.dataSource = self;
        previewController.currentPreviewItemIndex = 0;
        [self presentViewController:previewController animated:YES completion:^{
            UIView *view = [[[previewController.view.subviews lastObject] subviews] lastObject];
            if ([view isKindOfClass:[UINavigationBar class]])
            {
                [[UIApplication sharedApplication] setStatusBarHidden:NO];
                [((UINavigationBar *)view) setBarStyle:UIBarStyleBlackTranslucent];
                ((UINavigationBar *)view).tintColor = [UIColor whiteColor];
                ((UINavigationBar *)view).barTintColor = [UIColor otDarkBlue];
                ((UINavigationBar *)view).translucent = YES;
                [((UINavigationBar *)view) setBackgroundImage:[UIImage imageNamed:@"ot-navigation"] forBarMetrics:UIBarMetricsDefault];
            }
        }];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    Attachment *attachment;
    
    if (_filteredObjects == nil)
        attachment = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        attachment = [_filteredObjects objectAtIndex:indexPath.row];
    NSString *filePath = [[[FileSystemUtilities applicationDocumentsDirectory] path] stringByAppendingPathComponent:[FileSystemUtilities getAttachmentFolder:_claim.claimId]];
    filePath = [filePath stringByAppendingPathComponent:attachment.fileName];
    
    NSString *title = NSLocalizedString(@"app_name", nil);
    NSString *message = nil;
    [UIAlertView showWithTitle:title message:message placeholder0:NSLocalizedString(@"message_enter_description", nil) defaultText0:attachment.note delegate0:nil placeholder1:NSLocalizedString(@"message_select_document_type", nil) defaultText1:attachment.typeCode.displayValue delegate1:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"confirm", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            attachment.note = [[alertView textFieldAtIndex:0] text];
            
            DocumentTypeEntity *docTypeEntity = [DocumentTypeEntity new];
            [docTypeEntity setManagedObjectContext:attachment.managedObjectContext];
            NSArray *docTypeCollection = [docTypeEntity getCollection];
            NSString *typeCode = [[alertView textFieldAtIndex:1] text];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(displayValue CONTAINS[cd] %@)", typeCode];
            DocumentType *docType = [[docTypeCollection filteredArrayUsingPredicate:predicate] firstObject];
            attachment.typeCode = docType;
            [attachment.managedObjectContext save:nil];
        }
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return !_claim.getViewType == OTViewTypeView;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Attachment *attachment = [_fetchedResultsController objectAtIndexPath:indexPath];
        [self.managedObjectContext deleteObject:attachment];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

#pragma mark - QLPreviewControllerDataSource

// Returns the number of items that the preview controller should preview
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController {
    return 1;
}

// returns the item that the preview controller should preview
- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx {
    return documentURL;
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController {
    return self;
}


#pragma mark ActionSheet

- (IBAction)showImagePickerAlert:(id)sender {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.delegate = self;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [UIActionSheet showFromRect:[[sender view] frame] inView:self.view animated:YES withTitle:nil cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[NSLocalizedStringFromTable(@"from_photo_library", @"Additional", nil), NSLocalizedStringFromTable(@"take_new_photo", @"Additional", nil)] tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
            if (buttonIndex == [actionSheet cancelButtonIndex]) return;
            if (buttonIndex == 0) {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            } else {
                if (TARGET_IPHONE_SIMULATOR) return;
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                imagePickerController.showsCameraControls = YES;
                imagePickerController.videoQuality = UIImagePickerControllerQualityTypeMedium;
                imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
                imagePickerController.cameraDevice= UIImagePickerControllerCameraDeviceRear;
                imagePickerController.navigationBarHidden = NO;
                
            }
            if(IS_DEVICE_RUNNING_IOS_8_AND_ABOVE())
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self presentViewController:imagePickerController animated:YES completion:nil];
                });
                
            } else {
                [self presentViewController:imagePickerController animated:YES completion:nil];
            }
        }];
    } else {
        [UIActionSheet showFromToolbar:self.navigationController.toolbar withTitle:nil cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[NSLocalizedStringFromTable(@"from_photo_library", @"Additional", nil), NSLocalizedStringFromTable(@"take_new_photo", @"Additional", nil)] tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
            if (buttonIndex == [actionSheet cancelButtonIndex]) return;
            if (buttonIndex == 0) {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            } else {
                if (TARGET_IPHONE_SIMULATOR) return;
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                imagePickerController.showsCameraControls = YES;
                imagePickerController.videoQuality = UIImagePickerControllerQualityTypeMedium;
                imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
                imagePickerController.cameraDevice= UIImagePickerControllerCameraDeviceRear;
                imagePickerController.navigationBarHidden = NO;
                
            }
            if(IS_DEVICE_RUNNING_IOS_8_AND_ABOVE())
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self presentViewController:imagePickerController animated:YES completion:nil];
                });
                
            } else {
                [self presentViewController:imagePickerController animated:YES completion:nil];
            }
        }];
    }
}

#pragma mark UIImagePickerViewControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (!selectedImage) return;
        // TODO: Chưa hiểu tại sao khi chụp ảnh từ thiết bị, lưu vào file, khi submit nó lại báo sai kích thước. Mặc dù đã kiểm tra kích thước đúng?

        NSData *imageData = UIImageJPEGRepresentation(selectedImage, 1);

        NSString *temporaryFileName = @"_selectedImage_.png";
        NSString *temporaryFilePath = [[FileSystemUtilities getOpentenureFolder] stringByAppendingPathComponent:temporaryFileName];
        temporaryFilePath = [[[FileSystemUtilities applicationDocumentsDirectory] path] stringByAppendingPathComponent:temporaryFilePath];
        NSString *fileName = [[[[NSUUID UUID] UUIDString] lowercaseString] stringByAppendingPathExtension:@"jpg"];
        BOOL success = [imageData writeToURL:[[NSURL alloc] initFileURLWithPath:temporaryFilePath] atomically:YES];
        NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:temporaryFilePath error:nil];
        ALog(@"dict %@\nData size: %tu", dict.description, imageData.length);
        
        if (success) {
            unsigned long long size = [[[NSFileManager defaultManager] attributesOfItemAtPath:temporaryFilePath error:nil] fileSize];
            NSNumber *fileSize = [NSNumber numberWithUnsignedLongLong:size];
            NSData *fileData = [NSData dataWithContentsOfFile:temporaryFilePath];
            NSString *md5 = [fileData md5];
            
            self.dictionary = [NSMutableDictionary dictionary];
            [_dictionary setValue:[[[OT dateFormatter] stringFromDate:[NSDate date]] substringToIndex:10] forKey:@"documentDate"];
            [_dictionary setValue:@"image/jpg" forKey:@"mimeType"];
            [_dictionary setValue:fileName  forKey:@"fileName"];
            [_dictionary setValue:@"jpg" forKey:@"fileExtension"];
            [_dictionary setValue:[[[NSUUID UUID] UUIDString] lowercaseString] forKey:@"id"];
            [_dictionary setValue:fileSize forKey:@"size"];
            [_dictionary setValue:md5 forKey:@"md5"];
            [_dictionary setValue:kAttachmentStatusCreated forKey:@"status"];
            [_dictionary setValue:temporaryFilePath forKey:@"filePath"];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"new_file", nil)
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                                      otherButtonTitles:NSLocalizedString(@"confirm", nil), nil];
            
            [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
            
            // Alert style customization
            [[alertView textFieldAtIndex:1] setSecureTextEntry:NO];
            [[alertView textFieldAtIndex:1] setText:[_docTypeDisplayValue objectAtIndex:0]];
            
            [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeASCIICapable];
            [[alertView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
            [[alertView textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"message_enter_description", nil)];
            [[alertView textFieldAtIndex:1] setPlaceholder:NSLocalizedString(@"message_select_document_type", nil)];
            [[alertView textFieldAtIndex:1] setDelegate:self];
            [alertView show];
        } else {
            [OT handleErrorWithMessage:@"Error"];
        }
    }];
}

#pragma mark - UIPickerViewDelegate methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    _textField.text = [_docTypeDisplayValue objectAtIndex:row];
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _docTypeDisplayValue.count;
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [_docTypeDisplayValue objectAtIndex:row];
}

@end
