//
//  ShapeKitGeometry.m
//  ShapeKit
//
//  Created by Michael Weisman on 10-08-21.

// * This is free software; you can redistribute and/or modify it under
// the terms of the GNU Lesser General Public Licence as published
// by the Free Software Foundation. 
// See the COPYING file for more information.
//

#import "ShapeKitGeometry.h"

@implementation ShapeKitGeometry
@synthesize wktGeom, geomType, projDefinition, geosGeom, numberOfCoords;

#pragma mark ShapeKitPoint init methods
- (id)init
{
    if (self = [super init]) {
        handle = initGEOS_r(notice, log_and_exit);
    }
    return self;
}

- (id)initWithWKB:(const unsigned char *)wkb size:(size_t)wkb_size {
    if (self = [self init]) {
        GEOSWKBReader *WKBReader = GEOSWKBReader_create_r(handle);
        geosGeom = GEOSWKBReader_read_r(handle, WKBReader, wkb, wkb_size);
        GEOSWKBReader_destroy_r(handle, WKBReader);
        
        self.geomType = [NSString stringWithUTF8String:GEOSGeomType_r(handle, geosGeom)];
        
        GEOSWKTWriter *WKTWriter = GEOSWKTWriter_create_r(handle);
        self.wktGeom = [NSString stringWithUTF8String:GEOSWKTWriter_write_r(handle, WKTWriter, geosGeom)];
        GEOSWKTWriter_destroy_r(handle, WKTWriter);
    }
    
    return self;
}

-(id)initWithWKT:(NSString *)wkt {
    if (self = [self init]) {
        GEOSWKTReader *WKTReader = GEOSWKTReader_create_r(handle);
        self.geosGeom = GEOSWKTReader_read_r(handle, WKTReader, [wkt UTF8String]);
        GEOSWKTReader_destroy_r(handle, WKTReader);
        
        self.geomType = [NSString stringWithUTF8String:GEOSGeomType_r(handle, geosGeom)];
        
        GEOSWKTWriter *WKTWriter = GEOSWKTWriter_create_r(handle);
        self.wktGeom = [NSString stringWithUTF8String:GEOSWKTWriter_write_r(handle, WKTWriter, geosGeom)];
        GEOSWKTWriter_destroy_r(handle, WKTWriter);
    }
    return self;
}

-(id)initWithGeosGeometry:(GEOSGeometry *)geom {
    if (self = [self init]) {
        geosGeom = geom;
        self.geomType = [NSString stringWithUTF8String:GEOSGeomType_r(handle, geosGeom)];
        GEOSWKTWriter *WKTWriter = GEOSWKTWriter_create_r(handle);
        self.wktGeom = [NSString stringWithUTF8String:GEOSWKTWriter_write_r(handle, WKTWriter, geosGeom)];
        GEOSWKTWriter_destroy_r(handle, WKTWriter);
    }
    return self;    
}

-(void)reprojectTo:(NSString *)newProjectionDefinition {
    // TODO: Impliment this as an SRID int stored on the geom rather than a proj4 string
	projPJ source, destination;
	source = pj_init_plus([projDefinition UTF8String]);
	destination = pj_init_plus([newProjectionDefinition UTF8String]);
	unsigned int coordCount;
    GEOSCoordSequence *sequence = GEOSCoordSeq_clone_r(handle, GEOSGeom_getCoordSeq_r(handle, geosGeom));
	GEOSCoordSeq_getSize_r(handle, sequence, &coordCount);
	double x[coordCount];
	double y[coordCount];
    
    for (int coord = 0; coord < coordCount; coord++) {
        double xCoord = NULL;
        GEOSCoordSeq_getX_r(handle, sequence, coord, &xCoord);
        
        double yCoord = NULL;
        GEOSCoordSeq_getY_r(handle, sequence, coord, &yCoord);
		xCoord *= DEG_TO_RAD;
		yCoord *= DEG_TO_RAD;
		y[coord] = yCoord;
		x[coord] = xCoord;
    }
	
    GEOSCoordSeq_destroy_r(handle, sequence);
	
	int proj = pj_transform(source, destination, coordCount, 1, x, y, NULL );
	for (int i = 0; i < coordCount; i++) {
		printf("x:\t%.2f\n",x[i]);
	}
    
    // TODO: move the message from a log to an NSError
    if (proj != 0) {
        ALog(@"%@",[NSString stringWithUTF8String:pj_strerrno(proj)]);
    }
	pj_free(source);
	pj_free(destination);
}

