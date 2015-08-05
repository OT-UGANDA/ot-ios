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

#import "OTFileChooserViewController.h"
#import "SSZipArchive.h"

#define kRowHeight 58.0f

@interface OTFileChooserViewController () <SSZipArchiveDelegate>

@property (nonatomic, strong) DirectoryWatcher *docWatcher;
@property (nonatomic, strong) NSMutableArray *documentList;
@property (nonatomic, strong) NSMutableArray *documentURLs;
@property (nonatomic, strong) UIDocumentInteractionController *docInteractionController;
@end

@implementation OTFileChooserViewController
@synthesize watchFolder = _watchFolder;

- (void)setupDocumentControllerWithURL:(NSURL *)url
{
    if (self.docInteractionController == nil)
    {
        self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
        self.docInteractionController.delegate = self;
    }
    else
    {
        self.docInteractionController.URL = url;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // start monitoring the document directory…
    [self createToolbar];
    
    self.documentURLs = [NSMutableArray array];
    self.documentList = [NSMutableArray array];
    // scan for existing documents
    if (_watchFolder == nil)
        _watchFolder = [self applicationDocumentsDirectory];
    self.docWatcher = [DirectoryWatcher watchFolderWithPath:_watchFolder delegate:self];
    [self directoryDidChange:self.docWatcher];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray* resContents = [fileManager contentsOfDirectoryAtPath:[self applicationDocumentsDirectory] error:NULL];
    for (NSString *obj in resContents){
        [self.documentList addObject:obj];
    }
}

- (void)createToolbar {
    [self.navigationItem setHidesBackButton:YES];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancel;
    // Top
    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadContents:)];
    self.navigationItem.rightBarButtonItem = reloadButton;
}

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)reloadContents:(id)sender {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray* resContents = [fileManager contentsOfDirectoryAtPath:[self applicationDocumentsDirectory] error:NULL];
    for (NSString *obj in resContents){
        [self.documentList addObject:obj];
    }
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    self.documentURLs = nil;
    self.docWatcher = nil;
}

// if we installed a custom UIGestureRecognizer (i.e. long-hold), then this would be called
//
- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressGesture
{
    if (longPressGesture.state == UIGestureRecognizerStateBegan)
    {
        NSIndexPath *cellIndexPath = [self.tableView indexPathForRowAtPoint:[longPressGesture locationInView:self.tableView]];
        
        NSURL *fileURL;
        // for secton 1, we preview the docs found in the Documents folder
        fileURL = [self.documentURLs objectAtIndex:cellIndexPath.row];
        self.docInteractionController.URL = fileURL;
        
        [self.docInteractionController presentOptionsMenuFromRect:longPressGesture.view.frame
                                                           inView:longPressGesture.view
                                                         animated:YES];
    }
}
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self.docWatcher.currentPath isEqualToString:[self watchFolder]]) {
        return 1;
    } else
        return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView numberOfSections] == 1) {
        return self.documentURLs.count;
    }
    switch (section) {
        case 0:
            return  1;
            break;
            
        case 1:
            return self.documentURLs.count;
            break;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    self.title = [_docWatcher.currentPath lastPathComponent];

    NSString *title = [_docWatcher.currentPath lastPathComponent];//NSLocalizedString(@"documents", nil);
    if ([tableView numberOfSections] == 1) {
        if (self.documentURLs.count == 0)
            title = NSLocalizedString(@"folder_is_empty_notification", nil);
    } else {
        switch (section) {
            case 0:
                title = NSLocalizedString(@"back_to_folder", nil);
                break;
                
            default:
                if (self.documentURLs.count == 0)
                    title = NSLocalizedString(@"folder_is_empty_notification", nil);
                break;
        }
    }
    return title;
}

