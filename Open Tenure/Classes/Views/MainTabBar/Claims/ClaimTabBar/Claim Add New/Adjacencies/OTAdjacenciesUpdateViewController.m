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

#import "OTAdjacenciesUpdateViewController.h"
#import "OTFormInputTextFieldCell.h"
#import "OTFormFloatInputTextFieldCell.h"
#import "OTMapViewController.h"
#import "ShapeKit.h"

#define ADJACENT_THRESHOLD 0.0001

static inline double azimuth(MKMapPoint p1, MKMapPoint p2) {
    double tmp = atan2(p2.y - p1.y, p2.x - p1.x);
    return (tmp >= 2.0 * M_PI ? tmp - 2.0 * M_PI : (tmp >= 0.0 ? tmp : tmp + 2.0 * M_PI));
}

@interface OTAdjacenciesUpdateViewController ()

@property (assign) OTViewType viewType;

@end

@implementation OTAdjacenciesUpdateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.viewType = _claim.getViewType;
    
    self.formCells = [self createAdjacencies];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)createAdjacencies {
    
    NSInteger customCellHeight = 40.0f;
    Class inputTextFieldClass = [OTFormFloatInputTextFieldCell class];
    
    [self setHeaderTitle:NSLocalizedString(@"title_claim_adjacencies", nil) forSection:0];
    
    OTFormInputTextFieldCell *northAdjacency =
    [[inputTextFieldClass alloc] initWithText:_claim.northAdjacency
                                  placeholder:NSLocalizedString(@"north_adjacency", nil)
                                     delegate:self
                                    mandatory:NO
                             customCellHeight:customCellHeight
                                 keyboardType:UIKeyboardTypeDefault
                                     viewType:_viewType];
    northAdjacency.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        _claim.northAdjacency = inText;
    };

    OTFormInputTextFieldCell *southAdjacency =
    [[inputTextFieldClass alloc] initWithText:_claim.southAdjacency
                                  placeholder:NSLocalizedString(@"south_adjacency", nil)
                                     delegate:self
                                    mandatory:NO
                             customCellHeight:customCellHeight
                                 keyboardType:UIKeyboardTypeDefault
                                     viewType:_viewType];
    southAdjacency.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        _claim.southAdjacency = inText;
    };

    OTFormInputTextFieldCell *eastAdjacency =
    [[inputTextFieldClass alloc] initWithText:_claim.eastAdjacency
                                  placeholder:NSLocalizedString(@"east_adjacency", nil)
                                     delegate:self
                                    mandatory:NO
                             customCellHeight:customCellHeight
                                 keyboardType:UIKeyboardTypeDefault
                                     viewType:_viewType];
    eastAdjacency.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        _claim.eastAdjacency = inText;
    };

    OTFormInputTextFieldCell *westAdjacency =
    [[inputTextFieldClass alloc] initWithText:_claim.westAdjacency
                                  placeholder:NSLocalizedString(@"west_adjacency", nil)
                                     delegate:self
                                    mandatory:NO
                             customCellHeight:customCellHeight
                                 keyboardType:UIKeyboardTypeDefault
                                     viewType:_viewType];
    westAdjacency.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        _claim.westAdjacency = inText;
    };

    NSMutableArray *adjacentCells = [NSMutableArray array];

    if (_claim.mappedGeometry != nil) {
        ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:_claim.mappedGeometry];
        ShapeKitPoint *centerPoint = [polygon centroid];
        MKMapPoint center = MKMapPointForCoordinate(centerPoint.geometry.coordinate);
        NSArray *adjacentClaims = [self getAdjacentCLaims];
        for (Claim *claim in adjacentClaims) {
            ShapeKitPolygon *otherPolygon = [[ShapeKitPolygon alloc] initWithWKT:claim.mappedGeometry];
            ShapeKitPoint *otherPoint = [otherPolygon centroid];
            MKMapPoint other = MKMapPointForCoordinate(otherPoint.geometry.coordinate);
            double angle = azimuth(center, other);
            NSString *cardinalDirection = [self getCardinalDirection:angle * 180.0 / M_PI];
            OTFormFloatInputTextFieldCell *cell =
            [[inputTextFieldClass alloc] initWithText:[NSString stringWithFormat:@"%@, By: %@", claim.claimName, [claim.person fullNameType:OTFullNameTypeDefault]]
                                          placeholder:NSLocalizedString(cardinalDirection, nil)
                                             delegate:self
                                            mandatory:NO
                                     customCellHeight:customCellHeight
                                         keyboardType:UIKeyboardTypeDefault
                                             viewType:_viewType];
            [adjacentCells addObject:cell];
        }
    }
    [self setHeaderTitle:NSLocalizedString(@"adjacent_claims", nil) forSection:1];
    return @[@[northAdjacency, southAdjacency, eastAdjacency, westAdjacency], adjacentCells];
}

- (NSArray *)getAdjacentCLaims {
    NSMutableArray *adjacentClaims = [NSMutableArray array];
    NSMutableArray *claims = [NSMutableArray arrayWithArray:[ClaimEntity getCollection]];
    [claims removeObject:_claim];
    if (_claim.mappedGeometry == nil) return nil;
    ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:_claim.mappedGeometry];
    for (Claim *claim in claims) {
        if (claim.mappedGeometry == nil) continue;
        ShapeKitPolygon *otherPolygon = [[ShapeKitPolygon alloc] initWithWKT:claim.mappedGeometry];
        BOOL isEqual = [polygon isEqualToGeometry:otherPolygon];
        double distance = ADJACENT_THRESHOLD;
        if ([polygon isWithinDistance:otherPolygon distance:&distance] && !isEqual) {
            [adjacentClaims addObject:claim];
        }
    }
    
    return adjacentClaims;
}

- (NSString *)getCardinalDirection:(double)angle {
    NSArray *quadrant = @[@"north", @"south", @"east", @"west", @"north_east", @"north_west", @"south_east", @"south_west", @"none"];
    int a = angle;
    int result = 8;
    if (a > 240 && a <= 285) result = 0;
    if (a > 71 && a <= 105) result = 1;
    if ((a >= 0 && a <= 15) || (a > 330 && a <= 360)) result = 2;
    if (a > 150 && a <= 195) result = 3;
    if (a > 285 && a <= 330) result = 4;
    if (a > 195 && a <= 240) result = 5;
    if (a > 15 && a <= 71) result = 6;
    if (a > 105 && a <= 150) result = 7;
    return quadrant[result];
}

@end
