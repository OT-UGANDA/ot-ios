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

#import "GeoShape.h"
#import "GeoShapeVertex.h"

#define NEAREST_THESAURUS 1.5

long at(long i, long n) {
    return i < 0 ? n - (-i % n) : i % n;
}

/*!
 Diện tích tam giác ABC
 */
NS_INLINE double area(MKMapPoint A, MKMapPoint B, MKMapPoint C) {
    return (A.x * (B.y - C.y) + B.x * (C.y - A.y) + C.x * (A.y - B.y)) / 2.0;
}

/*!
 Miền của P theo hướng A-B
 */
NS_INLINE bool isRight(MKMapPoint A, MKMapPoint B, MKMapPoint P) {
    return area(A, B, P) >= 0.;
}

/*!
 Phương vị của hướng p1 -> p2
 */
NS_INLINE double azimuth(MKMapPoint p1, MKMapPoint p2) {
    double tmp = atan2(p2.y - p1.y, p2.x - p1.x);
    return (tmp >= 2.0 * M_PI ? tmp - 2.0 * M_PI : (tmp >= 0.0 ? tmp : tmp + 2.0 * M_PI));
}

/*!
 Góc của pA (0-360)
 */
NS_INLINE double angle(MKMapPoint pA, MKMapPoint pLeft, MKMapPoint pRight) {
    double tmp = azimuth(pA, pRight) - azimuth(pA, pLeft);
    return (tmp >= 2.0 * M_PI ? tmp - 2.0 * M_PI : (tmp >= 0. ? tmp : tmp + 2.0 * M_PI));
}

/*!
 Tính khoảng cách giữa 2 điểm
 */
NS_INLINE double distance(MKMapPoint A, MKMapPoint B) {
    return sqrt((B.x - A.x)*(B.x - A.x) + (B.y - A.y)*(B.y - A.y));
}

/*!
 Tính khoảng cách vuông góc từ một điểm tới một cạnh
 @param point điểm cần tính
 @param A, B đoạn thẳng AB
 */
NS_INLINE double distancePerpendicular(MKMapPoint point, MKMapPoint A, MKMapPoint B) {
    double a;
    if (isRight(A, B, point))
        a = angle(A, B, point);
    else
        a = angle(A, point, B);
    return sin(a)*distance(point, A);
}

/*!
 Xác định điểm vuông góc (chưa kiểm chứng)
 @param point điểm bất kỳ
 @param A, B đoạn thẳng
 */
MKMapPoint MKMapPointPerpendicular(MKMapPoint point, MKMapPoint A, MKMapPoint B) {
    if (distance(A, B) > 0) {
        double x1 = A.x;
        double y1 = A.y;
        double x2 = B.x;
        double y2 = B.y;
        double x3 = point.x;
        double y3 = point.y;
        double k = ((y2-y1) * (x3-x1) - (x2-x1) * (y3-y1)) / ((y2-y1)*(y2-y1) + (x2-x1)*(x2-x1));
        double x4 = x3 - k * (y2-y1);
        double y4 = y3 + k * (x2-x1);
        return MKMapPointMake(x4, y4);
    } return A;
}

/*!
 Dịch chuyển của một điểm từ p theo hướng direction và bán kính radius
 */
NS_INLINE MKMapPoint offsetFrom(MKMapPoint p, double direction, double radius) {
    double dx = radius * cos(direction);
    double dy = radius * sin(direction);
    return MKMapPointMake(p.x + dx, p.y + dy);
}

/*!
 Bisectors the specified A.
 @param A - Point A
 @param B - Point B is left side
 @param C - Point C is right side
 @result azimuth of bisector line
 */
NS_INLINE double bisector(MKMapPoint pA, MKMapPoint pLeft, MKMapPoint pRight) {
    double tmp = 0;
    tmp = azimuth(pA, pLeft) + angle(pA, pLeft, pRight) / 2.0;
    return (tmp >= 2.0 * M_PI ? tmp - 2. * M_PI : (tmp >= 0 ? tmp : tmp + 2. * M_PI));
}

