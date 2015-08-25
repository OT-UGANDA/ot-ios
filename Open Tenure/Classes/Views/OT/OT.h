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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/*!
 Notifications key
 */
extern NSString * const kLoginSuccessNotificationName;
extern NSString * const kLogoutSuccessNotificationName;
extern NSString * const kGetAllClaimsSuccessNotificationName;
extern NSString * const kInitializedNotificationName;
extern NSString * const kMapZoomLevelNotificationName;
extern NSString * const kSetMainTabBarIndexNotificationName;
extern NSString * const kSetClaimTabBarIndexNotificationName;

extern NSString * const kResponseClaimsErrorNotificationName;
extern NSString * const kResponseClaimsMessageErrorKey;

extern NSString * const kWithdrawClaimSuccessNotificationName;
extern NSString * const kGetClaimSuccessNotificationName;
extern NSString * const kUpdateGeometryNotificationName;

/*!
 Claim status
 */
extern NSString * const kClaimStatusCreated;
extern NSString * const kClaimStatusUploading;
extern NSString * const kClaimStatusUnmoderated;
extern NSString * const kClaimStatusUpdating;
extern NSString * const kClaimStatusModerated;
extern NSString * const kClaimStatusChallenged;
extern NSString * const kClaimStatusUploadIncomplete;
extern NSString * const kClaimStatusUploadError;
extern NSString * const kClaimStatusUpdateIncomplete;
extern NSString * const kClaimStatusUpdateError;
extern NSString * const kClaimStatusWithdrawn;

// Attachment status
extern NSString * const kAttachmentStatusCreated;
extern NSString * const kAttachmentStatusUploading;
extern NSString * const kAttachmentStatusUploaded;
extern NSString * const kAttachmentStatusDeleted;
extern NSString * const kAttachmentStatusUploadIncomplete;
extern NSString * const kAttachmentStatusUploadError;
extern NSString * const kAttachmentStatusDownloadIncomplete;
extern NSString * const kAttachmentStatusDownloadFailed;
extern NSString * const kAttachmentStatusDownloading;


// Person kind
extern NSString * const kPersonTypePhysical;
extern NSString * const kPersonTypeGroup;

typedef NS_ENUM(NSInteger, OTSelectionAction) {
    OTClaimSelectionAction = 0,
    OTShareViewDetail
};

typedef NS_ENUM(NSInteger, OTViewType) {
    OTViewTypeView = 0,
    OTViewTypeEdit,
    OTViewTypeAdd
};

typedef NS_ENUM(NSInteger, OTFullNameType) {
    OTFullNameTypeDefault = 0,
    OTFullNameType1
};


@interface OT : NSObject

+ (void)handleError:(NSError *)error;
+ (void)handleErrorWithMessage:(NSString *)message;

+ (NSDateFormatter *)dateFormatter;

+ (UIBarButtonItem *)logoButtonWithTitle:(NSString *)title;

/*!
 Lấy mã ngôn ngữ hiện tại
 */
+ (NSString *)getLocalization;

/*!
 Cookies store
 */
+ (NSString *)getCookie;

/*!
 Cập nhật dữ liệu từ server khi lần đầu khởi động ứng dụng. Được gọi từ OTAppDelegate
 */
+ (void)updateIdType;
+ (void)updateLandUse;
+ (void)updateClaimType;
+ (void)updateDocumentType;
+ (void)updateDefaultFormTemplate;
+ (void)updateCommunityArea;
+ (void)updateParcelGeomRequired;

/*!
 Lưu và lấy ra trạng thái khởi tạo
 */
+ (BOOL)getInitialized;

+ (void)setUpdatedIdType:(BOOL)state;
+ (BOOL)getUpdatedIdType;
+ (void)setUpdatedLandUse:(BOOL)state;
+ (BOOL)getUpdatedLandUse;
+ (void)setUpdatedClaimType:(BOOL)state;
+ (BOOL)getUpdatedClaimType;
+ (void)setUpdatedDocumentType:(BOOL)state;
+ (BOOL)getUpdatedDocumentType;
+ (void)setUpdatedDefaultFormTemplate:(BOOL)state;
+ (BOOL)getUpdatedDefaultFormTemplate;
+ (void)setUpdatedCommunityArea:(BOOL)state;
+ (BOOL)getUpdatedCommunityArea;

+ (void)login;

+ (NSAttributedString *)getAttributedStringFromText:(NSString *)text;

/*!
 Xác định control cho UIBarbuttonItem dùng cho showcase
 */
+ (UIControl *)findBarButtonItem:(UIBarButtonItem *)barButtonItem fromNavBar:(UINavigationBar *)toolbar;

@end
