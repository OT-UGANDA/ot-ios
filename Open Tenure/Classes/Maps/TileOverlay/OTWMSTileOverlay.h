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

#import <MapKit/MapKit.h>

typedef struct {
    CGFloat minx;
    CGFloat miny;
    CGFloat maxx;
    CGFloat maxy;
} BBOX;

#define SRID        @"900913"
#define TO_RADIANS  M_PI/180.0f
#define TO_DEGREES  180.0f/M_PI

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

@interface OTWMSTileOverlay : MKTileOverlay

@property (nonatomic, getter=isGeoServerWMS) BOOL geoServerWMS;

- (id)initWithWMSUrlString:(NSString *)urlString tileSize:(CGSize)tileSize;

- (NSArray *)tilesForNorthEast:(CLLocationCoordinate2D)neCoord southWest:(CLLocationCoordinate2D)swCoord startZoom:(int)startZoom endZoom:(int)endZoom canReplace:(BOOL)canReplace;

- (BBOX)bboxForPath:(MKTileOverlayPath)path;
- (NSString *)filePathForTilePath:(MKTileOverlayPath)path;
- (NSURL *)URLForTilePath:(MKTileOverlayPath)path;

@end
