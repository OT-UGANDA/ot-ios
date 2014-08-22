//
//  TBClusterAnnotation.h
//  TBAnnotationClustering
//
//  Created by Theodore Calmes on 10/8/13.
//  Copyright (c) 2013 Theodore Calmes. All rights reserved.
//  Modified by Tran Trung Chuyen on 2/10/2014
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface TBClusterAnnotation : NSObject <MKAnnotation>

@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *subtitle;
@property (nonatomic) NSString *icon;
@property (nonatomic) NSString *uuid;
@property (assign, nonatomic) NSInteger count;
@property (assign, nonatomic) NSUInteger index;
@property (assign, nonatomic) NSUInteger tag;

@property (nonatomic) MKMapRect boundingMapRect;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate count:(NSInteger)count;

@end
