//
//  OTGeometry.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 9/12/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTGeometry.h"
#import "OTCoordinate.h"

static inline long at(long i, long n) {
    return i < 0 ? n - (-i % n) : i % n;
}

static inline double area(MKMapPoint A, MKMapPoint B, MKMapPoint C) {
    return (A.x * (B.y - C.y) + B.x * (C.y - A.y) + C.x * (A.y - B.y)) / 2.0;
}

static inline bool isRight(MKMapPoint A, MKMapPoint B, MKMapPoint P) {
    return area(A, B, P) >= 0.;
}

static inline double azimuth(MKMapPoint p1, MKMapPoint p2) {
    double tmp = atan2(p2.y - p1.y, p2.x - p1.x);
    return (tmp >= 2.0 * M_PI ? tmp - 2.0 * M_PI : (tmp >= 0.0 ? tmp : tmp + 2.0 * M_PI));
}

static inline double angle(MKMapPoint pA, MKMapPoint pLeft, MKMapPoint pRight) {
    double tmp = azimuth(pA, pRight) - azimuth(pA, pLeft);
    return (tmp >= 2.0 * M_PI ? tmp - 2.0 * M_PI : (tmp >= 0. ? tmp : tmp + 2.0 * M_PI));
}

static inline bool isPointInsideAB(MKMapPoint A, MKMapPoint B, MKMapPoint P) {
    if (isRight(A, B, P)) {
        double a1 = angle(A, B, P);
        double a2 = angle(B, P, A);
        return a1 <= M_PI_2 && a2 <= M_PI_2;
    } else {
        double a1 = angle(A, P, B);
        double a2 = angle(B, A, P);
        return a1 <= M_PI_2 && a2 <= M_PI_2;
    }
}

@implementation OTGeometry

- (id)initWithName:(NSString *)name {
    if (self = [super init]) {
        _name = name;
        _points = [@[] mutableCopy];
    }
    return self;
}

- (void)addCoordinate:(CLLocationCoordinate2D)coordinate currentZoomScale:(double)currentZoomScale {
    OTCoordinate *vertex = [[OTCoordinate alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    [self insertVertex:vertex currentZoomScale:currentZoomScale];
}

- (void)removeCoordinate:(CLLocationCoordinate2D)coordinate {
    OTCoordinate *otCoordinate = [[OTCoordinate alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    
    NSMutableArray *discardedCoordinates = [[NSMutableArray alloc] init];
    
    for (OTCoordinate *storedCoordinate in [self points]) {
        if ([storedCoordinate isEqual:otCoordinate]) {
            [discardedCoordinates addObject:storedCoordinate];
        }
    }
    
    [[self points] removeObjectsInArray:discardedCoordinates];
}

- (MKPolygon *)polygon {
    const unsigned int numberOfPoints = (unsigned int)self.points.count;
    
    CLLocationCoordinate2D locations[numberOfPoints];
    
    for (NSInteger i = 0; i<numberOfPoints; i++) {
        locations[i] = [(OTCoordinate *)self.points[i] coordinate];
    }
    MKPolygon *polygon = [MKPolygon polygonWithCoordinates:locations count:numberOfPoints];
    
    return polygon;
}

- (void)insertVertex:(OTCoordinate *)vertex currentZoomScale:(double)currentZoomScale {
    if (self.points.count < 3) {
        [self.points addObject:vertex];
        return;
    }
    MKMapPoint point = MKMapPointForCoordinate(vertex.coordinate);
    NSUInteger insertionIndex = [self getInsertionIndex:point currentZoomScale:currentZoomScale];
    if (insertionIndex != NSUIntegerMax) {
        [self.points insertObject:vertex atIndex:insertionIndex+1];
    } else {
        [self.points addObject:vertex];
    }
}


- (NSUInteger)getInsertionIndex:(MKMapPoint)point currentZoomScale:(double)currentZoomScale {
    NSUInteger insertionIndex = NSUIntegerMax;
    double offset = MKRoadWidthAtZoomScale(currentZoomScale) * 1.5;
    long i = 0, n = self.polygon.pointCount;
    BOOL result = NO;
    
    while (result == NO && i < n) {
        MKMapPoint p0 = self.polygon.points[at(i, n)];
        MKMapPoint p1 = self.polygon.points[at(i+1, n)];
        double dx = p0.x - p1.x;   // dx = x1-x2
        double dy = p0.y - p1.y;   // dy = y1-y2
        double a1 = point.x * dy;                      // x*dy
        double a2 = point.y * dx;                      // y*dx
        double a3 = p0.x * p1.y;   // x1*y2
        double a4 = p1.x * p0.y;   // x2*y1
        double d = fabs(a1 - a2 + a3 - a4)/sqrt(dx*dx + dy*dy);
        bool c1 = isPointInsideAB(p0, p1, point);
        if (d <= offset && c1) {
            insertionIndex = at(i, n);
            return i;
        }
        i++;
    }
    
    return insertionIndex;
}


@end
