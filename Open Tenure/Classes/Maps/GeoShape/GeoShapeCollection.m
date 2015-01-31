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

#import "GeoShapeCollection.h"
#import "GeoShapeVertex.h"
#import "GeoShape.h"

@implementation GeoShapeCollection

@synthesize workingOverlay = _workingOverlay;
@synthesize overlays = _overlays;
@synthesize region = _region;
@synthesize boundingMapRect = _boundingMapRect;
@synthesize snappedCoordinate = _snappedCoordinate;
@synthesize coordinate = _coordinate;

- (id)init {
    if (self = [super init]) {
        _overlays = [@[] mutableCopy];
        _boundingMapRect = MKMapRectWorld;
        pthread_rwlock_init(&_rwLock, NULL);
    }
    return self;
}

- (GeoShape *)createShapeWithTitle:(NSString *)title subtitle:(NSString *)subtitle {
    GeoShape *shape = [[GeoShape alloc] initWithTitle:title subtitle:subtitle];
    [self addShape:shape];
    return shape;
}

- (GeoShape *)createShapeWithCenterCoordinate:(CLLocationCoordinate2D)coordinate {
    GeoShape *shape = [[GeoShape alloc] initWithCenterCoordinate:coordinate];
    [self addShape:shape];
    return shape;
}

- (GeoShape *)createShapeFromPolygon:(MKPolygon *)polygon {
    GeoShape *shape = [[GeoShape alloc] initWithTitle:nil subtitle:nil];
    for (int i = 0; i < polygon.pointCount-1; i++)
        [shape addCoordinate:MKCoordinateForMapPoint(polygon.points[i]) currentZoomScale:CGFLOAT_MIN];

    [self addShape:shape];
    return shape;
}

- (void)addShape:(GeoShape *)shape {
    pthread_rwlock_wrlock(&_rwLock);
    [_overlays addObject:shape];
    [self updateOverlays];
    pthread_rwlock_unlock(&_rwLock);
}

- (NSInteger)addPointToWorkingOverlay:(CLLocationCoordinate2D)point currentZoomScale:(double)currentZoomScale {
    if (_overlays.count == 0) return 0;
    if (self.workingOverlay == nil) return 0;
    NSInteger currentIndex = [self.workingOverlay addCoordinate:point currentZoomScale:currentZoomScale];
    [self updateOverlays];
    return currentIndex;
}

- (void)removePointFromWorkingOverlay:(CLLocationCoordinate2D)point {
    if (_overlays.count == 0) return;
    if (self.workingOverlay == nil) return;
    [self.workingOverlay removeCoordinate:point];
    [self updateOverlays];
}

- (NSArray *)shapesInMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale {
    if (MKMapRectIsNull(mapRect)) return nil;
    pthread_rwlock_wrlock(&_rwLock);
    
    NSMutableArray *objects = [NSMutableArray array];
    for (GeoShape *overlay in _overlays) {
        if (MKMapRectIntersectsRect(mapRect, [overlay boundingMapRect])) {
            [objects addObject:overlay];
        }
    }
    pthread_rwlock_unlock(&_rwLock);
    return objects;
}

- (void)lockForReading {
    pthread_rwlock_rdlock(&_rwLock);
}

- (void)unlockForReading {
    pthread_rwlock_unlock(&_rwLock);
}

- (void)updateOverlays {
    if (_overlays.count == 1) {
        GeoShape *shape = [_overlays firstObject];
        _boundingMapRect = shape.boundingMapRect;
    } else {
        for (GeoShape *shape in _overlays) {
            _boundingMapRect = MKMapRectUnion(shape.boundingMapRect, _boundingMapRect);
        }
    }
    _region = MKCoordinateRegionForMapRect(_boundingMapRect);
    _coordinate = _region.center;
}

- (GeoShape *)getOverlayByMapPoint:(MKMapPoint)mapPoint {
    for (GeoShape *shape in _overlays)
        if ([shape isPointInside:mapPoint])
            return shape;
    return nil;
}

- (BOOL)getSnapFromMapPoint:(CLLocationCoordinate2D)coordinate mapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale snapMode:(SnapMode)mode {
    NSMutableArray *overlays = [NSMutableArray arrayWithArray:[self shapesInMapRect:mapRect zoomScale:zoomScale]];
    double snap_threshold = 0.2 * MKRoadWidthAtZoomScale(zoomScale);
    [overlays removeObject:_workingOverlay];
    NSMutableArray *visiblePoints = [@[] mutableCopy];
    
    // Endpoint
    for (GeoShape *shape in overlays) {
        for (GeoShapeVertex *vertex in shape.vertices) {
            NSValue *value = [NSValue valueWithMKCoordinate:vertex.coordinate];
            [visiblePoints addObject:value];
        }
    }
    // Nearest
    MKMapPoint point = MKMapPointForCoordinate(coordinate);
    for (GeoShape *shape in overlays) {
        NSUInteger n = shape.vertices.count;
        for (int i = 0; i < shape.pointCount; i++) {
            MKMapPoint A = shape.points[at(i, n)];
            MKMapPoint B = shape.points[at(i+1, n)];
            if (isPointInsideAB(A, B, point)) {
                MKMapPoint p = MKMapPointPerpendicular(point, A, B);
                NSValue *value = [NSValue valueWithMKCoordinate:MKCoordinateForMapPoint(p)];
                [visiblePoints addObject:value];
            }
        }
    }
    // Sắp xếp theo khoảng cách
    if (visiblePoints.count > 0) {
        [visiblePoints sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            double distance1 = MKMetersBetweenMapPoints(MKMapPointForCoordinate([obj1 MKCoordinateValue]), MKMapPointForCoordinate(coordinate));
            double distance2 = MKMetersBetweenMapPoints(MKMapPointForCoordinate([obj2 MKCoordinateValue]), MKMapPointForCoordinate(coordinate));
            return distance1 > distance2;
        }];
    }
    if (visiblePoints.count > 0) {
        NSValue *value = visiblePoints[0];
        CLLocationCoordinate2D snapCoordinate = [value MKCoordinateValue];
        CLLocationDistance distance = MKMetersBetweenMapPoints(MKMapPointForCoordinate(coordinate), MKMapPointForCoordinate(snapCoordinate));
        if (distance <= snap_threshold) {
            _snappedCoordinate = snapCoordinate;
            return YES;
        }
    }
    return NO;
}

@end
