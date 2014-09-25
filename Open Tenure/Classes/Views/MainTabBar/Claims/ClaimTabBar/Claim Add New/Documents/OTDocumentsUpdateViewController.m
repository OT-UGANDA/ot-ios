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
#import "PickerView.h"
#import <QuickLook/QuickLook.h>

@interface OTDocumentsUpdateViewController () <OTFileChooserViewControllerDelegate, UITextFieldDelegate, UIDocumentInteractionControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) PickerView *pickerView;
@property (nonatomic, strong) NSMutableDictionary *dictionary;
@property (nonatomic, strong) NSArray *docTypeCollection;
@property (nonatomic, strong) NSMutableArray *docTypeDisplayValue;

@end

@implementation OTDocumentsUpdateViewController

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
    
    self.pickerView = [[PickerView alloc] initWithPickItems:_docTypeDisplayValue];
    [_pickerView setPickType:PickTypeList];
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
    return [NSPredicate predicateWithFormat:@"(claim = %@)", _claim];
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
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@, Type: %@", attachment.note, attachment.mimeType];
    cell.detailTextLabel.text = attachment.statusCode;
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

- (void)fileChooserController:(OTFileChooserViewController *)controller didSelectFile:(NSString *)file uti:(NSString *)uti {
    
    unsigned long long size = [[[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil] fileSize];
    NSNumber *fileSize = [NSNumber numberWithUnsignedLongLong:size];
    NSData *fileData = [NSData dataWithContentsOfFile:file];
    NSString *md5 = [fileData md5];
    self.dictionary = [NSMutableDictionary dictionary];
    [_dictionary setValue:[[OT dateFormatter] stringFromDate:[NSDate date]] forKey:@"documentDate"];
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
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(displayValue == %@)", typeCode];
        
        // Nạp lại sau khi claim đã save
        DocumentTypeEntity *docTypeEntity = [DocumentTypeEntity new];
        [docTypeEntity setManagedObjectContext:_claim.managedObjectContext];
        _docTypeCollection = [docTypeEntity getCollection];
        
        DocumentType *docType = [[_docTypeCollection filteredArrayUsingPredicate:predicate] firstObject];
        attachment.typeCode = docType;
        
        if (attachment != nil) {
            NSString *destination = [FileSystemUtilities getAttachmentFolder:_claim.claimId];
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
    [_pickerView attachWithTextField:textField];
    [_pickerView showPopOverList];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [_pickerView detach];
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
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Attachment *attachment;
    
    if (_filteredObjects == nil)
        attachment = [_fetchedResultsController objectAtIndexPath:indexPath];
    else
        attachment = [_filteredObjects objectAtIndex:indexPath.row];
    NSString *filePath = [FileSystemUtilities getAttachmentFolder:_claim.claimId];
    filePath = [filePath stringByAppendingPathComponent:attachment.fileName];
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    
    BOOL isFileExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if (!isFileExist) {
        NSString *title = @"Download attachment";
        NSString *message = @"This file does not exist in local. Do you want to download?";
        [UIAlertView showWithTitle:title message:message cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"OK", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [FileSystemUtilities createClaimFolder:attachment.claim.claimId];
                [CommunityServerAPI getAttachment:attachment.attachmentId saveToPath:filePath];
            }
        }];
    } else {
        // Presenting a Document Interaction Controller
        UIDocumentInteractionController *docView = [self setupControllerWithURL:fileUrl usingDelegate:self];
        [docView presentPreviewAnimated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
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

/*!
 Creating and Configuring a Document Interaction Controller
 */
- (UIDocumentInteractionController *)setupControllerWithURL:(NSURL *)fileURL
                                              usingDelegate:(id<UIDocumentInteractionControllerDelegate>)interactionDelegate {
    UIDocumentInteractionController *interactionController =
    [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    interactionController.delegate = interactionDelegate;
    return interactionController;
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
        [UIActionSheet showFromRect:[[sender view] frame] inView:self.view animated:YES withTitle:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"Select from photo library", nil), NSLocalizedString(@"Take new picture", nil)] tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
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
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }];
    } else {
        [UIActionSheet showFromToolbar:self.navigationController.toolbar withTitle:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"Select from photo library", nil), NSLocalizedString(@"Take new picture", nil)] tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
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
            [self presentViewController:imagePickerController animated:YES completion:nil];
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
        NSString *temporaryFilePath = [[[FileSystemUtilities applicationDocumentsDirectory] path] stringByAppendingPathComponent:@"Open Tenure"];
        temporaryFilePath = [temporaryFilePath stringByAppendingPathComponent:temporaryFileName];
        NSString *fileName = [[[[NSUUID UUID] UUIDString] lowercaseString] stringByAppendingPathExtension:@"jpg"];
        BOOL success = [imageData writeToFile:temporaryFilePath atomically:YES];
        NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:temporaryFilePath error:nil];
        ALog(@"dict %@\nData size: %tu", dict.description, imageData.length);
        
        if (success) {
            unsigned long long size = [[[NSFileManager defaultManager] attributesOfItemAtPath:temporaryFilePath error:nil] fileSize];
            NSNumber *fileSize = [NSNumber numberWithUnsignedLongLong:size];
            NSData *fileData = [NSData dataWithContentsOfFile:temporaryFilePath];
            NSString *md5 = [fileData md5];
            
            self.dictionary = [NSMutableDictionary dictionary];
            [_dictionary setValue:[[OT dateFormatter] stringFromDate:[NSDate date]] forKey:@"documentDate"];
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
            [[alertView textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"message_enter_description", nil)];
            [[alertView textFieldAtIndex:1] setPlaceholder:NSLocalizedString(@"message_select_document_type", nil)];
            [[alertView textFieldAtIndex:1] setDelegate:self];
            [alertView show];
        } else {
            [OT handleErrorWithMessage:@"Error"];
        }
    }];
}

@end
