//
//  OTGeometry.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 9/12/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShapeKit.h"

@interface OTGeometry : NSObject

@property (nonatomic, strong) NSMutableArray *points;
@property (nonatomic, strong) NSString *name;

- (id)initWithName:(NSString *)name;

- (void)addCoordinate:(CLLocationCoordinate2D)coordinate currentZoomScale:(double)currentZoomScale;
- (void)removeCoordinate:(CLLocationCoordinate2D)coordinate;
- (MKPolygon *)polygon;

@end
