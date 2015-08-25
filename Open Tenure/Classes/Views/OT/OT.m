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
#import "OT.h"

NSString * const kLoginSuccessNotificationName = @"LoginSuccessNotificationName";
NSString * const kLogoutSuccessNotificationName = @"LogoutSuccessNotificationName";
NSString * const kGetAllClaimsSuccessNotificationName = @"GetAllClaimsSuccessNotificationName";
NSString * const kInitializedNotificationName = @"InitializedNotificationName";
NSString * const kMapZoomLevelNotificationName = @"MapZoomLevelNotificationName";
NSString * const kSetMainTabBarIndexNotificationName = @"SetMainTabBarIndexNotificationName";
NSString * const kSetClaimTabBarIndexNotificationName = @"SetClaimTabBarIndexNotificationName";

NSString * const kResponseClaimsErrorNotificationName = @"ResponseClaimsErrorNotificationName";
NSString * const kResponseClaimsMessageErrorKey = @"ResponseClaimsMessageErrorKey";

NSString * const kWithdrawClaimSuccessNotificationName = @"WithdrawClaimSuccessNotificationName";
NSString * const kGetClaimSuccessNotificationName = @"GetClaimSuccessNotificationName";
NSString * const kUpdateGeometryNotificationName = @"UpdateGeometryNotificationName";

NSString * const kClaimStatusCreated = @"created";
NSString * const kClaimStatusUploading = @"uploading";
NSString * const kClaimStatusUnmoderated = @"unmoderated";
NSString * const kClaimStatusUpdating = @"updating";
NSString * const kClaimStatusModerated = @"moderated";
NSString * const kClaimStatusChallenged = @"challenged";
NSString * const kClaimStatusUploadIncomplete = @"upload_incomplete";
NSString * const kClaimStatusUploadError = @"upload_error";
NSString * const kClaimStatusUpdateIncomplete = @"update_incomplete";
NSString * const kClaimStatusUpdateError = @"update_error";
NSString * const kClaimStatusWithdrawn = @"withdrawn";

NSString * const kAttachmentStatusCreated = @"created";
NSString * const kAttachmentStatusUploading = @"uploading";
NSString * const kAttachmentStatusUploaded = @"uploaded";
NSString * const kAttachmentStatusDeleted = @"deleted";
NSString * const kAttachmentStatusUploadIncomplete = @"upload_incomplete";
NSString * const kAttachmentStatusUploadError = @"upload_error";
NSString * const kAttachmentStatusDownloadIncomplete = @"download_incomplete";
NSString * const kAttachmentStatusDownloadFailed = @"download_failed";
NSString * const kAttachmentStatusDownloading = @"downloading";

@implementation OT

+ (void)handleError:(NSError *)error {
    NSString *errorMessage = [error localizedDescription];
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showErrorWithStatus:errorMessage];
    });
}

+ (void)handleErrorWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
       [SVProgressHUD showErrorWithStatus:message];
    });
}

+ (NSDateFormatter *)dateFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
//    [dateFormatter setTimeZone:gmt];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];
    return dateFormatter;
}

+ (UIBarButtonItem *)logoButtonWithTitle:(NSString *)title {
    CGSize size = CGSizeZero;
    CGFloat fontSize = 19.0f;
    if ([[self getLocalization] isEqualToString:@"km"]) {
        // Khmer Sangam MN
        size = [title sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Khmer Sangam MN" size:fontSize]}];
    } else {
        size = [title sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]}];
    }
    UIImage *logoImage = [UIImage imageNamed:@"sola_logo"];
    CGRect rect = CGRectMake(0, 0, size.width + logoImage.size.width, logoImage.size.height);
    UIButton *logoButton = [[UIButton alloc] initWithFrame:rect];
    logoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [logoButton setImage:logoImage forState:UIControlStateNormal];
    [logoButton setTitle:title forState:UIControlStateNormal];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:logoButton];
    return button;
}

+ (NSString *)getLocalization {
    NSArray *languages = @[@"en-us", @"ru-ru", @"ar-jo", @"fr-fr", @"es-es", @"sq-al", @"pt-br", @"km-kh", @"zh-cn"];
    NSString *key = [[[NSBundle mainBundle] preferredLocalizations] firstObject];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", key];
    NSString *value = [[languages filteredArrayUsingPredicate:predicate] firstObject];
    if (value != nil) return value;
    return @"en-us";
}

+ (NSString *)getCookie {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    return [[NSHTTPCookie requestHeaderFieldsWithCookies:[cookieStorage cookies]] objectForKey:@"Cookie"];
}

