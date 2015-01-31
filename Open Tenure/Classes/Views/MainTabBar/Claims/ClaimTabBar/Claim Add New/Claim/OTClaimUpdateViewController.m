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

#import <CoreText/CoreText.h>
#import "OTClaimUpdateViewController.h"
#import "OTFormInfoCell.h"
#import "OTFormInputTextFieldCell.h"
#import "OTFormInputTextViewCell.h"
#import "OTSelectionTabBarViewController.h"
#import "OTFormCell.h"

#import "CDRTranslucentSideBar.h"
#import "OTSideBarItems.h"

#import <QuickLook/QuickLook.h>

typedef NS_ENUM(NSInteger, OTCell) {
    OTCellClaimTypeTag = 1001,
    OTCellLandUseTag,
    OTCellStartDateTag,
    OTCellClaimantTag
};

@interface OTClaimUpdateViewController () <OTSelectionTabBarViewControllerDelegate, UIPickerViewDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource, UIViewControllerTransitioningDelegate> {
    NSURL *documentURL;
}

@property (nonatomic, strong) CDRTranslucentSideBar *sideBarMenu;
@property (nonatomic, strong) OTSideBarItems *sideBarItems;

@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIDatePicker *datePicker;

@property (nonatomic, strong) NSArray *claimTypeCollection;
@property (nonatomic, strong) NSArray *landUseCollection;

@property (nonatomic, strong) NSMutableArray *claimTypeDisplayValye;
@property (nonatomic, strong) NSMutableArray *landUseDisplayValue;

@property (nonatomic, strong) __block OTFormCell *claimantBlock;
@property (nonatomic, strong) __block OTFormCell *challengedBlock;
@property (nonatomic, strong) __block OTFormCell *claimTypeBlock;
@property (nonatomic, strong) __block OTFormCell *landUseBlock;
@property (nonatomic, strong) __block OTFormCell *startDateBlock;
@property (assign) OTViewType viewType;

@property (nonatomic, strong) UIView *pickerViewBackground;
@property (nonatomic, strong) UIView *datePickerBackground;

@property (nonatomic, assign, getter=isPickerClaimTypeShowing) BOOL pickerClaimTypeShowing;
@property (nonatomic, assign, getter=isPickerLandUseShowing) BOOL pickerLandUseShowing;
@property (nonatomic, assign, getter=isDatePickerShowing) BOOL datePickerShowing;

@end

@implementation OTClaimUpdateViewController