#pragma mark GEOS init functions
void notice(const char *fmt,...) {
	va_list ap;
    
    fprintf( stdout, "NOTICE: ");
    
	va_start (ap, fmt);
    vfprintf( stdout, fmt, ap);
    va_end(ap);
    fprintf( stdout, "\n" );
}

void log_and_exit(const char *fmt,...) {
	va_list ap;
    
    fprintf( stdout, "ERROR: ");
    
	va_start (ap, fmt);
    vfprintf( stdout, fmt, ap);
    va_end(ap);
    fprintf( stdout, "\n" );
	exit(1);
}

@end

#pragma mark - ShapeKitPoint methods

@implementation ShapeKitPoint
@synthesize geometry;

-(id)initWithWKT:(NSString *)wkt {
    if (self = [super initWithWKT:wkt]) {
        GEOSCoordSequence *sequence = GEOSCoordSeq_clone_r(handle, GEOSGeom_getCoordSeq_r(handle, geosGeom));
        geometry = [[TBClusterAnnotation alloc] init];
        double xCoord;
        GEOSCoordSeq_getX_r(handle, sequence, 0, &xCoord);
        
        double yCoord;
        GEOSCoordSeq_getY_r(handle, sequence, 0, &yCoord);
        geometry.coordinate = CLLocationCoordinate2DMake(yCoord, xCoord);
        
        GEOSCoordSeq_getSize_r(handle, sequence, &numberOfCoords);
        GEOSCoordSeq_destroy_r(handle, sequence);
    }
    return self;
}

-(id)initWithGeosGeometry:(GEOSGeometry *)geom {
    if (self = [super initWithGeosGeometry:geom]) {
        GEOSCoordSequence *sequence = GEOSCoordSeq_clone_r(handle, GEOSGeom_getCoordSeq_r(handle, geosGeom));
        geometry = [[TBClusterAnnotation alloc] init];
        double xCoord;
        GEOSCoordSeq_getX_r(handle, sequence, 0, &xCoord);
        
        double yCoord;
        GEOSCoordSeq_getY_r(handle, sequence, 0, &yCoord);
        geometry.coordinate = CLLocationCoordinate2DMake(yCoord, xCoord);
        
        GEOSCoordSeq_getSize_r(handle, sequence, &numberOfCoords);
        GEOSCoordSeq_destroy_r(handle, sequence);
    }
    return self;
}

-(id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    if (self = [super init]) {
        GEOSCoordSequence *seq = GEOSCoordSeq_create_r(handle, 1, 2);
        GEOSCoordSeq_setX_r(handle, seq, coordinate.longitude, 0);
        GEOSCoordSeq_setY_r(handle, seq, coordinate.latitude, 0);
        self.geosGeom = GEOSGeom_createPoint_r(handle, seq);

        // TODO: Move the destroy into the dealloc method
        // GEOSCoordSeq_destroy(seq);
        geometry = [[TBClusterAnnotation alloc] init];
        geometry.coordinate = coordinate;
        
        
        GEOSWKTWriter *WKTWriter = GEOSWKTWriter_create_r(handle);
        self.wktGeom = [NSString stringWithUTF8String:GEOSWKTWriter_write_r(handle, WKTWriter, geosGeom)];
        GEOSWKTWriter_destroy_r(handle, WKTWriter);
    }
    return self;
}

@end

#pragma mark - ShapeKitPolyline methods

@implementation ShapeKitPolyline
@synthesize geometry;

- (id)initWithWKB:(const unsigned char *)wkb size:(size_t)wkb_size {
    if (self = [super initWithWKB:wkb size:wkb_size]) {
        GEOSCoordSequence *sequence = GEOSCoordSeq_clone_r(handle, GEOSGeom_getCoordSeq_r(handle, geosGeom));
        GEOSCoordSeq_getSize_r(handle, sequence, &numberOfCoords);
        CLLocationCoordinate2D coords[numberOfCoords];
        
        for (int coord = 0; coord < numberOfCoords; coord++) {
            double xCoord = NULL;
            GEOSCoordSeq_getX_r(handle, sequence, coord, &xCoord);
            
            double yCoord = NULL;
            GEOSCoordSeq_getY_r(handle, sequence, coord, &yCoord);
            coords[coord] = CLLocationCoordinate2DMake(yCoord, xCoord);
        }
        geometry = [MKPolyline polylineWithCoordinates:coords count:numberOfCoords];
        
        GEOSCoordSeq_destroy_r(handle, sequence);
    }
    return self;
}