+ (void)updateIdType {
    [CommunityServerAPI getIdTypesWithCompletionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSMutableArray *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    for (NSDictionary *object in objects) {
                        IdType *idType = [IdTypeEntity getIdTypeByCode:[object objectForKey:@"code"]];
                        if (idType == nil) {
                            idType = [IdTypeEntity create];
                            [idType importFromJSON:object];
                        }
                    }
                    if (objects.count > 0)
                        [self setUpdatedIdType:YES];
                    saveDataContext;
                }
            } else {
                NSString *errorString = NSLocalizedStringFromTable(@"error_generic_conection", @"ActivityLogin", nil);
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

+ (void)updateLandUse {
    [CommunityServerAPI getLandUsesWithCompletionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSMutableArray *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    for (NSDictionary *object in objects) {
                        LandUse *landUse = [LandUseEntity getLandUseByCode:[object objectForKey:@"code"]];
                        if (landUse == nil) {
                            landUse = [LandUseEntity create];
                            [landUse importFromJSON:object];
                        }
                    }
                    if (objects.count > 0)
                        [self setUpdatedLandUse:YES];
                    saveDataContext;
                }
            } else {
                NSString *errorString = NSLocalizedStringFromTable(@"error_generic_conection", @"ActivityLogin", nil);
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

+ (void)updateClaimType {
    [CommunityServerAPI getClaimTypesWithCompletionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSMutableArray *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    for (NSDictionary *object in objects) {
                        ClaimType *claimType = [ClaimTypeEntity getClaimTypeByCode:[object objectForKey:@"code"]];
                        if (claimType == nil) {
                            claimType = [ClaimTypeEntity create];
                            [claimType importFromJSON:object];
                        }
                    }
                    if (objects.count > 0)
                        [self setUpdatedClaimType:YES];
                    saveDataContext;
                }
            } else {
                NSString *errorString = NSLocalizedStringFromTable(@"error_generic_conection", @"ActivityLogin", nil);
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

+ (void)updateDocumentType {
    [CommunityServerAPI getDocumentTypesWithCompletionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSMutableArray *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    for (NSDictionary *object in objects) {
                        DocumentType *docType = [DocumentTypeEntity getDocTypeByCode:[object objectForKey:@"code"]];
                        if (docType == nil) {
                            docType = [DocumentTypeEntity create];
                            [docType importFromJSON:object];
                        }
                    }
                    if (objects.count > 0)
                        [self setUpdatedDocumentType:YES];
                    saveDataContext;
                }
            } else {
                NSString *errorString = NSLocalizedStringFromTable(@"error_generic_conection", @"ActivityLogin", nil);
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

+ (void)updateDefaultFormTemplate {
    [CommunityServerAPI getDefaultFormTemplate:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSDictionary *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    if (objects.count > 0) {
                        FormTemplate *formTepplate = [FormTemplateEntity getEntityByName:[objects objectForKey:@"name"]];
                        if (formTepplate == nil)
                            formTepplate = [FormTemplateEntity createObject];
                        
                            [formTepplate importFromJSON:objects];
                        saveDataContext;
                    }
                    [self setUpdatedDefaultFormTemplate:YES];
                }
            } else {
                NSString *errorString = NSLocalizedStringFromTable(@"error_generic_conection", @"ActivityLogin", nil);
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

+ (void)updateCommunityArea {
    [CommunityServerAPI getCommunityArea:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSMutableArray *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    NSString *communityArea = [objects valueForKey:@"result"];
                    if (![communityArea isEqualToString:[OTSetting getCommunityArea]])
                        [OTSetting setCommunityArea:communityArea];
                    [self setUpdatedCommunityArea:YES];
                }
            } else {
                NSString *errorString = NSLocalizedStringFromTable(@"error_generic_conection", @"ActivityLogin", nil);
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

+ (void)updateParcelGeomRequired {
    [CommunityServerAPI getParcelGeomRequired:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSDictionary *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    BOOL parcelGeomRequired = [[objects valueForKey:@"result"] boolValue];
                    [OTSetting setParcelGeomRequired:parcelGeomRequired];
                }
            } else {
                NSString *errorString = NSLocalizedStringFromTable(@"error_generic_conection", @"ActivityLogin", nil);
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

+ (void)login {
    if ([OTAppDelegate authenticated]) {
        // Logout
        [SVProgressHUD show];
        [CommunityServerAPI logoutWithCompletionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
            if (error != nil) {
                [OT handleError:error];
            } else {
                if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedStringFromTable(@"message_logout_ok", @"ActivityLogin", nil)];
                    // Clear session
                    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                    for (NSHTTPCookie *cookie in [cookieStorage cookies])
                        [cookieStorage deleteCookie:cookie];
                    [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] setUserName:nil];
                    [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] setAuthenticated:NO];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutSuccessNotificationName object:self userInfo:nil];
                } else {
                    NSString *errorString = NSLocalizedStringFromTable(@"error_generic_conection", @"ActivityLogin", nil);
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                    NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                               code:[httpResponse statusCode]
                                                           userInfo:userInfo];
                    [OT handleError:reportError];
                }
            }
        }];
    } else {
        // Login        
        [UIAlertView showWithTitle:NSLocalizedString(@"app_name", nil) message:nil style:UIAlertViewStyleLoginAndPasswordInput cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedStringFromTable(@"action_sign_in_short", @"ActivityLogin", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != [alertView cancelButtonIndex]) {
                [SVProgressHUD showWithStatus:NSLocalizedStringFromTable(@"login_progress_signing_in", @"ActivityLogin", nil)];
                [CommunityServerAPI loginWithUsername:[[alertView textFieldAtIndex:0] text] andPassword:[[alertView textFieldAtIndex:1] text] completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
                    if (error != nil) {
                        [OT handleError:error];
                    } else {
                        if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                            [SVProgressHUD showSuccessWithStatus:NSLocalizedStringFromTable(@"message_login_ok", @"ActivityLogin", nil)];
                            
                            // Store session
                            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:[NSHTTPCookie cookieWithProperties:[httpResponse allHeaderFields]]];
                            [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] setUserName:[[alertView textFieldAtIndex:0] text]];
                            [(OTAppDelegate *)[[UIApplication sharedApplication] delegate] setAuthenticated:YES];
                            [[NSNotificationCenter defaultCenter] postNotificationName:kLoginSuccessNotificationName object:self userInfo:nil];
                        } else {
                            NSString *errorString = NSLocalizedStringFromTable(@"error_generic_conection", @"ActivityLogin", nil);
                            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                            [OT handleError:[NSError errorWithDomain:@"HTTP"
                                                                code:[httpResponse statusCode]
                                                            userInfo:userInfo]];
                        }
                    }
                }];
            }
        }];
    }
}