- (void)setupView {
    
    ClaimTypeEntity *claimTypeEntity = [ClaimTypeEntity new];
    [claimTypeEntity setManagedObjectContext:_claim.managedObjectContext];
    _claimTypeCollection = [claimTypeEntity getCollection];
    
    _claimTypeDisplayValye = [NSMutableArray array];
    for (ClaimType *object in _claimTypeCollection) {
        [_claimTypeDisplayValye addObject:object.displayValue];
    }
    
    LandUseEntity *landUseEntity = [LandUseEntity new];
    [landUseEntity setManagedObjectContext:_claim.managedObjectContext];
    _landUseCollection = [landUseEntity getCollection];
    _landUseDisplayValue = [NSMutableArray array];
    for (LandUse *object in _landUseCollection) {
        [_landUseDisplayValue addObject:object.displayValue];
    }
    
    // Dùng để view claim và person sử dụng context khi ở trạng thái select
    [_claim setToTemporary];

    self.viewType = _claim.getViewType;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureSideBarMenu];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
    singleTap.numberOfTapsRequired = 1;
    [self.tableView addGestureRecognizer:singleTap];

    [self setupView];
    
    // Headerview 16pt
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
    headerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = headerView;
    
    NSInteger customCellHeight = 32.0f;

    [self setHeaderTitle:NSLocalizedString(@"claim_name_label", nil) forSection:0];
    OTFormInputTextFieldCell *claimName =
    [[OTFormInputTextFieldCell alloc] initWithText:_claim.claimName
                                       placeholder:NSLocalizedString(@"claim_name", nil)
                                          delegate:self
                                         mandatory:YES
                                  customCellHeight:customCellHeight
                                      keyboardType:UIKeyboardTypeAlphabet
                                          viewType:self.viewType];
    claimName.didBeginEditingBlock =  ^void(BPFormInputCell *inCell, NSString *inText){
        [self hidePickers];
    };
    claimName.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
        if (inText.length > 0) {
            inCell.validationState = BPFormValidationStateValid;
            inCell.shouldShowInfoCell = NO;
            if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
                _claim.claimName = inText;
        } else {
            inCell.validationState = BPFormValidationStateInvalid;
            inCell.infoCell.label.text = NSLocalizedString(@"message_error_mandatory_fields", nil);
            inCell.shouldShowInfoCell = YES;
        }
        return YES;
    };
    if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
        [claimName.textField becomeFirstResponder];
    claimName.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    
    // Claim Type
    [self setHeaderTitle:NSLocalizedString(@"claim_type", nil) forSection:1];
    if (_claim.claimType == nil)
        _claim.claimType = [_claimTypeCollection firstObject];

    OTFormCell *claimType = [[OTFormCell alloc] initWithFrame:CGRectZero];
    _claimTypeBlock = claimType;
    claimType.tag = OTCellClaimTypeTag;
    
    UITapGestureRecognizer *claimTypeTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerClaimTypeShow:)];
    claimTypeTapped.numberOfTapsRequired = 1;
    
    NSString *claimTypeTitle = _claim.claimType.displayValue;
    
    claimType.selectionStyle = UITableViewCellSelectionStyleNone;
    claimType.imageView.image = [UIImage imageNamed:@"ic_action_picker"];
    claimType.textLabel.attributedText = [OT getAttributedStringFromText:claimTypeTitle];
    claimType.imageView.userInteractionEnabled = YES;
    claimType.imageView.tag = OTCellClaimTypeTag;
    [claimType.imageView addGestureRecognizer:claimTypeTapped];

    // Land Use
    [self setHeaderTitle:NSLocalizedString(@"land_use", nil) forSection:2];
    if (_claim.landUse == nil)
        _claim.landUse = [_landUseCollection firstObject];

    OTFormCell *landUse = [[OTFormCell alloc] initWithFrame:CGRectZero];
    _landUseBlock = landUse;
    landUse.tag = OTCellLandUseTag;
    
    UITapGestureRecognizer *landUseTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerLandUseShow:)];
    landUseTapped.numberOfTapsRequired = 1;
    
    NSString *landUseTitle = _claim.landUse.displayValue;
    
    landUse.selectionStyle = UITableViewCellSelectionStyleNone;
    landUse.imageView.image = [UIImage imageNamed:@"ic_action_picker"];
    landUse.textLabel.attributedText = [OT getAttributedStringFromText:landUseTitle];
    landUse.imageView.userInteractionEnabled = YES;
    landUse.imageView.tag = OTCellLandUseTag;
    [landUse.imageView addGestureRecognizer:landUseTapped];
    
    // Date of right's start (YYYY-MM-DD)
    [self setHeaderTitle:NSLocalizedString(@"date_of_start_label", nil) forSection:3];
    if (_claim.startDate == nil)
        _claim.startDate = [[OT dateFormatter] stringFromDate:[NSDate date]];

    OTFormCell *startDate = [[OTFormCell alloc] initWithFrame:CGRectZero];
    _startDateBlock = startDate;
    startDate.tag = OTCellStartDateTag;
    
    UITapGestureRecognizer *startDateTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(datePickerShow:)];
    startDateTapped.numberOfTapsRequired = 1;
    
    NSString *startDateTitle = [_claim.startDate substringToIndex:10];;
    
    startDate.selectionStyle = UITableViewCellSelectionStyleNone;
    startDate.imageView.image = [UIImage imageNamed:@"ic_action_datepicker"];
    startDate.textLabel.attributedText = [OT getAttributedStringFromText:startDateTitle];
    startDate.imageView.userInteractionEnabled = YES;
    startDate.imageView.tag = OTCellStartDateTag;
    [startDate.imageView addGestureRecognizer:startDateTapped];
    
    // Claim notes
    [self setHeaderTitle:NSLocalizedString(@"claim_notes", nil) forSection:4];
    OTFormInputTextFieldCell *claimNotes =
    [[OTFormInputTextFieldCell alloc] initWithText:_claim.notes
                                       placeholder:NSLocalizedString(@"insert_claim_notes", nil)
                                          delegate:self
                                         mandatory:NO
                                  customCellHeight:customCellHeight * 1.5
                                      keyboardType:UIKeyboardTypeDefault
                                          viewType:self.viewType];
    claimNotes.didBeginEditingBlock =  ^void(BPFormInputCell *inCell, NSString *inText){
        [self hidePickers];
    };
    claimNotes.textLabel.numberOfLines = 0;
    claimNotes.shouldChangeTextBlock = ^BOOL(BPFormInputCell *inCell, NSString *inText) {
        if (self.viewType == OTViewTypeAdd || self.viewType == OTViewTypeEdit)
            _claim.notes = inText;
        return YES;
    };
    
    // Select person
    [self setHeaderTitle:NSLocalizedString(@"claimant", nil) forSection:5];
    OTFormCell *claimant = [[OTFormCell alloc] initWithFrame:CGRectZero];
    _claimantBlock = claimant;
    claimant.tag = OTCellClaimantTag;
    
    UITapGestureRecognizer *claimantTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showClaimant)];
    claimantTapped.numberOfTapsRequired = 1;
    
    NSString *claimantTitle = _claim.person != nil ? [_claim.person fullNameType:OTFullNameTypeDefault] : NSLocalizedString(@"message_touch_to_select_a_person", nil);
    
    claimant.selectionStyle = UITableViewCellSelectionStyleNone;
    claimant.imageView.image = _claim.person == nil ? [UIImage imageNamed:@"ic_action_add_claimant"] : [UIImage imageNamed:@"ic_action_edit_claimant"];
    claimant.textLabel.attributedText = [OT getAttributedStringFromText:claimantTitle];
    claimant.imageView.userInteractionEnabled = YES;
    claimant.imageView.tag = OTCellClaimantTag;
    [claimant.imageView addGestureRecognizer:claimantTapped];
    
    // Select challenged to claim
    [self setHeaderTitle:NSLocalizedString(@"challenge_to", nil) forSection:6];
    OTFormCell *challenged = [[OTFormCell alloc] initWithFrame:CGRectZero];
    _challengedBlock = challenged;
    
    UITapGestureRecognizer *challengedTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showSelectChallenged)];
    challengedTapped.numberOfTapsRequired = 1;
    
    NSString *challengedTitle = _claim.challenged != nil ? [_claim.challenged claimName] : NSLocalizedString(@"message_touch_to_select_a_claim", nil);
    
    challenged.selectionStyle = UITableViewCellSelectionStyleNone;
    challenged.imageView.image = _claim.challenged == nil ? [UIImage imageNamed:@"ic_action_add_claimant"] : [UIImage imageNamed:@"ic_action_remove_claimant"];
    challenged.textLabel.attributedText = [OT getAttributedStringFromText:challengedTitle];
    challenged.imageView.userInteractionEnabled = YES;
    [challenged.imageView addGestureRecognizer:challengedTapped];

    claimName.customCellHeight = customCellHeight;
    claimType.customCellHeight = customCellHeight;
    landUse.customCellHeight = customCellHeight;
    startDate.customCellHeight = customCellHeight;
    claimNotes.customCellHeight = customCellHeight;
    claimant.customCellHeight = customCellHeight;
    challenged.customCellHeight = customCellHeight;
    self.formCells = @[@[claimName], @[claimType], @[landUse], @[startDate], @[claimNotes], @[claimant], @[challenged]];
    
    self.customSectionHeaderHeight = 16;
    self.customSectionFooterHeight = 8;
}

