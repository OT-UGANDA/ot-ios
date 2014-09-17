//
//  OTGeometryCollection.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 9/12/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTGeometryCollection.h"

@implementation OTGeometryCollection

- (id)init{
    if (self = [super init]) {
        _geometries = [@[] mutableCopy];
    }
    return self;
}

- (OTGeometry *)newGeometryWithName:(NSString *)name {
    OTGeometry *geometry = [[OTGeometry alloc] initWithName:name];
    [self addGeometry:geometry];
    [self setWorkingGeometry:geometry];
    return geometry;
}

- (void)addGeometry:(OTGeometry *)geometry {
    [self.geometries addObject:geometry];
}

- (void)addPointToWorkingGeometry:(CLLocationCoordinate2D)point currentZoomScale:(double)currentZoomScale {
    if (self.geometries.count == 0) return;
    if (self.workingGeometry == nil) self.workingGeometry = [self.geometries lastObject];
    [self.workingGeometry addCoordinate:point currentZoomScale:currentZoomScale];
}

- (void)removePointFromWorkingGeometry:(CLLocationCoordinate2D)point {
    if (self.geometries.count == 0) return;
    if (self.workingGeometry == nil) self.workingGeometry = [self.geometries lastObject];
    [self.workingGeometry removeCoordinate:point];
}

- (NSUInteger)numberOfGeometries {
    return self.geometries.count;
}

@end
