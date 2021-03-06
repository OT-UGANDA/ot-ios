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
#import <pthread.h>
#import "GeoShape.h"

typedef NS_ENUM(NSInteger, SnapMode) {
    SnapModeEndPoint = 0,
    SnapModeMiddPoint,
    SnapModeNearest
};

@interface GeoShapeCollection : NSObject <MKOverlay> {
    @package
    GeoShape *_workingOverlay;
    NSMutableArray *_overlays;
    MKCoordinateRegion _region;
    MKMapRect _boundingMapRect;
    CLLocationCoordinate2D _snappedCoordinate;
    pthread_rwlock_t _rwLock;
}

@property (nonatomic, strong) GeoShape *workingOverlay;
@property (nonatomic, strong) NSArray *overlays;
@property (nonatomic, assign) MKCoordinateRegion region;
@property (nonatomic, assign) MKMapRect boundingMapRect;
@property (nonatomic, assign) CLLocationCoordinate2D snappedCoordinate;

- (GeoShape *)createShapeWithTitle:(NSString *)title subtitle:(NSString *)subtitle;
- (GeoShape *)createShapeWithCenterCoordinate:(CLLocationCoordinate2D)coordinate;
- (GeoShape *)createShapeFromPolygon:(MKPolygon *)polygon;
- (void)addShape:(GeoShape *)shape;
- (NSInteger)addPointToWorkingOverlay:(CLLocationCoordinate2D)point currentZoomScale:(double)currentZoomScale;
- (void)removePointFromWorkingOverlay:(CLLocationCoordinate2D)point;

- (NSArray *)shapesInMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale;
- (void)lockForReading;
- (void)unlockForReading;
- (void)updateOverlays;
- (GeoShape *)getOverlayByMapPoint:(MKMapPoint)mapPoint;
- (BOOL)getSnapFromMapPoint:(CLLocationCoordinate2D)coordinate mapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale snapMode:(SnapMode)mode;

@end