- (IBAction)singleTapAction:(id)sender {
    [self hidePickers];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _claimantBlock.imageView.image = _claim.person == nil ? [UIImage imageNamed:@"ic_action_add_claimant"] : [UIImage imageNamed:@"ic_action_edit_claimant"];
    NSString *claimantTitle = _claim.person != nil ? [_claim.person fullNameType:OTFullNameTypeDefault] : NSLocalizedString(@"message_touch_to_select_a_person", nil);
    _claimantBlock.textLabel.attributedText = [OT getAttributedStringFromText:claimantTitle];

    _challengedBlock.imageView.image = _claim.challenged == nil ? [UIImage imageNamed:@"ic_action_add_claimant"] : [UIImage imageNamed:@"ic_action_remove_claimant"];
    NSString *challengedTitle = _claim.challenged != nil ? [_claim.challenged claimName] : NSLocalizedString(@"message_touch_to_select_a_claim", nil);
    _challengedBlock.textLabel.attributedText = [OT getAttributedStringFromText:challengedTitle];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)configureSideBarMenu {
    _sideBarItems = [[OTSideBarItems alloc] initWithStyle:UITableViewStylePlain];
    NSArray *cells = @[@{@"title" : NSLocalizedStringFromTable(@"action_showcase", @"Showcase", nil)}];
    
    [_sideBarItems setCells:cells];
    __strong typeof(self) self_ = self;
    _sideBarItems.itemAction = ^void(NSInteger section, NSInteger itemIndex) {
        switch (itemIndex) {
            case 0:
                // TODO View tutorial
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

- (IBAction)addPerson:(id)sender {
    [self dismissKeyboard];
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
                          
                          OTAppDelegate* appDelegate = (OTAppDelegate*)[[UIApplication sharedApplication] delegate];
                          id main = appDelegate.window.rootViewController;
                          UINavigationController *nav = [[main storyboard] instantiateViewControllerWithIdentifier:@"PersonTabBar"];
                          if (nav != nil) {
                              [self.navigationController presentViewController:nav animated:YES completion:nil];
                          }
                      }];
}

- (void)insertNewPersonWithType:(BOOL)physical {
    
    PersonEntity *personEntity = [PersonEntity new];
    [personEntity setManagedObjectContext:_claim.managedObjectContext];
    Person *newPerson = [personEntity create];
    newPerson.personId = [[[NSUUID UUID] UUIDString] lowercaseString];
    newPerson.person = [NSNumber numberWithBool:physical];
    // Save person to temporary
    [newPerson setToTemporary];
    
    _claim.person = newPerson;
}

#pragma Bar Buttons Action
- (void)showInvalidCell:(OTFormInputTextFieldCell *)cell {
    allCellChecked = true;
    [cell.textField becomeFirstResponder];
    [cell.textField resignFirstResponder];
}

- (void)checkInvalidCell {
    NSInteger i = 0;
    while (i < self.formCells.count) {
        for (OTFormInputTextFieldCell *cell in self.formCells[i]) {
            if (cell.validationState == BPFormValidationStateInvalid) {
                [self performSelector:@selector(showInvalidCell:) withObject:cell afterDelay:3];
            }
        }
        i++;
    }
}

- (void)updateShare {
    if (_claim.shares.count != 0) return;
    ShareEntity *shareEntity = [ShareEntity new];
    [shareEntity setManagedObjectContext:_claim.managedObjectContext];
    Share *share = [shareEntity create];
    share.shareId = [[[NSUUID UUID] UUIDString] lowercaseString];
    [share addOwnersObject:[_claim.person clone]];
    share.denominator = [NSNumber numberWithInteger:100];
    share.nominator = [NSNumber numberWithInteger:100];
    share.claim = _claim;
}

static bool allCellChecked = false;
- (IBAction)save:(id)sender {
    [self.sideBarMenu dismiss];
    if (self.allCellsAreValid) {
        if (_claim.person == nil) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_unable_to_save_missing_person", nil)];
        } else if ([_claim.managedObjectContext hasChanges]) {
            [FileSystemUtilities createClaimFolder:_claim.claimId];
            [self updateShare];
            [_claim.managedObjectContext save:nil];
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"message_saved", nil)];
            [self setupView];
        }
    } else {
        if (!allCellChecked) [self checkInvalidCell];
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_error_mandatory_fields", nil)];
    }
}

