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

#import "OTTileOverlay.h"
#import "OTSetting.h"

@interface OTTileOverlay ()

@property (strong, nonatomic) NSString *tilesDirectory;
@property (assign, nonatomic, getter=isOverride) BOOL override;

@end

@implementation OTTileOverlay

- (instancetype)initWithWMSURL:(NSString *)wmsURL override:(BOOL)override {
    if (self = [super initWithURLTemplate:wmsURL]) {
        self.override = override;
        NSString *requestString = @"GetMap";
        NSString *versionString = [OTSetting getWMSVersion];
        NSString *layersString = [OTSetting getGeoServerLayers];
        NSString *formatString = @"image/png";
        NSString *srsString = @"EPSG:900913";
        NSString *serviceString = @"WMS";
        NSString *stylesString = @"";
        
        NSString *request = [NSString stringWithFormat:@"/wms?request=%@", requestString];
        NSString *version = [NSString stringWithFormat:@"&version=%@", versionString];
        NSString *layers = [NSString stringWithFormat:@"&layers=%@", layersString];
        NSString *format = [NSString stringWithFormat:@"&format=%@", formatString];
        NSString *srs = [NSString stringWithFormat:@"&srs=%@", srsString];
        NSString *service = [NSString stringWithFormat:@"&service=%@", serviceString];
        NSString *styles = [NSString stringWithFormat:@"&styles=%@", stylesString];
        
        urlTilePathParams.request = malloc(sizeof(char) * request.length + 1);
        urlTilePathParams.version = malloc(sizeof(char) * version.length + 1);
        urlTilePathParams.layers = malloc(sizeof(char) * layers.length + 1);
        urlTilePathParams.format = malloc(sizeof(char) * format.length + 1);
        urlTilePathParams.srs = malloc(sizeof(char) * srs.length + 1);
        urlTilePathParams.service = malloc(sizeof(char) * service.length + 1);
        urlTilePathParams.styles = malloc(sizeof(char) * styles.length + 1);
        
        strcpy(urlTilePathParams.request, [request UTF8String]);
        strcpy(urlTilePathParams.version, [version UTF8String]);
        strcpy(urlTilePathParams.layers, [layers UTF8String]);
        strcpy(urlTilePathParams.format, [format UTF8String]);
        strcpy(urlTilePathParams.srs, [srs UTF8String]);
        strcpy(urlTilePathParams.service, [service UTF8String]);
        strcpy(urlTilePathParams.styles, [styles UTF8String]);
        
        layersString = [layersString stringByReplacingOccurrencesOfString:@":" withString:@"-"];
        _tilesDirectory = [[self tilesDirectoryForLayers:layersString] path];
    }
    return self;
}

- (NSURL *)URLForTilePath:(MKTileOverlayPath)path {
    CGFloat n0 = M_PI - 2.0 * M_PI * path.y / pow(2.0, path.z);
    CGFloat n1 = M_PI - 2.0 * M_PI * (path.y + 1) / pow(2.0, path.z);
    
    CLLocationDegrees lonLeft = path.x / pow(2.0, path.z) * 360.0 - 180.0;
    CLLocationDegrees lonRight = (path.x + 1)/ pow(2.0, path.z) * 360.0 - 180.0;
    CLLocationDegrees latTop = 180.0 / M_PI * atan(0.5 * (exp(n0) - exp(-n0)));
    CLLocationDegrees latBottom = 180.0 / M_PI * atan(0.5 * (exp(n1) - exp(-n1)));
    
    // To Mercator
    CGFloat x0 = lonLeft * 20037508.34 / 180.0;
    CGFloat x1 = lonRight * 20037508.34 / 180.0;
    CGFloat y1 = (log(tan((90 + latTop) * M_PI / 360)) / (M_PI / 180)) * 20037508.34 / 180.0;
    CGFloat y0 = (log(tan((90 + latBottom) * M_PI / 360)) / (M_PI / 180)) * 20037508.34 / 180.0;
    
    NSString *bbox = [NSString stringWithFormat:@"&bbox=%f,%f,%f,%f", x0, y0, x1, y1];
    urlTilePathParams.bbox = malloc(sizeof(char) * bbox.length + 1);
    strcpy(urlTilePathParams.bbox, [bbox UTF8String]);
    
    CGSize tileSize = self.tileSize;
    //tileSize.height *= path.contentScaleFactor;
    //tileSize.width *= path.contentScaleFactor;
    NSString *size = [NSString stringWithFormat:@"&width=%d&height=%d", (int)tileSize.width, (int)tileSize.height];
    
    urlTilePathParams.size = malloc(sizeof(char) * size.length + 1);
    strcpy(urlTilePathParams.size, [size UTF8String]);
    
    NSString *urlString = [NSString stringWithFormat:@"%@%s%s%s%s%s%s%s%s%s",
                           self.URLTemplate,
                           urlTilePathParams.request,
                           urlTilePathParams.version,
                           urlTilePathParams.layers,
                           urlTilePathParams.format,
                           urlTilePathParams.srs,
                           urlTilePathParams.service,
                           urlTilePathParams.styles,
                           urlTilePathParams.bbox,
                           urlTilePathParams.size];
    
    return [NSURL URLWithString:urlString];
}

- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *, NSError *))result {
    NSURL *url = [self URLForTilePath:path];
    NSString *tileFilePath = [self getTileFilePathForTilePath:path];

    if (![self isOverride] && ![self isDownloading]) { // Local
        // Kiểm tra nếu tile file đang tồn tại
        ALog(@"Load file %@", tileFilePath);
        if ([[NSFileManager defaultManager] fileExistsAtPath:tileFilePath]) {
            NSData *tileData = [NSData dataWithContentsOfFile:tileFilePath];
            result(tileData, nil);
        } else {
            result(nil, nil);
        }
    } else if (![self isDownloading]) { // Luôn luôn tải về bản mới và ghi đè
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        ALog(@"%@", url.relativeString);
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   if (error) {
                                       NSLog(@"Error downloading tile ! \n");
                                       result(nil, error);
                                   }
                                   else {
                                       [self createTileFilePathForTilePath:path];
                                       [data writeToFile:tileFilePath atomically:YES];
                                       result(data, nil);
                                   }
                               }];
    } else { // Download
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        if ([[NSFileManager defaultManager] fileExistsAtPath:tileFilePath]) return;
        ALog(@"Downloading %@", url.relativeString);
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   if (error) {
                                       NSLog(@"Error downloading tile ! \n");
                                   }
                                   else {
                                       [self createTileFilePathForTilePath:path];
                                       [data writeToFile:tileFilePath atomically:YES];
                                   }
                               }];
    }
}

/**
 *
 * Returns the path to the application's tiles directory:
 * layer/version
 *
 * **/

- (NSURL *)tilesDirectoryForLayers:(NSString *)layers {

    BOOL isDirectory = NO;
    NSError *error = nil;
    
    NSURL *appDocsUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    NSURL *tilesUrl = [appDocsUrl URLByAppendingPathComponent:MAP_TILES];
    NSURL *layersUrl = [tilesUrl URLByAppendingPathComponent:layers];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tilesUrl.path isDirectory:&isDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:tilesUrl.path
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
            [NSException raise:@"Failed creating directory" format:@"[%@], %@", tilesUrl, error];
        }
    } else if (!isDirectory) {
        [NSException raise:@".data exists, and is a file" format:@"Path: %@", tilesUrl];
    }
    
    isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:layersUrl.path isDirectory:&isDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:layersUrl.path
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
            [NSException raise:@"Failed creating directory" format:@"[%@], %@", layersUrl, error];
        }
    } else if (!isDirectory) {
        [NSException raise:@".data exists, and is a file" format:@"Path: %@", layersUrl];
    }

    return layersUrl;
}

- (NSString *)getTileFilePathForTilePath:(MKTileOverlayPath)path {
    NSString *tileFilePath = [NSString stringWithFormat:@"%@/%tu/%tu/%tu.png",
                              _tilesDirectory,
                              path.z,
                              path.x,
                              path.y];
    return tileFilePath;
}

- (void)createTileFilePathForTilePath:(MKTileOverlayPath)path {
    NSString *zPath = [NSString stringWithFormat:@"%@/%tu", _tilesDirectory, path.z];
    NSString *xPath = [NSString stringWithFormat:@"%@/%tu/%tu", _tilesDirectory, path.z, path.x];
    [FileSystemUtilities createFolder:zPath];
    [FileSystemUtilities createFolder:xPath];
}

@end