bool isPointInsideAB(MKMapPoint A, MKMapPoint B, MKMapPoint P) {
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

NS_INLINE bool isPointInside(MKMapPoint A, MKMapPoint B, MKMapPoint P) {
    return ((B.y <= P.y) && (P.y < A.y)) || ((A.y <= P.y) && (P.y < B.y));
}

NS_INLINE bool isRightV(MKMapPoint A, MKMapPoint B, MKMapPoint P) {
    double a = area(A, B, P);
    if (A.y <= B.y)
        return a >= 0.;
    else
        return a < 0.;
}

/*!
 Xác định 2 đoạn có cắt nhau hay không
 @param A, B đoạn thẳng AB
 @param C, D đoạn thẳng CD
 @param includingEndPoit bao gồm cắt nhau tại đỉnh
 */
NS_INLINE bool isCross(MKMapPoint A, MKMapPoint B, MKMapPoint C, MKMapPoint D, bool includingEndPoint) {
    if (includingEndPoint) {
        double b1 = area(A, B, C);
        double b2 = area(A, B, D);
        double b3 = area(C, D, A);
        double b4 = area(C, D, B);
        return (b1 >= 0.) == !(b2 >= 0.) && (b3 >= 0.) == !(b4 >= 0.);
    } else {
        double b1 = area(A, B, C);
        double b2 = area(A, B, D);
        double b3 = area(C, D, A);
        double b4 = area(C, D, B);
        if (b1 == 0. || b2 == 0. || b3 == 0. || b4 == 0.) return false;
        return (b1 >= 0.) == !(b2 >= 0) && (b3 >= 0.) == !(b4 >= 0.);
    }
}

/*!
 Chiều dài cung tròn của 2 điểm theo bề mặt trái đất
 */
CLLocationDistance CLLocationDistanceGlobe(MKMapPoint p1, MKMapPoint p2) {
    return MKMetersBetweenMapPoints(p1, p2);
//    static const double EARTH_RADIUS_IN_METERS = 6372797.560856;
//    CLLocationCoordinate2D cd1 = MKCoordinateForMapPoint(p1);
//    CLLocationCoordinate2D cd2 = MKCoordinateForMapPoint(p2);
//    double latitudeArc  = (cd1.latitude - cd2.latitude) * M_PI / 180.0;
//    double longitudeArc = (cd1.longitude - cd2.longitude) * M_PI / 180.0;
//    double latitudeH = sin(latitudeArc * 0.5);
//    latitudeH *= latitudeH;
//    double lontitudeH = sin(longitudeArc * 0.5);
//    lontitudeH *= lontitudeH;
//    double tmp = 1.0;//cos(cd1.latitude*DEG_TO_RAD) * cos(cd2.latitude*DEG_TO_RAD);
//    return EARTH_RADIUS_IN_METERS * 2.0 * asin(sqrt(latitudeH + tmp*lontitudeH));
}

/*!
 Point in the segment
 @param p - Point to check
 @param p1 - Start Point
 @param p2 - End Point
 @result true/false
 */
NS_INLINE bool isPointInSegment(MKMapPoint p, MKMapPoint p1, MKMapPoint p2) {
    CLLocationDistance d1 = CLLocationDistanceGlobe(p, p1);
    CLLocationDistance d2 = CLLocationDistanceGlobe(p, p2);
    CLLocationDistance d0 = CLLocationDistanceGlobe(p1, p2);
    
    CLLocationDistance distance = (d1 + d2) - d0;

    return distance <= 0.0001;
}

NS_INLINE bool isParallels(MKMapPoint A, MKMapPoint B, MKMapPoint C, MKMapPoint D) {
    double b1 = area(A, B, C);
    double b2 = area(A, B, D);
    double b3 = area(C, D, A);
    double b4 = area(C, D, B);
    return b1 == b2 && b3 == b4;
}

/*!
 Độ nghiêng (dốc) của 2 điểm
 */
NS_INLINE double slope(MKMapPoint a, MKMapPoint b) {
    return (a.x - b.x != 0) ? ((a.y - b.y) / (a.x - b.x)) : ((a.y - b.y) >= 0 ? (M_PI / 2.0) : (-M_PI / 2.0));
}

/*!
 Xác định giao điểm, với điều kiện hai đoạn thẳng không song song (isParallelPointA....)
 */
NS_INLINE MKMapPoint intersectPoint(MKMapPoint A, MKMapPoint B, MKMapPoint C, MKMapPoint D) {
    MKMapPoint invalidPoint = MKMapPointMake(DBL_MIN, DBL_MIN);
    if (isParallels(A, B, C, D))
        return invalidPoint;
    double x;
    double y;
    double _loc_5 = (B.y - A.y) / (B.x - A.x);
    double _loc_6 = (D.y - C.y) / (D.x - C.x);
    double _loc_7 = A.y - _loc_5 * A.x;
    double _loc_8 = C.y - _loc_6 * C.x;
    if (fabs(slope(A, B)) == M_PI/2.0) {
        x = A.x;
        y = _loc_6 * x + _loc_8;
        return MKMapPointMake(x, y);
    }
    if (fabs(slope(C, D)) == M_PI/2.0) {
        x = C.x;
        y = _loc_5 * x + _loc_7;
        return MKMapPointMake(x, y);
    }
    double _loc_9 = (_loc_8 - _loc_7) / (_loc_5 - _loc_6);
    x = _loc_9;
    y = _loc_5 * _loc_9 + _loc_7;
    return MKMapPointMake(x, y);
}

@implementation GeoShape

@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize pointCount = _pointCount;
@synthesize coordinate = _coordinate;
@synthesize points = _points;
@synthesize region = _region;
@synthesize boundingMapRect = _boundingMapRect;
@synthesize vertices = _vertices;

- (id)init {
    if (self = [super init]) {
        _strokeColor = [UIColor otDarkBlue];
        _fillColor = [UIColor clearColor];
        _lineWidth = 1.0;
    }
    return self;
}

- (id)initWithTitle:(NSString *)newTitle subtitle:(NSString *)newSubtitle {
    if (self = [self init]) {
        _title = newTitle;
        _subtitle = newSubtitle;
        _points = NULL;
        _pointCount = 0;
        _boundingMapRect = MKMapRectWorld;
        _vertices = [@[] mutableCopy];
        _currentIndex = 0;
    }
    return self;
}

- (id)initWithCenterCoordinate:(CLLocationCoordinate2D)coordinate {
    if (self = [self init]) {
        _pointCount = 0;
        _boundingMapRect = MKMapRectWorld;
        _vertices = [@[] mutableCopy];
        _region.center = coordinate;
        _region.span = MKCoordinateSpanMake(1, 1);
        GeoShapeVertex *vertex = [[GeoShapeVertex alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        [self insertVertex:vertex currentZoomScale:CGFLOAT_MIN];
    }
    return self;
}

- (NSInteger)addCoordinate:(CLLocationCoordinate2D)coordinate currentZoomScale:(double)currentZoomScale {
    GeoShapeVertex *vertex = [[GeoShapeVertex alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];

    [self insertVertex:vertex currentZoomScale:currentZoomScale];
    return _currentIndex;
}

- (void)removeCoordinate:(CLLocationCoordinate2D)coordinate {
    GeoShapeVertex *vertex = [[GeoShapeVertex alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    [self removeVertex:vertex];
}

- (CLLocationCoordinate2D *)coordinates {
    CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * _pointCount);
    for (int i = 0; i < _pointCount; i++) {
        GeoShapeVertex *vertex = [_vertices objectAtIndex:i];
        coords[i] = vertex.coordinate;
    }
    return coords;
}

- (void)removeVertex:(GeoShapeVertex *)vertex {
    for (GeoShapeVertex *storedVertex in [_vertices copy]) {
        if ([storedVertex isEqual:vertex]) {
            [_vertices removeObject:vertex];
            _pointCount--;
        }
    }
    [self updatePoints];
}

- (void)insertVertex:(GeoShapeVertex *)vertex currentZoomScale:(double)currentZoomScale {
    for (GeoShapeVertex *storedVertex in _vertices)
        if ([storedVertex isEqual:vertex] && currentZoomScale != CGFLOAT_MIN) return;
    if (_vertices.count < 3 || currentZoomScale == CGFLOAT_MIN) {
        [_vertices addObject:vertex];
        _pointCount++;
        _currentIndex++;
        vertex.tag = _currentIndex;
        [self updatePoints];
        return;
    }
    MKMapPoint point = MKMapPointForCoordinate(vertex.coordinate);
    NSUInteger insertionIndex = [self getInsertionIndex:point currentZoomScale:currentZoomScale];
    if (insertionIndex != NSUIntegerMax) {
        [_vertices insertObject:vertex atIndex:insertionIndex+1];
        _pointCount++;
        _currentIndex++;
        vertex.tag = _currentIndex;
    } else {
        [_vertices addObject:vertex];
        _pointCount++;
        _currentIndex++;
        vertex.tag = _currentIndex;
    }
    [self updatePoints];
}

- (NSUInteger)getInsertionIndex:(MKMapPoint)point currentZoomScale:(double)currentZoomScale {
    NSUInteger insertionIndex = NSUIntegerMax;
    double offset = MKRoadWidthAtZoomScale(currentZoomScale) * NEAREST_THESAURUS;
    long i = 0, n = _pointCount;
    BOOL result = NO;
    MKMapPoint *points = self.points;
    while (result == NO && i < n) {
        MKMapPoint p0 = points[at(i, n)];
        MKMapPoint p1 = points[at(i+1, n)];
        double dx = p0.x - p1.x;
        double dy = p0.y - p1.y;
        double a1 = point.x * dy;
        double a2 = point.y * dx;
        double a3 = p0.x * p1.y;
        double a4 = p1.x * p0.y;
        double d = fabs(a1 - a2 + a3 - a4)/sqrt(dx*dx + dy*dy);
        bool c1 = isPointInsideAB(p0, p1, point);
        if (d <= offset && c1) {
            insertionIndex = at(i, n);
            result = YES;
            return i;
        }
        i++;
    }
    
    return insertionIndex;
}

- (void)updatePoints {
    MKMapPoint *pts = malloc(sizeof(MKMapPoint) * _pointCount);
    for (int i = 0; i < _pointCount; i++) {
        GeoShapeVertex *vertex = [_vertices objectAtIndex:i];
        pts[i] = MKMapPointForCoordinate(vertex.coordinate);
    }
    _region = MKCoordinateRegionFromPoints([_vertices copy]);
    _boundingMapRect = MKMapRectForCoordinateRegion(_region);
    _points = pts;
    [self updateCW];
    [self updateCentroid];
}

- (void)updateCentroid {
    if (_pointCount >= 4) {
        MKMapPoint centroid = [self getCentroid];
        _coordinate = MKCoordinateForMapPoint(centroid);
    } else {
        _coordinate = _region.center;
    }
}

- (void)updateCW {
    NSUInteger n = _pointCount;
    if (n < 3) _isCW = NO;
    double a = 0.0;
    for (long i = 1; i < n; i++)
        a += area(_points[at(i-1, n)], _points[at(i, n)], _points[at(i+1, n)]);
    _isCW = (a >= 0 ? YES : NO);
}

NS_INLINE MKMapRect MKMapRectForCoordinateRegion(MKCoordinateRegion region) {
    MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude + region.span.latitudeDelta / 2,
                                                                      region.center.longitude - region.span.longitudeDelta / 2));
    MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude - region.span.latitudeDelta / 2,
                                                                      region.center.longitude + region.span.longitudeDelta / 2));
    return MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
}

NS_INLINE MKCoordinateRegion MKCoordinateRegionFromPoints(NSArray *vertices) {
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
    
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
    
    for (GeoShapeVertex *vertex in vertices) {
        topLeftCoord.longitude = fmin(topLeftCoord.longitude, vertex.coordinate.longitude);
        topLeftCoord.latitude = fmax(topLeftCoord.latitude, vertex.coordinate.latitude);
        
        bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, vertex.coordinate.longitude);
        bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, vertex.coordinate.latitude);
    }
    
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(MKMapRectWorld);
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.1;
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.1;
    return region;
}

