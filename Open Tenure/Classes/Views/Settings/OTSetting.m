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

#import "OTSetting.h"

@implementation OTSetting

+ (NSString *)getCommunityServerURL {
    NSString *url = [[NSUserDefaults standardUserDefaults] stringForKey:@"CommunityServerURL"];
    if (url == nil) url = @"https://ot.flossola.org";
    return url;
}

+ (void)setCommunityServerURL:(NSString *)url {
    [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"CommunityServerURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)getGeoServerURL {
    NSString *url = [[NSUserDefaults standardUserDefaults] stringForKey:@"GeoServerURL"];
    if (url == nil) url = @"http://demo.flossola.org/geoserver/sola";
    return url;
}

+ (void)setGeoServerURL:(NSString *)url {
    [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"GeoServerURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)getGeoServerLayers {
    NSString *layer = [[NSUserDefaults standardUserDefaults] stringForKey:@"GeoServerLayers"];
    if (layer == nil) layer = @"sola:nz_orthophoto";
    return layer;
}

+ (void)setGeoServerLayers:(NSString *)layers {
    [[NSUserDefaults standardUserDefaults] setObject:layers forKey:@"GeoServerLayers"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)getFormURL {
    NSString *url = [[NSUserDefaults standardUserDefaults] stringForKey:@"FormURL"];
    if (url == nil) url = @"https://ot.flossola.org";
    return url;
}

+ (void)setFormURL:(NSString *)url {
    [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"FormURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)getWMSVersion {
    NSString *wmsVersion = [[NSUserDefaults standardUserDefaults] stringForKey:@"WMSVersion"];
    if (wmsVersion == nil) wmsVersion = @"1.1.0";
    return wmsVersion;
}

+ (void)setWMSVersion:(NSString *)wmsVersion {
    [[NSUserDefaults standardUserDefaults] setObject:wmsVersion forKey:@"WMSVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)getCommunityArea {
    NSString *communityArea = [[NSUserDefaults standardUserDefaults] stringForKey:@"CommunityArea"];
    return communityArea;
}

+ (void)setCommunityArea:(NSString *)communityArea {
    [[NSUserDefaults standardUserDefaults] setObject:communityArea forKey:@"CommunityArea"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getInitialization {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"initialized"];
}

+ (void)setInitialization:(BOOL)initialized {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:initialized] forKey:@"initialized"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (void)setReInitialization:(BOOL)state {
    if (state) {
        // Xóa các thiết lập
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:state] forKey:@"ReInitialization"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getReInitialization {
    BOOL state = [[NSUserDefaults standardUserDefaults] boolForKey:@"ReInitialization"];
    if (state) {
        // Xóa dữ liệu
        NSURL *storeURL = [[FileSystemUtilities applicationHiddenDocumentsDirectory] URLByAppendingPathComponent:@"OpenTenure.sqlite"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
            NSError *error;
            if (![[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]) {
                ALog(@"Error: %@", error.localizedDescription);
            } else {
                [OTSetting setReInitialization:NO];
                ALog(@"ReInitialized");
            }
        }
        // Xóa các tài nguyên
        [FileSystemUtilities deleteDocumentsFolder];
    }
    return state;
}

@end