-(id)initWithWKT:(NSString *)wkt {
    if (self = [super initWithWKT:wkt]) {
        GEOSCoordSequence *sequence = GEOSCoordSeq_clone_r(handle, GEOSGeom_getCoordSeq_r(handle, geosGeom));
        GEOSCoordSeq_getSize_r(handle, sequence, &numberOfCoords);
        CLLocationCoordinate2D coords[numberOfCoords];
        
        for (int coord = 0; coord < numberOfCoords; coord++) {
            double xCoord = NULL;
            GEOSCoordSeq_getX_r(handle, sequence, coord, &xCoord);
            
            double yCoord = NULL;
            GEOSCoordSeq_getY_r(handle, sequence, coord, &yCoord);
            coords[coord] = CLLocationCoordinate2DMake(yCoord, xCoord);
        }
        geometry = [MKPolyline polylineWithCoordinates:coords count:numberOfCoords];

        GEOSCoordSeq_destroy_r(handle, sequence);
    }
    return self;
}

-(id)initWithGeosGeometry:(GEOSGeometry *)geom {
    if (self = [super initWithGeosGeometry:geom]) {
        GEOSCoordSequence *sequence = GEOSCoordSeq_clone_r(handle, GEOSGeom_getCoordSeq_r(handle, geosGeom));
        GEOSCoordSeq_getSize_r(handle, sequence, &numberOfCoords);
        CLLocationCoordinate2D coords[numberOfCoords];
        
        for (int coord = 0; coord < numberOfCoords; coord++) {
            double xCoord = NULL;
            GEOSCoordSeq_getX_r(handle, sequence, coord, &xCoord);
            
            double yCoord = NULL;
            GEOSCoordSeq_getY_r(handle, sequence, coord, &yCoord);
            coords[coord] = CLLocationCoordinate2DMake(yCoord, xCoord);
        }
        geometry = [MKPolyline polylineWithCoordinates:coords count:numberOfCoords];
        
        GEOSCoordSeq_destroy_r(handle, sequence);
    }
    return self;
}

-(id)initWithCoordinates:(CLLocationCoordinate2D[])coordinates count:(unsigned int)count{
    if (self = [super init]) {
        GEOSCoordSequence *seq = GEOSCoordSeq_create_r(handle, count,2);
        
        for (int i = 0; i < count; i++) {
            GEOSCoordSeq_setX_r(handle, seq, i, coordinates[i].longitude);
            GEOSCoordSeq_setY_r(handle, seq, i, coordinates[i].latitude);
        }
        self.geosGeom = GEOSGeom_createLineString_r(handle, seq);
        
        // TODO: Move the destroy into the dealloc method
        // GEOSCoordSeq_destroy(seq);
        geometry = [MKPolyline polylineWithCoordinates:coordinates count:count];
        
        GEOSWKTWriter *WKTWriter = GEOSWKTWriter_create_r(handle);
        self.wktGeom = [NSString stringWithUTF8String:GEOSWKTWriter_write_r(handle, WKTWriter, geosGeom)];
        GEOSWKTWriter_destroy_r(handle, WKTWriter);
    }
    return self;
}


@end

#pragma mark - ShapeKitPolygon methods

@implementation ShapeKitPolygon
@synthesize geometry;
@synthesize interiors = _interiors;

- (id)initWithWKB:(const unsigned char *)wkb size:(size_t)wkb_size {
    if (self = [super initWithWKB:wkb size:wkb_size]) {
        [self loadInteriorRings];
        GEOSCoordSequence *sequence = GEOSCoordSeq_clone_r(handle, GEOSGeom_getCoordSeq_r(handle, GEOSGetExteriorRing_r(handle, geosGeom)));
        GEOSCoordSeq_getSize_r(handle, sequence, &numberOfCoords);
        CLLocationCoordinate2D coords[numberOfCoords];
        
        for (int coord = 0; coord < numberOfCoords; coord++) {
            double xCoord = NULL;
            GEOSCoordSeq_getX_r(handle, sequence, coord, &xCoord);
            
            double yCoord = NULL;
            GEOSCoordSeq_getY_r(handle, sequence, coord, &yCoord);
            coords[coord] = CLLocationCoordinate2DMake(yCoord, xCoord);
        }
        if (_interiors != nil && [_interiors count]) {
            geometry = [MKPolygon polygonWithCoordinates:coords count:numberOfCoords interiorPolygons:_interiors];
        } else {
            geometry = [MKPolygon polygonWithCoordinates:coords count:numberOfCoords];
        }
        GEOSCoordSeq_destroy_r(handle, sequence);
    }
    return self;
}

