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
#import "OTFormCell.h"
#import "OTShowcase.h"

#define ADJACENT_THRESHOLD 0.0001

static inline double azimuth(MKMapPoint p1, MKMapPoint p2) {
    double tmp = atan2(p2.y - p1.y, p2.x - p1.x);
    return (tmp >= 2.0 * M_PI ? tmp - 2.0 * M_PI : (tmp >= 0.0 ? tmp : tmp + 2.0 * M_PI));
}

@interface OTAdjacenciesUpdateViewController () {
    OTShowcase *showcase;
    BOOL multipleShowcase;
    NSInteger currentShowcaseIndex;
}

@end

@implementation OTAdjacenciesUpdateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.formCells = [self createAdjacencies];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - OTShowcase & OTShowcaseDelegate methods
- (void)configureShowcase {
    showcase = [[OTShowcase alloc] init];
    showcase.delegate = self;
    [showcase setBackgroundColor:[UIColor otDarkBlue]];
    [showcase setTitleColor:[UIColor greenColor]];
    [showcase setDetailsColor:[UIColor whiteColor]];
    [showcase setHighlightColor:[UIColor whiteColor]];
    [showcase setContainerView:self.navigationController.navigationBar.superview];
    __strong typeof(showcase) showcase_ = showcase;
    showcase.nextActionBlock = ^(void){
        [showcase_ showcaseTapped];
    };
    showcase.skipActionBlock = ^(void) {
        [showcase_ setShowing:NO];
        [showcase_ showcaseTapped];
    };
}

- (IBAction)defaultShowcase:(id)sender {
    [self configureShowcase];
    if (_showcaseTargetList.count == 0 || [showcase isShowing]) return;
    NSDictionary *item = [_showcaseTargetList objectAtIndex:0];
    [showcase setIType:[[item objectForKey:@"type"] intValue]];
    [showcase setupShowcaseForTarget:[item objectForKey:@"target"]  title:[item objectForKey:@"title"] details:[item objectForKey:@"detail"]];
    [showcase show];
}

#pragma mark - OTShowcaseDelegate methods
- (void)OTShowcaseShown{}

- (void)OTShowcaseDismissed {
    currentShowcaseIndex++;
    if (![showcase isShowing]) {
        currentShowcaseIndex = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:kSetClaimTabBarIndexNotificationName object:[NSNumber numberWithInteger:0] userInfo:nil];
    } else {
        if (currentShowcaseIndex < _showcaseTargetList.count) {
            NSDictionary *item = [_showcaseTargetList objectAtIndex:currentShowcaseIndex];
            [showcase setIType:[[item objectForKey:@"type"] intValue]];
            [showcase setupShowcaseForTarget:[item objectForKey:@"target"]  title:[item objectForKey:@"title"] details:[item objectForKey:@"detail"]];
            [showcase show];
        } else {
            currentShowcaseIndex = 0;
            [showcase setShowing:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:kSetClaimTabBarIndexNotificationName object:[NSNumber numberWithInteger:4] userInfo:@{@"action":@"showcase"}];
        }
    }
}

- (IBAction)done:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)checkInvalidCell {
    
}