+ (BOOL)getInitialized {    
    //Create folder
    BOOL success = YES;
    if (![OT getUpdatedIdType]) success = NO;
    if (![OT getUpdatedLandUse]) success = NO;
    if (![OT getUpdatedClaimType]) success = NO;
    if (![OT getUpdatedDocumentType]) success = NO;
    if (![OT getUpdatedDefaultFormTemplate]) success = NO;
    if (![OT getUpdatedCommunityArea]) success = NO;
    return success;
}

+ (void)setUpdatedIdType:(BOOL)state {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:state] forKey:@"UpdatedIdType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getUpdatedIdType {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"UpdatedIdType"];
}

+ (void)setUpdatedLandUse:(BOOL)state {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:state] forKey:@"UpdatedLandUse"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getUpdatedLandUse {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"UpdatedLandUse"];
}

+ (void)setUpdatedClaimType:(BOOL)state {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:state] forKey:@"UpdatedClaimType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getUpdatedClaimType {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"UpdatedClaimType"];
}

+ (void)setUpdatedDocumentType:(BOOL)state {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:state] forKey:@"UpdatedDocumentType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getUpdatedDocumentType {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"UpdatedDocumentType"];
}

+ (void)setUpdatedDefaultFormTemplate:(BOOL)state {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:state] forKey:@"UpdatedDefaultFormTemplate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getUpdatedDefaultFormTemplate {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"UpdatedDefaultFormTemplate"];
}

+ (void)setUpdatedCommunityArea:(BOOL)state {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:state] forKey:@"UpdatedCommunityArea"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getUpdatedCommunityArea {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"UpdatedCommunityArea"];
}

+ (NSAttributedString *)getAttributedStringFromText:(NSString *)text {
    if (text == nil) return nil;
    NSMutableParagraphStyle *style =  [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSTextAlignmentLeft;
    style.firstLineHeadIndent = 5.0f;
    style.headIndent = 5.0f;
    style.tailIndent = -5.0f;
    NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:text
                                                                   attributes:@{ NSParagraphStyleAttributeName:style}];
    return attrText;
}

+ (UIControl *)findBarButtonItem:(UIBarButtonItem *)barButtonItem fromNavBar:(UINavigationBar *)toolbar {
    UIControl *button = nil;
    for (UIView *subview in toolbar.subviews) {
        if ([subview isKindOfClass:[UIControl class]]) {
            for (id target in [(UIControl *)subview allTargets]) {
                if (target == barButtonItem) {
                    button = (UIControl *)subview;
                    break;
                }
            }
            if (button != nil) break;
        }
    }
    return button;
}

@end