- (IBAction)cancel:(id)sender {
    [self.sideBarMenu dismiss];
    if (![_claim isSaved]) {
        [self.navigationController dismissViewControllerAnimated:NO completion:^{
            [_claim.managedObjectContext deleteObject:_claim];
        }];
    } else {
        if ([_claim.managedObjectContext hasChanges] && self.viewType == OTViewTypeEdit) {
            [UIAlertView showWithTitle:NSLocalizedStringFromTable(@"title_save_dialog", @"Additional", nil) message:NSLocalizedStringFromTable(@"message_save_dialog", @"Additional", nil)
                                 style:UIAlertViewStyleDefault cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"action_save", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
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
    [self.sideBarMenu dismiss];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PDF Generation

- (UIImage *)imageByCroppingImage:(UIImage *)image toSize:(CGSize)size {
    double refWidth = CGImageGetWidth(image.CGImage);
    double refHeight = CGImageGetHeight(image.CGImage);
    
    double x = (refWidth - size.width) / 2.0;
    double y = (refHeight - size.height) / 2.0;
    CGRect cropRect = CGRectMake(x, y, size.width, size.height);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    
    UIImage *cropped = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    
    return cropped;
}

- (UIImage *)getCadastralMapWithSize:(CGSize)size {
    NSString *cadastralMap = @"_map_.jpg";
    for (Attachment *attachment in _claim.attachments) {
        if ([attachment.typeCode.code isEqualToString:@"cadastralMap"] &&
            [attachment.note isEqualToString:@"Map"]) {
            cadastralMap = attachment.fileName;
        }
    }
    NSString *claimImagePath = [[FileSystemUtilities getAttachmentFolder:_claim.claimId] stringByAppendingPathComponent:cadastralMap];
    UIImage *image = [UIImage imageWithContentsOfFile:claimImagePath];
    if (image) {
        CGFloat width = image.size.width < image.size.height ? image.size.width : image.size.height;
        CGFloat scale = size.width > size.height ? width / size.width : width / size.height;
        CGSize newSize = CGSizeMake(scale * size.width, scale * size.height);
        return [self imageByCroppingImage:image toSize:newSize];
    }
    return nil;
}

- (void)setupPDFDocumentName:(NSString *)name pageSize:(CGSize)pageSize {
    [FileSystemUtilities createClaimFolder:_claim.claimId];
    [FileSystemUtilities createClaimantFolder:_claim.claimId];
    NSString *claimFolder = [FileSystemUtilities getClaimFolder:_claim.claimId];
    NSString *pdfPath = [claimFolder stringByAppendingPathComponent:name];
    UIGraphicsBeginPDFContextToFile(pdfPath, CGRectZero, nil);
}

- (void)beginPDFPageSize:(CGSize)pageSize {
    UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, pageSize.width, pageSize.height), nil);
}

- (CGRect)PDFPageSize:(CGSize)pageSize addText:(NSString*)text withFrame:(CGRect)frame font:(UIFont *)font textColor:(UIColor *)textColor {

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentLeft;

    CGRect textRect = [text boundingRectWithSize:CGSizeZero
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle.copy}
                                         context:nil];
    CGSize stringSize = textRect.size;
    float textWidth = frame.size.width;
    
    if (stringSize.width > pageSize.width - frame.origin.x - (frame.size.width - frame.origin.x))
        textWidth = frame.size.width;
    else
        textWidth = stringSize.width;
    
    CGRect renderingRect = CGRectMake(frame.origin.x, frame.origin.y, textWidth, stringSize.height);
    
    [text drawInRect:renderingRect withAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:textColor,  NSParagraphStyleAttributeName:paragraphStyle.copy}];
    
    frame = CGRectMake(frame.origin.x, frame.origin.y, textWidth, stringSize.height);
    return frame;
}

- (CGRect)addLineWithFrame:(CGRect)frame withColor:(UIColor *)color {
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    CGPoint startPoint = frame.origin;
    CGPoint endPoint = CGPointMake(frame.origin.x + frame.size.width, frame.origin.y);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, startPoint.x, startPoint.y);
    CGPathAddLineToPoint(path, NULL, endPoint.x, endPoint.y);
    CGPathCloseSubpath(path);
    if (path != NULL) {
        CGContextAddPath(currentContext, path);
        CGContextSetStrokeColorWithColor(currentContext, color.CGColor);
        CGContextSetLineWidth(currentContext, frame.size.height);
        CGContextSetFillColorWithColor(currentContext, [[UIColor clearColor] CGColor]);
        CGContextDrawPath(currentContext, kCGPathFillStroke);
        CGPathRelease(path);
        
    }
    return frame;
}

- (CGRect)addImage:(UIImage*)image atPoint:(CGPoint)point size:(CGSize)size {
    CGRect imageFrame = CGRectMake(point.x, point.y, size.width, size.height);
    [image drawInRect:imageFrame];
    return imageFrame;
}

- (void)finishPDF {
    UIGraphicsEndPDFContext();
}

