//
//  ShapeKitGeometry.h
//  ShapeKit
//
//  Created by Michael Weisman on 10-08-21.

// * This is free software; you can redistribute and/or modify it under
// the terms of the GNU Lesser General Public Licence as published
// by the Free Software Foundation. 
// See the COPYING file for more information.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "geos_c.h"
#import "proj_api.h"
#import "TBClusterAnnotation.h"

@interface ShapeKitGeometry : NSObject {
    NSString *wktGeom;
    NSString *geomType;
	NSString *projDefinition;
    GEOSGeometry *geosGeom;
    GEOSContextHandle_t handle;
	unsigned int numberOfCoords;
}

@property (nonatomic, retain) NSString *wktGeom;
@property (nonatomic, retain) NSString *geomType;
@property (nonatomic, retain) NSString *projDefinition;
@property (nonatomic) GEOSGeometry *geosGeom;
@property (nonatomic) unsigned int numberOfCoords;

- (id)initWithWKB:(const unsigned char *)wkb size:(size_t)wkb_size;
- (id)initWithWKT:(NSString *)wkt;
- (id)initWithGeosGeometry:(GEOSGeometry *)geom;
- (void)reprojectTo:(NSString *)newProjectionDefinition;

void notice(const char *fmt,...);
void log_and_exit(const char *fmt,...);

@end

@interface ShapeKitPoint : ShapeKitGeometry
{
    TBClusterAnnotation *geometry;
}

@property (nonatomic, retain) TBClusterAnnotation *geometry;
-(id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end

@interface ShapeKitPolyline : ShapeKitGeometry
{
    MKPolyline *geometry;
}

@property (nonatomic, retain) MKPolyline *geometry;
-(id)initWithCoordinates:(CLLocationCoordinate2D[])coordinates count:(unsigned int)count;

@end

@interface ShapeKitPolygon : ShapeKitGeometry
{
    MKPolygon *geometry;
}

@property (readonly) NSArray *interiors;
@property (nonatomic, retain) MKPolygon *geometry;
-(id)initWithCoordinates:(CLLocationCoordinate2D[])coordinates count:(unsigned int)count;

@end

#pragma mark - Geometry collections

/** ShapeKitPolyline is an abstract class that represents a collection of heterogeneous ShapeKitGeometry objects.
 */
@interface ShapeKitGeometryCollection : ShapeKitGeometry
@property (strong) NSArray *geometries;
- (NSUInteger)numberOfGeometries;
- (ShapeKitGeometry *)geometryAtIndex:(NSInteger)index;
@end

/** ShapeKitPolyline models a collection of ShapeKitPolyline objects.
 */
@interface ShapeKitMultiPolyline : ShapeKitGeometryCollection
- (NSUInteger)numberOfPolylines;
- (ShapeKitPolyline *)polylineAtIndex:(NSInteger)index;
@end

/** ShapeKitPoint models a collection of ShapeKitPoint objects.
 */
@interface ShapeKitMultiPoint : ShapeKitGeometryCollection
- (NSUInteger)numberOfPoints;
- (ShapeKitPoint *)pointAtIndex:(NSInteger)index;
@end

/** ShapeKitMultiPolygon models a collection of ShapeKitMultiPolygon objects.
 */
@interface ShapeKitMultiPolygon : ShapeKitGeometryCollection
- (NSUInteger)numberOfPolygons;
- (ShapeKitPolygon *)polygonAtIndex:(NSInteger)index;
@end
