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

#import "OTWMSTileOverlay.h"

@interface OTWMSTileOverlay () {
    // array indexes for array to hold bounding boxes.
    int MINX;
    int MINY;
    int MAXX;
    int MAXY;
    
    // array indexes for array to hold tile x y.
    int X;
    int Y;
    
    // array indexes for array to hold tile x y.
    int NORTH_EAST_X;
    int NORTH_EAST_Y;
    int SOUTH_WEST_X;
    int SOUTH_WEST_Y;
    
    // Web Mercator upper left corner of the world map.
    double TILE_ORIGIN[2];
    
    //array indexes for that data
    int ORIG_X;
    int ORIG_Y;
    
    // Size of square world map in meters, using WebMerc projection.
    double MAP_SIZE;
    NSString *version;
    NSString *request;
    NSString *format;
    NSString *srs;
    NSString *service;
    NSString *styles;
    NSString *URL_STRING;
}

@end

@implementation OTWMSTileOverlay

#pragma mark - Overides
- (id)init {
    if (self = [super init]) {
        TILE_ORIGIN[0] = -20037508.34789244;
        TILE_ORIGIN[1] = 20037508.34789244;
        
        //array indexes for that data
        ORIG_X = 0;
        ORIG_Y = 1;
        
        // Size of square world map in meters, using WebMerc projection.
        MAP_SIZE = 20037508.34789244 * 2.0f;
        
        // array indexes for array to hold bounding boxes.
        MINX = 0;
        MINY = 1;
        MAXX = 2;
        MAXY = 3;
        
        // array indexes for array to hold tile x y.
        X = 0;
        Y = 1;
        
        // array indexes for array to hold tile x y.
        NORTH_EAST_X = 0;
        NORTH_EAST_Y = 1;
        SOUTH_WEST_X = 2;
        SOUTH_WEST_Y = 3;
        
        version = @"1.1.0";
        request = @"GetMap";
        format = @"image/png";
        srs = [@"EPSG:" stringByAppendingString:SRID];
        service = @"WMS";
        styles = @"";
    }
    return self;
}

- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *data, NSError *error))result {
    if (!result) return;
    NSString *filePath = [self filePathForTilePath:path];
    NSPurgeableData *cachedData = [NSPurgeableData dataWithContentsOfFile:filePath];
    if (cachedData) {
        result([NSData dataWithData:cachedData], nil);
    } else if ([self isGeoServerWMS]) {
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[self URLForTilePath:path] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20];
        [NSURLConnection sendAsynchronousRequest:urlRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
             NSPurgeableData *cachedData = nil;
             if (data) {
                 cachedData = [NSPurgeableData dataWithData:data];
                 [cachedData writeToFile:filePath atomically:YES];
             }
             result(data, connectionError);
         }];
    }
}


#pragma mark - Custom for WMS
- (id)initWithWMSUrlString:(NSString *)urlString tileSize:(CGSize)tileSize {
    if (self = [self init]) {
        if ([self URLTemplate] == nil) {
            URL_STRING  = [urlString stringByAppendingString:[NSString stringWithFormat:@"&width=%tu&height=%tu", (long)tileSize.width, (long)tileSize.height]];
            URL_STRING = [URL_STRING stringByAppendingString:@"&bbox=%f,%f,%f,%f"];
            self.geoServerWMS = YES;
        }
    }
    return self;
}

- (instancetype)initWithURLTemplate:(NSString *)URLTemplate {
    if (self = [super initWithURLTemplate:URLTemplate]) {
        URL_STRING = [self URLTemplate];
    }
    return self;
}

- (BBOX)bboxForPath:(MKTileOverlayPath)path {
    BBOX bbox;
    CGFloat tileSize = MAP_SIZE / pow(2.0f, path.z);
    CGFloat minx = TILE_ORIGIN[ORIG_X] + path.x * tileSize;
    CGFloat maxx = TILE_ORIGIN[ORIG_X] + (path.x+1) * tileSize;
    CGFloat miny = TILE_ORIGIN[ORIG_Y] - (path.y+1) * tileSize;
    CGFloat maxy = TILE_ORIGIN[ORIG_Y] - path.y * tileSize;
    bbox.minx = minx;
    bbox.miny = miny;
    bbox.maxx = maxx;
    bbox.maxy = maxy;
    return bbox;
}

