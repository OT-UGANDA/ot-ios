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

MK_EXTERN long at(long i, long n);

/*!
 Determining whether a given point P is inside or outside of segment A-B
 */
MK_EXTERN bool isPointInsideAB(MKMapPoint A, MKMapPoint B, MKMapPoint P);
MK_EXTERN MKMapPoint MKMapPointPerpendicular(MKMapPoint point, MKMapPoint A, MKMapPoint B);

@interface GeoShape : MKShape {
    NSString *_title;
    NSString *_subtitle;
    NSUInteger _pointCount;
    MKMapPoint *_points;
    MKCoordinateRegion _region;
    MKMapRect _boundingMapRect;
    NSMutableArray *_vertexes;
    CLLocationCoordinate2D _centroid;
    BOOL _isCW;
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

- (id)initWithTitle:(NSString *)newTitle subtitle:(NSString *)newSubtitle;
- (id)initWithCenterCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)addCoordinate:(CLLocationCoordinate2D)coordinate currentZoomScale:(double)currentZoomScale;
- (void)removeCoordinate:(CLLocationCoordinate2D)coordinate;

- (CLLocationCoordinate2D)coordinate;
- (CLLocationCoordinate2D *)coordinates;
- (MKCoordinateRegion)region;
- (MKMapPoint *)points;
- (NSUInteger)pointCount;
- (MKMapRect)boundingMapRect;
- (void)updatePoints;
- (NSMutableArray *)vertexs;
/*!
 Determining whether A given point is inside or outside of A polygon O(n)
 */
- (BOOL)isPointInside:(MKMapPoint)point;

@end