- (void)quickPreviewFilePath:(NSString *)filePath {
    documentURL = [NSURL fileURLWithPath:filePath];
    QLPreviewController *previewController = [[QLPreviewController alloc] init];
    previewController.delegate = self;
    previewController.dataSource = self;
    previewController.currentPreviewItemIndex = 0;

    [self.navigationController presentViewController:previewController animated:YES completion:^{
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

- (IBAction)print:(id)sender {
    [self.sideBarMenu dismiss];
    
    CGSize pageSize = CGSizeMake(595.28, 841.89);
    CGFloat kPadding = 40.0;
    CGFloat kTopMargin = 30.0;
    CGFloat kFontSize = 14.0;
    CGFloat kLineSpacing = 8.0;
    CGFloat x = kPadding;
    CGFloat y = kPadding;
    CGFloat width = pageSize.width - 2.0 * kPadding;
    CGRect rect = CGRectZero;
    
    NSString *pdfName = @"print_and_sign_this.pdf";
    
    
    [self setupPDFDocumentName:pdfName pageSize:pageSize];
    [self beginPDFPageSize:pageSize];
    NSString *title = [NSString stringWithFormat:@"Open Tenure Claim: %@ (Claimant *: %@)", _claim.claimName, [_claim.person fullNameType:OTFullNameTypeDefault]];
    
    // Tiêu đề
    rect = [self PDFPageSize:pageSize
                     addText:title
                   withFrame:CGRectMake(kPadding, kTopMargin, pageSize.width - kPadding * 2.0, kFontSize)
                        font:[UIFont boldSystemFontOfSize:kFontSize]
                   textColor:[UIColor otDarkBlue]];
    
    // Logo
    UIImage *logoImage = [UIImage imageNamed:@"sola_logo"];
    rect = [self addImage:logoImage atPoint:CGPointMake(kPadding, rect.origin.y + rect.size.height + kLineSpacing) size:logoImage.size];
    
    // Line 1
    rect = [self addLineWithFrame:CGRectMake(kPadding, rect.origin.y + rect.size.height + kLineSpacing, pageSize.width - kPadding * 2.0, 0.5) withColor:[UIColor otDarkBlue]];
    
    // Info text
    NSString *firstName = NSLocalizedString(@"first_name", nil);
    NSString *lastName = NSLocalizedString(@"last_name", nil);
    NSString *birthDate = NSLocalizedString(@"date_of_birth", nil);
    NSString *postalAddress = NSLocalizedString(@"postal_address", nil);
    NSString *contactPhoneNumber = NSLocalizedString(@"contact_phone_number", nil);

    NSString *infoText = [NSString stringWithFormat:@"%@: %@\n%@: %@\n%@: %@\n%@: %@\n%@: %@", firstName, _claim.person.name, lastName, _claim.person.lastName, birthDate, [_claim.person.birthDate substringToIndex:10], postalAddress, _claim.person.address, contactPhoneNumber, _claim.person.phone];
    if (![_claim.person.person boolValue]) {
        firstName = NSLocalizedString(@"group_name", nil);
        birthDate = NSLocalizedString(@"date_of_establishment_label", nil);
        infoText = [NSString stringWithFormat:@"%@: %@\n%@: %@\n%@: %@\n%@: %@", firstName, _claim.person.name, birthDate, [_claim.person.birthDate substringToIndex:10], postalAddress, _claim.person.address, contactPhoneNumber, _claim.person.phone];
    }
    
    rect = [self PDFPageSize:pageSize
                     addText:infoText
                   withFrame:CGRectMake(kPadding, rect.origin.y + kLineSpacing, pageSize.width - kPadding * 2.0, kFontSize)
                        font:[UIFont systemFontOfSize:kFontSize]
                   textColor:[UIColor blackColor]];
    // Line 2
    rect = [self addLineWithFrame:CGRectMake(kPadding, rect.origin.y + rect.size.height + kLineSpacing, pageSize.width - kPadding * 2.0, 0.5) withColor:[UIColor otDarkBlue]];
    
    // Cadastral map
    CGSize imageSize = CGSizeMake(width, width - kLineSpacing * 8.0);
    UIImage *claimImage = [self getCadastralMapWithSize:imageSize];
    if (claimImage != nil)
        rect = [self addImage:claimImage atPoint:CGPointMake(kPadding, rect.origin.y + rect.size.height + kLineSpacing) size:imageSize];
    else
        rect = [self PDFPageSize:pageSize
                         addText:@"Please download Cadastral Map!"
                       withFrame:CGRectMake(kPadding, rect.origin.y + kLineSpacing, pageSize.width - kPadding * 2.0, kFontSize)
                            font:[UIFont boldSystemFontOfSize:kFontSize]
                       textColor:[UIColor redColor]];
    
    // Line 3
    rect = [self addLineWithFrame:CGRectMake(kPadding, rect.origin.y + rect.size.height + kLineSpacing, pageSize.width - kPadding * 2.0, 0.5) withColor:[UIColor otDarkBlue]];
    
    // Date and Signature
    NSString *dateText = NSLocalizedString(@"date", nil);
    NSString *signatureText = NSLocalizedString(@"signature", nil);
    x = kPadding;
    y = rect.origin.y + rect.size.height + kLineSpacing * 2.0;

    CGRect rect1 = [self PDFPageSize:pageSize
                             addText:dateText
                           withFrame:CGRectMake(x, y, width, kFontSize)
                                font:[UIFont systemFontOfSize:kFontSize]
                           textColor:[UIColor blackColor]];
    CGRect rect2 = [self PDFPageSize:pageSize
                             addText:signatureText
                           withFrame:CGRectMake(x + (width - x) / 2.0, y, width / 2.0, kFontSize)
                                font:[UIFont systemFontOfSize:kFontSize]
                           textColor:[UIColor blackColor]];
    
    // Date line ____
    x = rect1.origin.x + rect1.size.width;
    y = rect1.origin.y + rect1.size.height;
    width = pageSize.width / 2.0 - x - rect1.size.width;
    CGRect rectLine1 = [self addLineWithFrame:CGRectMake(x, y, width, 0.5) withColor:[UIColor otDarkBlue]];
    
    // Signature line ___
    x = rect2.origin.x + rect2.size.width;
    width = pageSize.width - kPadding - x;
    CGRect rectLine2 = [self addLineWithFrame:CGRectMake(x, y, width, 0.5) withColor:[UIColor otDarkBlue]];
    
    // Adjacent claim
    x = kPadding;
    y = rect1.origin.y + rect1.size.height + kLineSpacing;
    NSString *adjacentClaims = NSLocalizedString(@"adjacent_claims", nil);
    rect = [self PDFPageSize:pageSize
                     addText:adjacentClaims
                   withFrame:CGRectMake(x, y, width, kFontSize)
                        font:[UIFont systemFontOfSize:kFontSize]
                   textColor:[UIColor blackColor]];
    // Line 5
    x = kPadding;
    y = rect.origin.y + rect.size.height + kLineSpacing * 2.0;
    rect = [self addLineWithFrame:CGRectMake(x, y, pageSize.width - kPadding * 2.0, 0.5) withColor:[UIColor otDarkBlue]];

    // Adjacencies
    x = kPadding;
    y = rect.origin.y + rect.size.height + kLineSpacing;
    NSString *adjacencies = NSLocalizedString(@"title_claim_adjacencies", nil);
    rect = [self PDFPageSize:pageSize
                     addText:adjacencies
                   withFrame:CGRectMake(x, y, width, kFontSize)
                        font:[UIFont systemFontOfSize:kFontSize]
                   textColor:[UIColor blackColor]];

    // Line 6
    x = kPadding;
    y = rect.origin.y + rect.size.height + kLineSpacing * 2.0;
    rect = [self addLineWithFrame:CGRectMake(x, y, pageSize.width - kPadding * 2.0, 0.5) withColor:[UIColor otDarkBlue]];
    
    // Date and Signature 2
    x = kPadding;
    y = rect.origin.y + rect.size.height + kLineSpacing * 2.0;
    rect1.origin.y = y;
    rect2.origin.y = y;
    CGRect rect11 = [self PDFPageSize:pageSize
                              addText:dateText
                            withFrame:rect1
                                 font:[UIFont systemFontOfSize:kFontSize]
                            textColor:[UIColor blackColor]];
    [self PDFPageSize:pageSize
              addText:signatureText
            withFrame:rect2
                 font:[UIFont systemFontOfSize:kFontSize]
            textColor:[UIColor blackColor]];

    // Date line ____
    y = rect11.origin.y + rect11.size.height;
    rectLine1.origin.y = y;
    rectLine2.origin.y = y;
    [self addLineWithFrame:rectLine1 withColor:[UIColor otDarkBlue]];
    
    // Signature line ___
    [self addLineWithFrame:rectLine2 withColor:[UIColor otDarkBlue]];
    
    // Finish
    [self finishPDF];
    
    // Quick preview pdf
    NSString *claimFolder = [FileSystemUtilities getClaimFolder:_claim.claimId];
    NSString *pdfPath = [claimFolder stringByAppendingPathComponent:pdfName];
    [self quickPreviewFilePath:pdfPath];
}

- (BOOL)createClaimJsonFile {
    NSString *claimFolder = [FileSystemUtilities getClaimFolder:_claim.claimId];
    NSString *claimJsonFile = [claimFolder stringByAppendingPathComponent:@"claim.json"];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_claim.dictionary options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return [jsonString writeToFile:claimJsonFile atomically:NO encoding:NSUTF8StringEncoding error:&error];
}

- (IBAction)export:(id)sender {
    [self.sideBarMenu dismiss];
    [FileSystemUtilities createClaimFolder:_claim.claimId];
    [FileSystemUtilities createClaimantFolder:_claim.claimId];

    NSString *title = NSLocalizedString(@"title_export", nil);
    NSString *message = nil;
    NSString *cancelButtonTitle = NSLocalizedString(@"cancel", nil);
    NSString *otherButtonTitle = NSLocalizedString(@"action_export", nil);
    [UIAlertView showWithTitle:title message:message style:UIAlertViewStyleSecureTextInput cancelButtonTitle:cancelButtonTitle otherButtonTitles:@[otherButtonTitle] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"message_export", nil)];
            NSString *password = [[alertView textFieldAtIndex:0] text];
            // Tạo
            BOOL success = NO;
            if ([self createClaimJsonFile]) {
                success = [ZipUtilities addFilesWithAESEncryption:password claimId:_claim.claimId];
            }
            if (success)
                [SVProgressHUD showSuccessWithStatus:@""];
            else
                [OT handleErrorWithMessage:NSLocalizedString(@"message_encryption_failed", nil)];
        }
    }];
}

