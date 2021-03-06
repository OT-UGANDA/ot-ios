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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OTOMTPType) {
    WTMS = 0,
    TMS,
    GeoServer
};

@interface OTSetting : NSObject

+ (NSString *)getAppVersion;

+ (NSString *)getCommunityServerURL;
+ (void)setCommunityServerURL:(NSString *)url;

+ (NSString *)getGeoServerWMSURL;
+ (NSString *)getGeoServerURL;
+ (void)setGeoServerURL:(NSString *)url;

+ (NSString *)getGeoServerLayers;
+ (void)setGeoServerLayers:(NSString *)layers;

+ (NSString *)getFormURL;
+ (void)setFormURL:(NSString *)url;

+ (OTOMTPType)getOMTPType;
+ (void)setOMTPType:(OTOMTPType)omtpType;

+ (NSString *)getTMSURL;
+ (void)setTMSURL:(NSString *)url;

+ (NSString *)getOfflineMapURL;

+ (NSString *)getWTMSURL;
+ (void)setWTMSURL:(NSString *)url;

+ (NSString *)getWMSVersion;
+ (void)setWMSVersion:(NSString *)wmsVersion;

+ (NSString *)getCommunityArea;
+ (void)setCommunityArea:(NSString *)communityArea;

+ (BOOL)getParcelGeomRequired;
+ (void)setParcelGeomRequired:(BOOL)required;

+ (BOOL)getInitialization;
+ (void)setInitialization:(BOOL)initialized;

/*!
 Export log
 */
+ (void)preparingExportLog;
+ (void)exportLog;

/*!
 Lưu và lấy trạng thái thiết lập mới (xóa toàn bộ dữ liệu)
 */
+ (void)setReInitialization:(BOOL)state;
+ (BOOL)getReInitialization;

@end