-(id)initWithWKT:(NSString *)wkt {
    if (self = [super initWithWKT:wkt]) {
        [self loadInteriorRings];
        GEOSCoordSequence *sequence = GEOSCoordSeq_clone_r(handle, GEOSGeom_getCoordSeq_r(handle, GEOSGetExteriorRing_r(handle, geosGeom)));
        GEOSCoordSeq_getSize_r(handle, sequence, &numberOfCoords);
        CLLocationCoordinate2D coords[numberOfCoords];
        
        for (int coord = 0; coord < numberOfCoords; coord++) {
            double xCoord = NULL;
            GEOSCoordSeq_getX_r(handle, sequence, coord, &xCoord);
            
            double yCoord = NULL;
            GEOSCoordSeq_getY_r(handle, sequence, coord, &yCoord);
            coords[coord] = CLLocationCoordinate2DMake(yCoord, xCoord);
        }
        if (_interiors != nil && [_interiors count]) {
            geometry = [MKPolygon polygonWithCoordinates:coords count:numberOfCoords interiorPolygons:_interiors];
        } else {
            geometry = [MKPolygon polygonWithCoordinates:coords count:numberOfCoords];
        }
        GEOSCoordSeq_destroy_r(handle, sequence);
    }
    return self;
}

-(id)initWithGeosGeometry:(GEOSGeometry *)geom {
    if (self = [super initWithGeosGeometry:geom]) {
        GEOSCoordSequence *sequence = GEOSCoordSeq_clone_r(handle, GEOSGeom_getCoordSeq_r(handle, GEOSGetExteriorRing_r(handle, geosGeom)));
        GEOSCoordSeq_getSize_r(handle, sequence, &numberOfCoords);
        CLLocationCoordinate2D coords[numberOfCoords];
        
        for (int coord = 0; coord < numberOfCoords; coord++) {
            double xCoord = NULL;
            GEOSCoordSeq_getX_r(handle, sequence, coord, &xCoord);
            
            double yCoord = NULL;
            GEOSCoordSeq_getY_r(handle, sequence, coord, &yCoord);
            coords[coord] = CLLocationCoordinate2DMake(yCoord, xCoord);
        }
        geometry = [MKPolygon polygonWithCoordinates:coords count:numberOfCoords];
        
        GEOSCoordSeq_destroy_r(handle, sequence);
    }
    return self;
}

-(id)initWithCoordinates:(CLLocationCoordinate2D[])coordinates count:(unsigned int)count {
    if (self = [super init]) {
        GEOSCoordSequence *seq = GEOSCoordSeq_create_r(handle, count+1, 2);
        
        for (int i = 0; i < count; i++) {
            GEOSCoordSeq_setX_r(handle, seq, i, coordinates[i].longitude);
            GEOSCoordSeq_setY_r(handle, seq, i, coordinates[i].latitude);
        }
        GEOSCoordSeq_setX_r(handle, seq, count, coordinates[0].longitude);
        GEOSCoordSeq_setY_r(handle, seq, count, coordinates[0].latitude);

        GEOSGeometry *ring = GEOSGeom_createLinearRing_r(handle, seq);
        self.geosGeom = GEOSGeom_createPolygon_r(handle, ring, NULL, 0);
        
        // TODO: Move the destroy into the dealloc method
        // GEOSCoordSeq_destroy(seq);
        geometry = [MKPolygon polygonWithCoordinates:coordinates count:count];
        
        GEOSWKTWriter *WKTWriter = GEOSWKTWriter_create_r(handle);
        self.wktGeom = [NSString stringWithUTF8String:GEOSWKTWriter_write_r(handle, WKTWriter, geosGeom)];
        GEOSWKTWriter_destroy_r(handle, WKTWriter);
    }
    return self;
}

