//
//  OTGeometryCollection.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 9/12/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTGeometry.h"

@interface OTGeometryCollection : NSObject

@property (nonatomic, strong) NSMutableArray *geometries;
@property (nonatomic, strong) OTGeometry *workingGeometry;

- (OTGeometry *)newGeometryWithName:(NSString *)name;
- (void)addGeometry:(OTGeometry *)geometry;
- (void)addPointToWorkingGeometry:(CLLocationCoordinate2D)point currentZoomScale:(double)currentZoomScale;
- (void)removePointFromWorkingGeometry:(CLLocationCoordinate2D)point;

- (NSUInteger)numberOfGeometries;

@end