- (void)rollback {
    [_claim.managedObjectContext rollback];
}

#pragma OTSelectionTabBarViewControllerDelegate methods

- (void)personSelection:(OTSelectionTabBarViewController *)controller didSelectPerson:(Person *)person {
    _claim.person = person;
    _claimantBlock.textLabel.attributedText = [OT getAttributedStringFromText:[person fullNameType:OTFullNameTypeDefault]];
    _claimantBlock.validationState = BPFormValidationStateValid;
    
    ShareEntity *shareEntity = [ShareEntity new];
    [shareEntity setManagedObjectContext:_claim.managedObjectContext];
    Share *share = [shareEntity create];
    share.shareId = [[[NSUUID UUID] UUIDString] lowercaseString];
    [share addOwnersObject:[person clone]];
    share.denominator = [NSNumber numberWithInteger:100];
    share.nominator = [NSNumber numberWithInteger:100];
    share.claim = _claim;
    
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)claimSelection:(OTSelectionTabBarViewController *)controller didSelelectClaim:(Claim *)claim {
    _claim.challenged = claim;
    _claim.challengedClaimId = claim.claimId;
    _challengedBlock.textLabel.attributedText = [OT getAttributedStringFromText:claim.claimName];
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissKeyboard {
    for (id cells in self.formCells) {
        for (id cell in cells) {
            if ([cell isKindOfClass:[BPFormInputTextFieldCell class]] ||
                [cell isKindOfClass:[BPFormInputTextViewCell class]]) {
                [[cell textField] resignFirstResponder];
            }
        }
    }
}

- (IBAction)pickerClaimTypeShow:(UIGestureRecognizer *)sender {
    if (self.viewType == OTViewTypeView) return;
    if (![self isPickerClaimTypeShowing] && ![self isPickerLandUseShowing] && ![self isDatePickerShowing]) {
        [self dismissKeyboard];
        CGRect frame = _claimTypeBlock.textLabel.frame;
        
        _pickerViewBackground = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, _claimTypeBlock.frame.origin.y + _claimTypeBlock.frame.size.height, frame.size.width, 150)];
        _pickerViewBackground.layer.borderColor = [[UIColor otGreen] CGColor];
        _pickerViewBackground.layer.borderWidth = 1;
        _pickerViewBackground.layer.cornerRadius = 4.0f;
        _pickerViewBackground.backgroundColor = [UIColor whiteColor];
        _pickerViewBackground.alpha = 0.95;
        
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 150)];
        _pickerView.delegate = self;
        _pickerClaimTypeShowing = YES;
        [_pickerView reloadAllComponents];
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"displayValue" ascending:YES];
        NSArray *options = [_claimTypeCollection sortedArrayUsingDescriptors:@[sortDescriptor]];
        for (int i = 0; i < options.count; i++) {
            ClaimType *claimType = [options objectAtIndex:i];
            if ([_claim.claimType isEqual:claimType])
                [_pickerView selectRow:i inComponent:0 animated:YES];
        }
        
        [_pickerViewBackground addSubview:_pickerView];
        [_claimTypeBlock.superview.superview addSubview:_pickerViewBackground];
    } else [self hidePickers];
}

