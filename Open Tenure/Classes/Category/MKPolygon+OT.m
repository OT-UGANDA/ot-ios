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

#import "MKPolygon+OT.h"

#define kEarthRadius 6378137
static inline double degreesToRadians(double degrees) {
    return degrees * M_PI / 180.;
}

@implementation MKPolygon (OT)

/**
 Area calculator
 */
- (double)area {
    double area = 0;
    NSArray *coords = [self coordinates];
    if (coords.count > 2) {
        CLLocationCoordinate2D p1, p2;
        for (int i = 0; i < coords.count - 1; i++) {
            p1 = [coords[i] MKCoordinateValue];
            p2 = [coords[i + 1] MKCoordinateValue];
            area += degreesToRadians(p2.longitude - p1.longitude) * (2 + sinf(degreesToRadians(p1.latitude)) + sinf(degreesToRadians(p2.latitude)));
        }
        //Wrapping around
        p1 = [coords[coords.count - 1] MKCoordinateValue];
        p2 = [coords[0] MKCoordinateValue];
        area += degreesToRadians(p2.longitude - p1.longitude) * (2 + sinf(degreesToRadians(p1.latitude)) + sinf(degreesToRadians(p2.latitude)));
        area = area * kEarthRadius * kEarthRadius / 2;
    }
    
    return fabs(area);
}

- (NSArray *)coordinates {
    NSMutableArray *points = [NSMutableArray arrayWithCapacity:self.pointCount];
    for (int i = 0; i < self.pointCount; i++) {
        MKMapPoint *point = &self.points[i];
        [points addObject:[NSValue valueWithMKCoordinate:MKCoordinateForMapPoint(* point)]];
    }
    return points.copy;
}

- (double)getArea {
    double area = [self area];
    if (self.interiorPolygons != nil) {
        for (MKPolygon *p in self.interiorPolygons) {
            area -= [p area];
        }
    }
    return area;
}

@end
