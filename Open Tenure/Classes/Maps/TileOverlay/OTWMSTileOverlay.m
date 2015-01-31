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

#define MAP_TILES   @"MapTiles"
#define SRID        @"900913"
#define TO_RADIANS  M_PI/180.0f
#define TO_DEGREES  180.0f/M_PI

typedef struct {
    CGFloat minx;
    CGFloat miny;
    CGFloat maxx;
    CGFloat maxy;
} BBOX;

typedef struct {
    int NORTH_EAST_X;
    int NORTH_EAST_Y;
    int SOUTH_WEST_X;
    int SOUTH_WEST_Y;
} TILE;

typedef struct {
    int x;
    int y;
} POINT;

typedef struct {
    CLLocationCoordinate2D northeast;
    CLLocationCoordinate2D southwest;
} LatLngBounds;

NS_INLINE double MercatorFromLatitude(CLLocationDegrees latitude) {
    double radians = log(tan(TO_RADIANS*(latitude+90.0f)/2.0f));
    double mercator = TO_DEGREES*radians;
    return mercator;
}

NS_INLINE POINT TileOfCoordinate(CLLocationCoordinate2D coord, int zoom) {
    POINT result;
    int noTiles = (1 << zoom);
    double longitudeSpan = 360.0 / noTiles;
    result.x = (int)((coord.longitude +180.0)/longitudeSpan);
    result.y = -(int)((noTiles * (MercatorFromLatitude(coord.latitude) - 180.0))/360.0);
    return result;
}

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


- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *, NSError *))result {
    NSURL *url = [self URLForTilePath:path];
    NSString *filePath = [self filePathForTilePath:path];
    
    if ([self isOffline]) { // Local data
        // Kiểm tra nếu tile file đang tồn tại
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSData *tileData = [NSData dataWithContentsOfFile:filePath];
            result(tileData, nil);
        } else {
            result(nil, nil);
        }
    } else {
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        [NSURLConnection sendAsynchronousRequest:urlRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   if (error) {
                                       NSLog(@"Error downloading tile ! \n");
                                       result(nil, error);
                                   }
                                   else {
                                       [data writeToFile:filePath atomically:YES];
                                       result(data, nil);
                                   }
                               }];
    }
}

#pragma mark - Custom for WMS
- (id)initWithWMSUrlString:(NSString *)urlString layers:(NSString *)layers tileSize:(CGSize)tileSize {
    if (self = [self init]) {
        NSString *stringFormat = @"/wms?layers=%@&version=%@&service=%@&request=%@&transparent=true&styles=%@&format=%@&srs=%@%@&width=%tu&height=%tu";
        URL_STRING = [urlString stringByAppendingString:[NSString stringWithFormat:stringFormat, layers, version, service, request, styles, format, srs, @"&bbox=%f,%f,%f,%f", (int)tileSize.width, (int)tileSize.height]];
    }
    MKTileOverlayPath path;
    path.x = 1;
    path.y = 2;
    path.z = 3;
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
    BBOX bbox = [self bboxForPath:path];
    NSString *urlString = [NSString stringWithFormat:URL_STRING, bbox.minx, bbox.miny, bbox.maxx, bbox.maxy];
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

- (NSArray *)tilesForNorthEast:(CLLocationCoordinate2D)neCoord southWest:(CLLocationCoordinate2D)swCoord startZoom:(int)startZoom endZoom:(int)endZoom {
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
                NSString *filePath = [NSString stringWithFormat:@"%tu/%tu/%tu.png", zoom, x, y];
                if (![[NSFileManager defaultManager] fileExistsAtPath:[destinationUrl path]]) {
                    [tiles addObject:@{@"sourceUrl":sourceUrl, @"filePath":filePath}];
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
    NSString *tilesFolder = [[[FileSystemUtilities applicationDocumentsDirectory] path] stringByAppendingString:@"/tiles"];
    [FileSystemUtilities createFolder:tilesFolder];
    
    NSString *zPath = [NSString stringWithFormat:@"%@/%tu", tilesFolder, path.z];
    NSString *xPath = [NSString stringWithFormat:@"%@/%tu/%tu", tilesFolder, path.z, path.x];
    [FileSystemUtilities createFolder:zPath];
    [FileSystemUtilities createFolder:xPath];

    NSString *filePath = [NSString stringWithFormat:@"%tu/%tu/%tu.png", path.z, path.x, path.y];
    return [tilesFolder stringByAppendingPathComponent:filePath];
}

@end