- (NSURL *)URLForTilePath:(MKTileOverlayPath)path {
    NSString *urlString;
    if ([self URLTemplate] == nil) {
        BBOX bbox = [self bboxForPath:path];
        urlString = [NSString stringWithFormat:URL_STRING, bbox.minx, bbox.miny, bbox.maxx, bbox.maxy];
    } else
        return [super URLForTilePath:path];
    return [NSURL URLWithString:urlString];
}

- (TILE)getXYForNorthEast:(CLLocationCoordinate2D)northeast southWest:(CLLocationCoordinate2D)southwest zoom:(int)zoom {
    double tileSize = MAP_SIZE / pow(2.0f, zoom);
    TILE tile;
    tile.NORTH_EAST_X = (int)((northeast.longitude - TILE_ORIGIN[ORIG_X]) / tileSize);
    tile.NORTH_EAST_Y = -(int)((northeast.latitude - TILE_ORIGIN[ORIG_Y]) / tileSize);
    tile.SOUTH_WEST_X = (int)((southwest.longitude - TILE_ORIGIN[ORIG_X]) / tileSize);
    tile.SOUTH_WEST_Y = -(int)((southwest.latitude - TILE_ORIGIN[ORIG_Y]) / tileSize);
    return tile;
}

- (NSArray *)tilesForNorthEast:(CLLocationCoordinate2D)neCoord southWest:(CLLocationCoordinate2D)swCoord startZoom:(int)startZoom endZoom:(int)endZoom canReplace:(BOOL)canReplace {
    NSMutableArray *tiles = [NSMutableArray array];
    POINT northeast = TileOfCoordinate(neCoord, startZoom);
    POINT southwest = TileOfCoordinate(swCoord, startZoom);
    for(int zoom = startZoom ; zoom <= endZoom; zoom++) {
        for(int x = southwest.x ; x <= northeast.x ; x++) {
            for(int y = northeast.y ; y <= southwest.y ; y++) {
                MKTileOverlayPath path;
                path.x = x;
                path.y = y;
                path.z = zoom;
                NSURL *sourceUrl = [self URLForTilePath:path];
                NSURL *destinationUrl = [NSURL URLWithString:[self filePathForTilePath:path]];
                if (![[NSFileManager defaultManager] fileExistsAtPath:[destinationUrl path]] || canReplace) {
                    [tiles addObject:@{@"sourceUrl":sourceUrl, @"destinationUrl":destinationUrl}];
                }
            }
        }
        // At each subsequent level of zoom, tiles indexes double
        northeast.x *= 2;
        northeast.y *= 2;
        southwest.x *= 2;
        southwest.y *= 2;
    }
    return tiles;
}

- (NSString *)filePathForTilePath:(MKTileOverlayPath)path {
    NSString *tilesRoot = [[[FileSystemUtilities applicationDocumentsDirectory] path] stringByAppendingPathComponent:MAP_TILES];
    [FileSystemUtilities createDirectoryAtURL:[NSURL fileURLWithPath:tilesRoot isDirectory:YES]];
    
    NSString *tilesFolder = [tilesRoot stringByAppendingPathComponent:URL_STRING.md5];
    [FileSystemUtilities createDirectoryAtURL:[NSURL fileURLWithPath:tilesFolder isDirectory:YES]];
    
    NSString *zPath = [NSString stringWithFormat:@"%@/%tu", tilesFolder, path.z];
    NSString *xPath = [NSString stringWithFormat:@"%@/%tu/%tu", tilesFolder, path.z, path.x];
    [FileSystemUtilities createDirectoryAtURL:[NSURL fileURLWithPath:zPath isDirectory:YES]];
    [FileSystemUtilities createDirectoryAtURL:[NSURL fileURLWithPath:xPath isDirectory:YES]];
    
    NSString *filePath = [NSString stringWithFormat:@"%tu/%tu/%tu.png", path.z, path.x, path.y];
    return [tilesFolder stringByAppendingPathComponent:filePath];
}

@end