- (NSArray *)createAdjacencies {
    
    NSInteger customCellHeight = 32.0f;
    Class inputTextFieldClass = [OTFormInputTextFieldCell class];
    
    NSString *sectionHeaderTitle1 = NSLocalizedString(@"title_claim_adjacencies", nil);
    NSString *sectionHeaderTitle2 = NSLocalizedString(@"adjacent_claims", nil);
    OTFormCell *sectionHeader1 = [[OTFormCell alloc] init];
    sectionHeader1.selectionStyle = UITableViewCellSelectionStyleNone;
//    sectionHeader1.textLabel.backgroundColor = [UIColor otGreen];
    sectionHeader1.backgroundColor = [UIColor otGreen];
    sectionHeader1.textLabel.textColor = [UIColor whiteColor];
    sectionHeader1.textLabel.layer.cornerRadius = 0;
//    sectionHeader1.textLabel.attributedText = [OT getAttributedStringFromText:sectionHeaderTitle1];
    sectionHeader1.textLabel.text = sectionHeaderTitle1;
    sectionHeader1.customCellHeight = 24;
    
    OTFormCell *sectionHeader2 = [[OTFormCell alloc] init];
    sectionHeader2.selectionStyle = UITableViewCellSelectionStyleNone;
//    sectionHeader2.textLabel.backgroundColor = [UIColor otGreen];
    sectionHeader2.backgroundColor = [UIColor otGreen];
    sectionHeader2.textLabel.textColor = [UIColor whiteColor];
    sectionHeader2.textLabel.layer.cornerRadius = 0;
//    sectionHeader2.textLabel.attributedText = [OT getAttributedStringFromText:sectionHeaderTitle2];
    sectionHeader2.textLabel.text = sectionHeaderTitle2;
    sectionHeader2.customCellHeight = 24;
    
    [self setHeaderTitle:NSLocalizedString(@"north", nil) forSection:1];
    [self setHeaderTitle:NSLocalizedString(@"south", nil) forSection:2];
    [self setHeaderTitle:NSLocalizedString(@"east", nil) forSection:3];
    [self setHeaderTitle:NSLocalizedString(@"west", nil) forSection:4];
    
    OTFormInputTextFieldCell *northAdjacency =
    [[inputTextFieldClass alloc] initWithText:_claim.northAdjacency
                                  placeholder:NSLocalizedString(@"north_adjacency", nil)
                                     delegate:self
                                    mandatory:NO
                             customCellHeight:customCellHeight
                                 keyboardType:UIKeyboardTypeDefault
                                     viewType:_claim.getViewType];
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
                                     viewType:_claim.getViewType];
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
                                     viewType:_claim.getViewType];
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
                                     viewType:_claim.getViewType];
    westAdjacency.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        _claim.westAdjacency = inText;
    };

    NSMutableArray *adjacentCells = [NSMutableArray array];

    if (_claim.mappedGeometry != nil) {
        ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:_claim.mappedGeometry];
        ShapeKitPoint *centerPoint = [polygon centroid];
        MKMapPoint center = MKMapPointForCoordinate(centerPoint.geometry.coordinate);
        NSArray *adjacentClaims = [self getAdjacentCLaims];
        for (int i = 0; i < adjacentClaims.count; i++) {
            Claim *claim = [adjacentClaims objectAtIndex:i];
            ShapeKitPolygon *otherPolygon = [[ShapeKitPolygon alloc] initWithWKT:claim.mappedGeometry];
            ShapeKitPoint *otherPoint = [otherPolygon centroid];
            MKMapPoint other = MKMapPointForCoordinate(otherPoint.geometry.coordinate);
            double angle = azimuth(center, other);
            NSString *cardinalDirection = [self getCardinalDirection:angle * 180.0 / M_PI];
            NSString *text = [NSString stringWithFormat:@"%@, By: %@\n%@",claim.claimName, [claim.person fullNameType:OTFullNameTypeDefault], NSLocalizedString(_claim.statusCode, nil)];
            [self setHeaderTitle:NSLocalizedString(cardinalDirection, nil) forSection:i+6];
            OTFormCell *cell = [[OTFormCell alloc] init];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
            cell.customCellHeight = 44;
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.layer.cornerRadius = 0;
            cell.textLabel.attributedText = [OT getAttributedStringFromText:text];
            [adjacentCells addObject:cell];
            
            // Tạo claimant image
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 46, 46)];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            
            NSString *fullPath = [claim.person getFullPath];

            UIImage *personPicture = [UIImage imageWithContentsOfFile:fullPath];
            if (personPicture == nil) personPicture = [UIImage imageNamed:@"ic_person_picture"];
            imageView.image = personPicture;
            imageView.backgroundColor = [UIColor whiteColor];
            cell.accessoryView = imageView;
        }
    }

    self.customSectionHeaderHeight = 16;
    self.customSectionFooterHeight = 8;

    return @[@[sectionHeader1], @[northAdjacency], @[southAdjacency], @[eastAdjacency], @[westAdjacency], @[sectionHeader2], adjacentCells];
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