- (IBAction)pickerLandUseShow:(UIGestureRecognizer *)sender {
    if (self.viewType == OTViewTypeView) return;
    if (![self isPickerClaimTypeShowing] && ![self isPickerLandUseShowing] && ![self isDatePickerShowing]) {
        [self dismissKeyboard];
        CGRect frame = _landUseBlock.textLabel.frame;
        
        _pickerViewBackground = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, _landUseBlock.frame.origin.y + _landUseBlock.frame.size.height, frame.size.width, 150)];
        _pickerViewBackground.layer.borderColor = [[UIColor otGreen] CGColor];
        _pickerViewBackground.layer.borderWidth = 1;
        _pickerViewBackground.layer.cornerRadius = 4.0f;
        _pickerViewBackground.backgroundColor = [UIColor whiteColor];
        _pickerViewBackground.alpha = 0.95;
        
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 150)];
        _pickerView.delegate = self;
        _pickerLandUseShowing = YES;
        [_pickerView reloadAllComponents];
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"displayValue" ascending:YES];
        NSArray *options = [_landUseCollection sortedArrayUsingDescriptors:@[sortDescriptor]];
        for (int i = 0; i < options.count; i++) {
            LandUse *landUse = [options objectAtIndex:i];
            if ([_claim.landUse isEqual:landUse])
                [_pickerView selectRow:i inComponent:0 animated:YES];
        }
        
        [_pickerViewBackground addSubview:_pickerView];
        [_landUseBlock.superview.superview addSubview:_pickerViewBackground];
    } else [self hidePickers];
}

- (IBAction)datePickerShow:(UIGestureRecognizer *)sender {
    if (self.viewType == OTViewTypeView) return;
    if (![self isPickerClaimTypeShowing] && ![self isPickerLandUseShowing] && ![self isDatePickerShowing]) {
        [self dismissKeyboard];
        CGRect frame = _startDateBlock.textLabel.frame;
        
        _datePickerBackground = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, _startDateBlock.frame.origin.y + _startDateBlock.frame.size.height, frame.size.width, 150)];
        _datePickerBackground.layer.borderColor = [[UIColor otGreen] CGColor];
        _datePickerBackground.layer.borderWidth = 1;
        _datePickerBackground.layer.cornerRadius = 4.0f;
        _datePickerBackground.backgroundColor = [UIColor whiteColor];
        _datePickerBackground.alpha = 0.95;
        
        _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 150)];
        _datePickerShowing = YES;
        [_datePicker setDatePickerMode:UIDatePickerModeDate];
        [_datePicker addTarget:self action:@selector(datePickerChanged:) forControlEvents:UIControlEventValueChanged];
        
        // Đặt ngày của datePicker theo ngày của field
        NSDate *date = [[OT dateFormatter] dateFromString:_claim.startDate];
        if (date != nil)
            [_datePicker setDate:date];
        
        [_datePickerBackground addSubview:_datePicker];
        [_startDateBlock.superview.superview addSubview:_datePickerBackground];
    } else if ([self isPickerClaimTypeShowing])
        [self pickerClaimTypeDone:nil];
    else if ([self isPickerLandUseShowing])
        [self pickerLandUseDone:nil];
    else if ([self isDatePickerShowing])
        [self datePickerDone:nil];
}