- (UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    NSURL *fileURL;
    // second section is the contents of the Documents folder
    if (self.documentURLs.count > 0) {
        fileURL = [self.documentURLs objectAtIndex:indexPath.row];
        [self setupDocumentControllerWithURL:fileURL];
    }
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
//    cell.tintColor = [UIColor extSegmentedTintColor];
//    cell.textLabel.textColor = [UIColor extSegmentedTintColor];
//    cell.detailTextLabel.textColor = [UIColor extSegmentedTintColor];
    
    if (([tableView numberOfSections] == 2 && indexPath.section == 0) || self.documentURLs.count == 0) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        NSString *previousPath = [self.docWatcher.currentPath stringByDeletingLastPathComponent];
        cell.textLabel.text = [previousPath lastPathComponent];
        cell.detailTextLabel.text = @"Go back to folder";
        cell.imageView.image = [UIImage imageNamed:@"folder_close"];
        return cell;
    } else {
        // layout the cell
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirectory];
        if (isDirectory) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [UIImage imageNamed:@"folder"];
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            NSInteger iconCount = [self.docInteractionController.icons count];
            if (iconCount > 0)
            {
                cell.imageView.image = [self.docInteractionController.icons objectAtIndex:0];
            }
        }
        
        cell.textLabel.text = [[fileURL path] lastPathComponent];

        NSString *fileURLString = [self.docInteractionController.URL path];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURLString error:nil];
        NSInteger fileSize = [[fileAttributes objectForKey:NSFileSize] intValue];
        NSString *fileSizeStr = [NSByteCountFormatter stringFromByteCount:fileSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", fileSizeStr, self.docInteractionController.UTI];
        
        // attach to our view any gesture recognizers that the UIDocumentInteractionController provides
        //cell.imageView.userInteractionEnabled = YES;
        //cell.contentView.gestureRecognizers = self.docInteractionController.gestureRecognizers;
        //
        // or
        // add a custom gesture recognizer in lieu of using the canned ones
        //
        
        UILongPressGestureRecognizer *longPressGesture =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [cell.imageView addGestureRecognizer:longPressGesture];
        cell.imageView.userInteractionEnabled = YES;    // this is by default NO, so we need to turn it on
    }
    return cell;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kRowHeight;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL attachDoc = [NSStringFromClass([self.delegate class]) isEqualToString:@"OTDocumentsUpdateViewController"];
    BOOL importClaim = [NSStringFromClass([self.delegate class]) isEqualToString:@"OTClaimsViewController"];
    if ([tableView numberOfSections] == 2 & indexPath.section == 0) {
        NSString *previousPath = [self.docWatcher.currentPath stringByDeletingLastPathComponent];
        self.docWatcher = [DirectoryWatcher watchFolderWithPath:previousPath delegate:self];
        [self directoryDidChange:self.docWatcher];
    } else {
        NSURL *fileURL;
        fileURL = [self.documentURLs objectAtIndex:indexPath.row];
        [self setupDocumentControllerWithURL:fileURL];
        
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirectory];
        // proceed to add the document URL to our list (ignore the "Inbox" folder)
        ALog(@"%@", self.docInteractionController.UTI);
        if (isDirectory) {
            self.docWatcher = [DirectoryWatcher watchFolderWithPath:[fileURL path] delegate:self];;
            [self directoryDidChange:self.docWatcher];
        } else if ([self.docInteractionController.UTI isEqualToString:OTDocTypeArchiveZip] && importClaim) {
            [_delegate fileChooserController:self didSelectFile:[fileURL path] uti:self.docInteractionController.UTI];
            [self.navigationController popViewControllerAnimated:YES];
        } else if (attachDoc) {
            [_delegate fileChooserController:self didSelectFile:[fileURL path] uti:self.docInteractionController.UTI];
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            ALog(@"%@", self.docInteractionController.UTI);
            // for case 3 we use the QuickLook APIs directly to preview the document -
            QLPreviewController *previewController = [[QLPreviewController alloc] init];
            previewController.dataSource = self;
            previewController.delegate = self;
            // start previewing the document at the current section index
            previewController.currentPreviewItemIndex = indexPath.row;
            [[self navigationController] pushViewController:previewController animated:YES];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if (tableView.numberOfSections == 2) {
        if (indexPath.section == 0)
            return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [UIAlertView showWithTitle:NSLocalizedString(@"delete_this_document_notification", nil) message:nil cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"confirm", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                NSError* error;
                if ([fileManager removeItemAtURL:[self.documentURLs objectAtIndex:indexPath.row]  error:&error]) {
                    if (error) {
                        ALog(@"Unresolved error %@, %@", error, [error userInfo]);
                    } else {
                        [self.documentURLs removeObjectAtIndex:indexPath.row];
                    }
                }
            }
        }];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController
{
    return self;
}


#pragma mark - QLPreviewControllerDataSource

// Returns the number of items that the preview controller should preview
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController
{
    NSInteger numToPreview = 0;
    
    numToPreview = self.documentURLs.count;
    
    return numToPreview;
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    // if the preview dismissed (done button touched), use this method to post-process previews
}

// returns the item that the preview controller should preview
- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx
{
    NSURL *fileURL = nil;
    
    fileURL = [self.documentURLs objectAtIndex:idx];
    
    return fileURL;
}


#pragma mark - File system support

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher {
    [self.documentURLs removeAllObjects];    // clear out the old docs and start over
    
    NSString *documentsDirectoryPath = folderWatcher.currentPath;
    
    NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:NULL];
    
    for (NSString* curFileName in [documentsDirectoryContents objectEnumerator])
    {
        NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:curFileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        // proceed to add the document URL to our list (ignore the ".DS_Store" file)
        if (![curFileName isEqualToString:@".DS_Store"]
            // &&
            //![curFileName isEqualToString:@"gmap_tiles_standard"] &&
            //![curFileName isEqualToString:@"gmap_tiles_satellite"] &&
            //![curFileName isEqualToString:@"gmap_tiles_hybrid"] &&
            //![curFileName isEqualToString:@"gmap_tiles_terrain"] &&
            //![curFileName isEqualToString:@"wms_tiles"])
            ) {
            [self.documentURLs addObject:fileURL];
        }
    }
    [self.tableView reloadData];
}


- (void)unzipFileAtPath:(NSString *)filePath {
    NSString *title = NSLocalizedString(@"extract_file_notification", nil);
    title = [NSString stringWithFormat:title, [filePath lastPathComponent]];
    NSString *cancelButtonTitle = NSLocalizedString(@"cancel", nil);
    NSString *okButtonTitle = NSLocalizedString(@"confirm", nil);
    [UIAlertView showWithTitle:title message:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:@[okButtonTitle] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//                NSString *path = [[filePath stringByDeletingPathExtension] lastPathComponent];
//                path = [[[Utilities applicationDocumentsDirectory] path] stringByAppendingPathComponent:path];
//                BOOL OK = [Utilities createDirectoryAtURL:[[NSURL alloc] initFileURLWithPath:path]];
//                if (OK) {
//                    BOOL success = [SSZipArchive unzipFileAtPath:filePath toDestination:path delegate:self];
//                    if(!success)
//                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"extrac_error", nil)];
//                }
            });
        }
    }];
    
}

#pragma mark - Unzip delegate
- (void)zipArchiveProgressEvent:(NSInteger)loaded total:(NSInteger)total {
    double progress = (double)loaded / (double)total;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [SVProgressHUD showProgress:progress
                             status:NSLocalizedString(@"extracting_file", nil)
                           maskType:SVProgressHUDMaskTypeGradient];
        if (loaded == total)
            [SVProgressHUD dismiss];
    }];
}

@end