/*!
 Determining whether A given point is inside or outside of A polygon O(n)
 */
- (BOOL)isPointInside:(MKMapPoint)point {
    BOOL tmp = NO; NSUInteger n = _pointCount;
    if (n < 3) return tmp;
    for (long i = 0; i < n; i++)
        if (isPointInside(_points[at(i, n)], _points[at(i+1, n)], point) && isRightV(_points[at(i, n)], _points[at(i+1, n)], point))
            tmp = !tmp;
    return tmp;
}

/*!
 Xác định tâm của đa giác (điểm đặt lớn nhất nằm trong đa giác)
 */
- (MKMapPoint)getCentroid {
    MKMapPoint invalidPoint = MKMapPointMake(DBL_MIN, DBL_MIN);
    MKMapPoint center = MKMapPointForCoordinate(_region.center);
    double dLast = 0.; // Khoảng cách min từ skeleton tới cạnh
    for (long index = 0; index < _pointCount; index++) {
        MKMapPoint pg = [self at:index];
        MKMapPoint pp = [self at:index+1];
        MKMapPoint pb = [self offset:index distance:100];
        for (long i = 1; i < _pointCount - 1; i++) {
            long ik = at(index + i, _pointCount);
            MKMapPoint pk = [self at:ik];
            MKMapPoint pk1 = [self at:ik+1];
            MKMapPoint opp = intersectPoint(pg, pb, pk, pk1);
            if (MKMapPointEqualToPoint(invalidPoint, opp)) continue; // cạnh kế tiếp
            // Kiểm tra xem giao điểm có nằm trên cạnh đối hay không
            if (!isPointInSegment(opp, pk, pk1)) continue; // cạnh kế tiếp
            // Kiểm tra xem điểm opp có phải nằm trên cạnh đối hay không?
            if (isRight(pg, opp, pk1) != [self isCW]) continue; // cạnh kế tiếp
            // Nếu nằm trên cạnh đối thì phải thỏa mãn đk không cắt bất kỳ cạnh nào
            bool isOpposite = true;
            for (long l = 1; l < _pointCount - 1; l++) {
                if (isCross(pg, opp, [self at:index+l], [self at:index+l+1], false)&&(i!=l)) {
                    isOpposite = false;
                    break; // thoat ra khoi vong for l
                }
            }
            if (isOpposite) {
                MKMapPoint iRO = intersectPoint(pg, pp, pk, pk1);
                double bro = bisector(iRO, opp, pg);
                MKMapPoint iRO1 = offsetFrom(iRO, bro, 100);
                // Cắt đường phân giác góc đang xét
                // Giao điểm của hướng phải cạnh đối với đường phân giác góc đang xét
                MKMapPoint skeleton = intersectPoint(iRO, iRO1, pg, pb);
                // bổ sung:
                // Kiểm tra xem hai hướng phân giác hai bên có cắt trong đoạn pg-skeleton hay k
                bool bChange = false;
                MKMapPoint test1 = intersectPoint([self at:index-1], [self offset:index-1 distance:100], pg, skeleton);
                if (isPointInSegment(test1, pg, skeleton)) {
                    skeleton = test1;
                    bChange = true;
                    MKMapPoint test2 = intersectPoint([self at:index+1], [self offset:index+1 distance:100], pg, skeleton);
                    if (isPointInSegment(test2, pg, skeleton))
                        skeleton = test2;
                } else {
                    MKMapPoint test2 = intersectPoint([self at:index+1], [self offset:index+1 distance:100], pg, skeleton);
                    if (isPointInSegment(test2, pg, skeleton)) {
                        skeleton = test2;
                        bChange = true;
                    }
                }
                // end bổ sung
                double d1 = [self minDistanceFromPoint:skeleton];
                if (d1 > dLast) {
                    center = skeleton;
                    dLast = d1;
                }
                break; // Ra khoi vong for i
            }
        }
    }
    return center;
}

- (BOOL)isCW {
    return _isCW;
}

/*!
 Retrieve the index of vertex
 */
- (MKMapPoint)at:(long)i {
    return _points[at(i, _pointCount)];
}

- (MKMapPoint)offset:(long)i distance:(double)dR {
    double b = bisector([self at:i], [self at:i-1], [self at:i+1]);
    if ([self isCW]) b = bisector([self at:i], [self at:i+1], [self at:i-1]);
    return offsetFrom([self at:i], b, dR);
}

/*!
 Tính khoảng cách nhỏ nhất từ point tới cạnh của polygon
 (bán kính đường tròn nội tiếp tâm point lớn nhất)
 */
- (double)minDistanceFromPoint:(MKMapPoint)point {
    double d = DBL_MAX;
    for (long i = 0; i < _pointCount; i++) {
        if (isPointInsideAB([self at:i], [self at:i+1], point)) {
            double d1 = distancePerpendicular(point, [self at:i], [self at:i+1]);
            d = MIN(d, d1);
        } else {
            double d1 = distance(point, [self at:i]);
            d = MIN(d, d1);
            d1 = distance(point, [self at:i+1]);
            d = MIN(d, d1);
        }
    }
    return d;
}

@end