- (void)loadInteriorRings {
    GEOSCoordSequence *sequence = nil;
    // Loop interior rings to convert to ShapeKitPolygons
    int numInteriorRings = GEOSGetNumInteriorRings_r(handle, geosGeom);
    NSMutableArray *interiors = [[NSMutableArray alloc] init];
    for (int interiorIndex = 0; interiorIndex < numInteriorRings; interiorIndex++)
    {
        const GEOSGeometry *interior = GEOSGetInteriorRingN_r(handle, geosGeom, interiorIndex);
        sequence = GEOSCoordSeq_clone_r(handle, GEOSGeom_getCoordSeq_r(handle, interior));
        
        unsigned int numCoordsInt = 0;
        GEOSCoordSeq_getSize_r(handle, sequence, &numCoordsInt);
        CLLocationCoordinate2D coordsInt[numCoordsInt];
        
        for (int coord = 0; coord < numCoordsInt; coord++)
        {
            double xCoord = NULL;
            GEOSCoordSeq_getX_r(handle, sequence, coord, &xCoord);
            
            double yCoord = NULL;
            GEOSCoordSeq_getY_r(handle, sequence, coord, &yCoord);
            
            coordsInt[coord] = CLLocationCoordinate2DMake(yCoord, xCoord);
        }
        
        ShapeKitPolygon *curInterior = [[ShapeKitPolygon alloc] initWithCoordinates:coordsInt count: numCoordsInt];
        [interiors addObject: curInterior];
        
        GEOSCoordSeq_destroy_r(handle, sequence);
    }
    
    if ([interiors count])
        _interiors = [interiors copy];
}

@end

#pragma mark - Geometry collections -

@implementation ShapeKitGeometryCollection

- (id)init {
    self = [super init];
    
    if (self)
    {
        _geometries = [NSArray array];
    }
    return self;
}

- (void)dealloc {
    _geometries = nil;
}

- (id)initWithWKB:(const unsigned char *)wkb size:(size_t)wkb_size {
    self = [super initWithWKB:wkb size:wkb_size];
    
    if (self)
    {
        [self loadSubGeometries];
    }
    
    return self;
}

- (id)initWithGeosGeometry:(GEOSGeometry *)geom {
    self = [super initWithGeosGeometry:geom];
    
    if (self)
    {
        [self loadSubGeometries];
    }
    
    return self;
}

- (id)initWithWKT:(NSString *)wkt {
    self = [super initWithWKT:wkt];
    
    if (self)
    {
        [self loadSubGeometries];
    }
    
    return self;
}

// create an array of copy of original geometries
// (double memory footprint, but faster access to data
- (void)loadSubGeometries {
    int numGeometries = GEOSGetNumGeometries_r(handle, geosGeom);
    NSMutableArray *mArray = [NSMutableArray array];
    for (int i=0; i<numGeometries; i++)
    {
        const GEOSGeometry *curGeom = GEOSGetGeometryN_r(handle, geosGeom, i);
        GEOSGeometry *geomCopy = GEOSGeom_clone_r(handle, curGeom);
        
        ShapeKitGeometry *geomObj = [self initWithGeosGeometry:geomCopy];
        [mArray addObject: geomObj];
    }
    _geometries = [mArray copy];
}

- (NSUInteger)numberOfGeometries {
    return self.geometries.count;
}

- (ShapeKitGeometry *)geometryAtIndex:(NSInteger)index {
    return [self.geometries objectAtIndex:index];
}

- (NSString *)description {
    NSMutableString *geomsList = [[NSMutableString alloc] init];
    
    int i=0;
    for (ShapeKitGeometry*geom in self.geometries)
        [geomsList appendFormat:@"\n     Geometry %i: %@", ++i, [geom description]];
    
    return [[super description] stringByAppendingFormat: @"%@", geomsList];
}

@end

#pragma mark MultiLineString
@implementation ShapeKitMultiPolyline
- (NSUInteger)numberOfPolylines     { return [super numberOfGeometries]; }
- (ShapeKitPolyline*)polylineAtIndex:(NSInteger)index   { return (ShapeKitPolyline *)[super geometryAtIndex: index]; }
@end

#pragma mark MultiPoint
@implementation ShapeKitMultiPoint
- (NSUInteger)numberOfPoints        { return [super numberOfGeometries]; }
- (ShapeKitPoint*)pointAtIndex:(NSInteger)index         { return  (ShapeKitPoint *)[super geometryAtIndex: index]; }
@end

#pragma mark MultiPolygon
@implementation ShapeKitMultiPolygon
- (NSUInteger)numberOfPolygons      { return [super numberOfGeometries]; }
- (ShapeKitPolygon*)polygonAtIndex:(NSInteger)index     { return  (ShapeKitPolygon *)[super geometryAtIndex: index]; }
@end