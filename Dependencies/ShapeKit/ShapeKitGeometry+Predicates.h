//
//  ShapeKitGeometry+Predicates.h
//  ShapeKit

// * This is free software; you can redistribute and/or modify it under
// the terms of the GNU Lesser General Public Licence as published
// by the Free Software Foundation. 
// See the COPYING file for more information.
//

#import <Foundation/Foundation.h>
#import "ShapeKitGeometry.h"

@interface ShapeKitGeometry (predicates)

-(BOOL)isDisjointFromGeometry:(ShapeKitGeometry *)compareGeometry;
-(BOOL)touchesGeometry:(ShapeKitGeometry *)compareGeometry;

/*!
 Cắt nhau (có giao điểm)
 */
-(BOOL)intersectsGeometry:(ShapeKitGeometry *)compareGeometry;
-(BOOL)crossesGeometry:(ShapeKitGeometry *)compareGeometry;

/*!
 Nằm trong compareGeometry
 */
-(BOOL)isWithinGeometry:(ShapeKitGeometry *)compareGeometry;
-(BOOL)containsGeometry:(ShapeKitGeometry *)compareGeometry;

/*!
 Chồng chéo lên compareGeometry
 */
-(BOOL)overlapsGeometry:(ShapeKitGeometry *)compareGeometry;

/*!
 Trùng nhau
 */
-(BOOL)isEqualToGeometry:(ShapeKitGeometry *)compareGeometry;
-(BOOL)isRelatedToGeometry:(ShapeKitGeometry *)compareGeometry WithRelatePattern:(NSString *)pattern;

/*!
 Test whether two geometries lie within a given distance of each other.
 @param g0 - a Geometry
 @param g1 - another Geometry
 @param distance - the distance to test
 @return true if g0.distance(g1) <= distance
 */
- (BOOL)isWithinDistance:(ShapeKitGeometry *)compareGeometry distance:(double *)distance;

@end