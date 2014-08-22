//
//  TBCoordinateQuadTree.h
//  TBAnnotationClustering
//
//  Created by Theodore Calmes on 9/27/13.
//  Copyright (c) 2013 Theodore Calmes. All rights reserved.
//  Modified by Tran Trung Chuyen on 2/10/2014
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "TBQuadTree.h"

@interface TBCoordinateQuadTree : NSObject

@property (assign, nonatomic) TBQuadTreeNode* root;
@property (strong, nonatomic) MKMapView *mapView;

- (void)buildTreeFromFile:(NSString *)fileName;
- (void)buildTreeFromAnnotations:(NSArray *)annotations;
- (NSArray *)clusteredAnnotationsWithinMapRect:(MKMapRect)rect withZoomScale:(double)zoomScale;

@end