- (IBAction)pickerClaimTypeDone:(id)sender {
    [_pickerViewBackground removeFromSuperview];
    _pickerClaimTypeShowing = NO;
}

- (IBAction)pickerLandUseDone:(id)sender {
    [_pickerViewBackground removeFromSuperview];
    _pickerLandUseShowing = NO;
}

- (IBAction)datePickerDone:(id)sender {
    [_datePickerBackground removeFromSuperview];
    _datePickerShowing = NO;
}

- (void)hidePickers {
    if ([self isPickerClaimTypeShowing])
        [self pickerClaimTypeDone:nil];
    else if ([self isPickerLandUseShowing])
        [self pickerLandUseDone:nil];
    else
        [self datePickerDone:nil];
}

#pragma handle UIDatePicker method

- (IBAction)datePickerChanged:(UIDatePicker *)sender {
    NSString *dateString = [[OT dateFormatter] stringFromDate:[sender date]];
    _startDateBlock.textLabel.attributedText = [OT getAttributedStringFromText:[dateString substringToIndex:10]];
    _claim.startDate = dateString;
}

#pragma mark - UIPickerViewDelegate methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"displayValue" ascending:YES];
    if ([self isPickerClaimTypeShowing]) {
        NSArray *options = [_claimTypeCollection sortedArrayUsingDescriptors:@[sortDescriptor]];
        ClaimType *claimType = [options objectAtIndex:row];
        
        _claim.claimType = claimType;
        
        _claimTypeBlock.textLabel.attributedText = [OT getAttributedStringFromText:claimType.displayValue];
    } else if ([self isPickerLandUseShowing]) {
        NSArray *options = [_landUseCollection sortedArrayUsingDescriptors:@[sortDescriptor]];
        LandUse *landUse = [options objectAtIndex:row];
        
        _claim.landUse = landUse;
        
        _landUseBlock.textLabel.attributedText = [OT getAttributedStringFromText:landUse.displayValue];
    }
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _claimTypeCollection.count;
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"displayValue" ascending:YES];
    if ([self isPickerClaimTypeShowing]) {
        NSArray *options = [_claimTypeCollection sortedArrayUsingDescriptors:@[sortDescriptor]];
        ClaimType *claimType = [options objectAtIndex:row];

        title = claimType.displayValue;
    } else if ([self isPickerLandUseShowing]) {
        NSArray *options = [_landUseCollection sortedArrayUsingDescriptors:@[sortDescriptor]];
        LandUse *landUse = [options objectAtIndex:row];
        
        title = landUse.displayValue;
    }
    
    return title;
}

- (void)showLandUsePicker {
//    if (self.viewType == OTViewTypeView) return;
//    [_pickerView setPickType:PickTypeList];
//    [_pickerView setPickItems:_landUseDisplayValue];
//    [_pickerView attachWithTextField:_landUseBlock.textField];
//    [_landUseBlock.textField becomeFirstResponder];
//    [_pickerView showPopOverList];
}

- (void)showStartDatePicker {
//    if (self.viewType == OTViewTypeView) return;
//    [_pickerView attachWithTextField:_startDateBlock.textField];
//    [_pickerView setPickType:PickTypeDate];
//    [_startDateBlock.textField becomeFirstResponder];
//    [_pickerView showPopOverList];
}

- (void)showClaimant {
    if (![self isPickerClaimTypeShowing] && ![self isPickerLandUseShowing] && ![self isDatePickerShowing]) {
        if (_claim.person == nil) {
            [self addPerson:nil];
        } else {
            [_claim.person setToTemporary];
            OTAppDelegate* appDelegate = (OTAppDelegate*)[[UIApplication sharedApplication] delegate];
            id main = appDelegate.window.rootViewController;
            UINavigationController *nav = [[main storyboard] instantiateViewControllerWithIdentifier:@"PersonTabBar"];
            if (nav != nil) {
                [self.navigationController presentViewController:nav animated:YES completion:nil];
            }
        }
    } else [self hidePickers];
}

- (void)showSelectChallenged {
    if (![self isPickerClaimTypeShowing] && ![self isPickerLandUseShowing] && ![self isDatePickerShowing]) {
        if (_claim.challenged != nil) {
            _claim.challenged = nil;
            _challengedBlock.imageView.image = _claim.challenged == nil ? [UIImage imageNamed:@"ic_action_add_claimant"] : [UIImage imageNamed:@"ic_action_remove_claimant"];
            NSString *challengedTitle = _claim.challenged != nil ? [_claim.challenged claimName] : NSLocalizedString(@"message_touch_to_select_a_claim", nil);
            _challengedBlock.textLabel.attributedText = [OT getAttributedStringFromText:challengedTitle];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:OTClaimSelectionAction] forKey:@"OTSelectionAction"];
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
    } else [self hidePickers];
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

@end
