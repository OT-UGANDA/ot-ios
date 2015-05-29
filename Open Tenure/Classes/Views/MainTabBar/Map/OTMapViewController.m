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
#import "OTMapViewController.h"
#import "ShapeKit.h"
#import "TBCoordinateQuadTree.h"
#import "TBClusterAnnotationView.h"
#import "OTSettingViewController.h"
#import "OTSettingNavigationController.h"

#import "GeoShape.h"
#import "GeoShapeVertex.h"
#import "GeoShapeCollection.h"
#import "GeoShapeOverlayRenderer.h"
#import "GeoShapeAnnotationView.h"

#import "OTAnnotationView1.h"

#import "DownloadClaimTask.h"

#import "OTWMSTileOverlay.h"
#import "FileDownloadInfo.h"

#import "CDRTranslucentSideBar.h"
#import "OTSideBarItems.h"

#import "OTShowcase.h"

#define TILE_SIZE 256

@interface OTMapViewController () <DownloadClaimTaskDelegate> {
    MKAnnotationView *workingAnnotationView;
    GeoShapeVertex *workingVertex;
    BOOL snapped;
    id tileOverlay;
    OTShowcase *showcase;
    BOOL multipleShowcase;
    NSInteger currentShowcaseIndex;
    
    MKPolygon *communityArea;
}

@property (nonatomic, strong) CDRTranslucentSideBar *sideBarMenu;
@property (nonatomic, strong) OTSideBarItems *sideBarItems;

// Quad tree coordinate for handle cluster annotations
@property (strong, nonatomic) TBCoordinateQuadTree *coordinateQuadTree;

// Managing annotations on the mapView
@property (nonatomic) NSMutableArray *annotations;

@property (nonatomic, strong) GeoShapeCollection *shapes;
@property (nonatomic, assign, getter = isDragging) BOOL dragging;

@property (nonatomic) NSMutableArray *workingAnnotations;

// Progress handle
@property (nonatomic, assign) NSInteger totalItemsToDownload;
@property (nonatomic, assign) NSInteger totalItemsDownloaded;
@property (nonatomic, assign) NSInteger totalItemsDownloadError;
@property (nonatomic, assign, getter = isDownloading) BOOL downloading;

// Tiles download handle
@property (nonatomic, assign) NSInteger totalTilesToDownload;
@property (nonatomic, assign) NSInteger totalTilesDownloaded;
@property (nonatomic, assign) NSInteger totalTilesDownloadError;
@property (nonatomic, assign, getter = isTileDownloading) BOOL tileDownloading;

@property (nonatomic) NSOperationQueue *parseQueue;
@property (nonatomic) NSOperationQueue *downloadTilesQueue;

@property (nonatomic, strong) NSMutableArray *handleDeletedClaims;
@property (nonatomic, strong) NSMutableArray *handleDeletedAttachments;
@property (nonatomic, strong) NSMutableArray *handleDeletedPersons;

// Fix for Xcode 6 iOS 8
@property (nonatomic, strong) CLLocationManager *locationManager;

// Dashboard for marker
@property (nonatomic, strong) UIView *dashboardMenu;
@property (nonatomic, strong) UIView *dashboardAction;
@property (nonatomic, assign) BOOL dashboardMenuShowing;
@property (nonatomic, assign) BOOL dashboardActionShowing;
@property (nonatomic, strong) id selectedMarkerView;

@property (nonatomic, strong) MKPointAnnotation *customAnnotation;
@property (nonatomic, strong) UIImageView *redMarkerView;

@property (nonatomic, strong) NSMutableArray *additionalMarkers;

@property (nonatomic, strong) UILabel *mapTypeLabel;
@property (nonatomic, strong) IBOutlet UILabel *downloadTilesStatusLabel;

@end

@implementation OTMapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureSideBarMenu];
    
    [self configureMapTypeLabelForTitle:NSLocalizedStringFromTable(@"map_type_standard", @"Additional", nil) message:nil];
    
    self.locationManager = [[CLLocationManager alloc] init];
    // Fix for Xcode 6 iOS 8
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            #ifdef __IPHONE_8_0
                [_locationManager requestAlwaysAuthorization];
            #endif
            } else {

            }
            break;
        }
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted: {
            // TODO: Chức năng định bị bị vô hiệu hóa, đề nghị người dùng cho phép
            NSString *title = @"Requests permission to use location services whenever the app is running";
            NSString *message = @"Settings->Privacy->Location Services->Open Tenure->Alaways";
            [UIAlertView showWithTitle:title message:message cancelButtonTitle:@"OK" otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                
            }];
            break;
        }
        default:
            break;
    }
    
    //[self configureOperation];
    [self configureGestures];
    [self configureNotifications];
    [self configureCommunityArea];
    
    [self configureDashboard];
    
    if (_claim.getViewType == OTViewTypeView) { // Readonly
        // TODO: Vẽ các marker cho polygon (không cho phép sửa
    } else if (_claim.getViewType == OTViewTypeEdit) { // Editable
        
    } else { // Add new

    }
    
    // Init Quad tree coordinate
    _coordinateQuadTree = [[TBCoordinateQuadTree alloc] init];
    _coordinateQuadTree.mapView = _mapView;
    
    // Init annotations array
    _annotations = [NSMutableArray array];

    _shapes = [[GeoShapeCollection alloc] init];
    [_mapView addOverlay:_shapes level:MKOverlayLevelAboveLabels];

    self.workingAnnotations = [NSMutableArray array];
    
    // Vẽ các thửa trước
    [self drawMappedGeometry];
    
    if (_claim.mappedGeometry != nil) {
        // Lấy dữ liệu polygon
        ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:_claim.mappedGeometry];
        // Zoom đến polygon
        MKMapRect mapRect = polygon.geometry.boundingMapRect;
        CGFloat width = mapRect.size.width > mapRect.size.height ? mapRect.size.width : mapRect.size.height;
        mapRect.origin.x -= (width - mapRect.size.width) / 2.0;
        mapRect.origin.y -= (width - mapRect.size.height) / 2.0;
        mapRect.size.width = width;
        mapRect.size.height = width;
        [_mapView setVisibleMapRect:mapRect edgePadding:UIEdgeInsetsMake(50, 50, 50, 50) animated:YES];
        
        // Tạo workingOverlay
        GeoShape *shape = [_shapes createShapeWithTitle:_claim.claimName subtitle:nil];
        [_shapes setWorkingOverlay:shape];
        [self configureGeoShape:shape forClaim:_claim];
        shape.isAccessibilityElement = YES;
        
        // Chuyển các đỉnh vào workingOverlay
        for (NSInteger i = 0; i < polygon.geometry.pointCount-1; i++) {
            CLLocationCoordinate2D coordinate = MKCoordinateForMapPoint(polygon.geometry.points[i]);
            NSInteger tag = [_shapes addPointToWorkingOverlay:coordinate currentZoomScale:CGFLOAT_MIN];
            MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
            pointAnnotation.title = [@(tag) stringValue];
            pointAnnotation.subtitle = [NSString stringWithFormat:@"{Lat: %.10f, Lon: %.10f}", coordinate.latitude, coordinate.longitude];
            pointAnnotation.isAccessibilityElement = YES;
            pointAnnotation.coordinate = coordinate;
            [_workingAnnotations addObject:pointAnnotation];
            [_mapView addAnnotation:pointAnnotation];
        }
    } else {
        
    }
    
    self.additionalMarkers = [NSMutableArray array];
    if (_claim.locations.count > 0) {
        for (Location *location in _claim.locations) {
            ShapeKitPoint *point = [[ShapeKitPoint alloc] initWithWKT:location.mappedLocation];
            MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
            annotation.coordinate = point.geometry.coordinate;
            annotation.isAccessibilityElement = YES;
            annotation.accessibilityValue = [location.objectID.URIRepresentation lastPathComponent];
            annotation.accessibilityHint = @"AdditionalAnnotation";
            annotation.title = location.note;
            [_mapView addAnnotation:annotation];
            [_additionalMarkers addObject:annotation];
        }
    }
}

// Chuyển qua tab khác
- (void)viewWillDisappear:(BOOL)animated{
    [self.sideBarMenu dismiss];
    _customShowcase = NO;
    // TODO: Lưu mapedGeometry trong trường hợp tạo mới hoặc sửa
    if ([_claim getViewType] == OTViewTypeView) return;
    
    if (_shapes.workingOverlay.vertices.count > 2) {
        GeoShape *shape = _shapes.workingOverlay;
        NSUInteger pointCount = shape.pointCount;
        ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithCoordinates:shape.coordinates count:(unsigned int)pointCount];
        
        // Tạo điểm và nhãn cho polygon theo tâm của đường bao.
        ShapeKitPoint *point = [[ShapeKitPoint alloc] initWithCoordinate:shape.coordinate];
        
        _claim.gpsGeometry = point.wktGeom;
        _claim.mappedGeometry = polygon.wktGeom;
        
    } else {
        _claim.gpsGeometry = nil;
        _claim.mappedGeometry = nil;
    }
//    if (_claim.isSaved && [_claim.managedObjectContext hasChanges]) {
//        [_claim.managedObjectContext save:nil];
//    }
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)initialization:(id)sender {
    [UIAlertView showWithTitle:NSLocalizedString(@"title_initialization_process", nil) message:NSLocalizedString(@"message_default_initialization", nil) cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"confirm", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"message_title_app_initializing", nil) maskType:SVProgressHUDMaskTypeGradient];
            [OT updateIdType];
            [OT updateLandUse];
            [OT updateClaimType];
            [OT updateDocumentType];
            [OT updateDefaultFormTemplate];
            [OT updateCommunityArea];
            [self performSelector:@selector(checkInitialized) withObject:nil afterDelay:15.0f];
        }
    }];
}

- (void)checkInitialized {
    [SVProgressHUD dismiss];
    NSString *titleError = NSLocalizedString(@"message_title_app_not_initialized", nil);
    NSString *messageError = NSLocalizedString(@"message_app_not_initialized", nil);
    NSString *titleSuccess = NSLocalizedString(@"message_title_app_initialized", nil);
    NSString *messageSuccess = NSLocalizedString(@"message_app_initialized", nil);
    NSString *confirm = NSLocalizedString(@"confirm", nil);
    if ([OT getInitialized]) {
        [OTSetting setInitialization:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:kInitializedNotificationName object:self userInfo:nil];
        [UIAlertView showWithTitle:titleSuccess message:messageSuccess cancelButtonTitle:confirm otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            
        }];
    } else {
        [UIAlertView showWithTitle:titleError message:messageError cancelButtonTitle:confirm otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            
        }];
    }
}

#pragma mark - MapTypeLabel
- (void)configureMapTypeLabelForTitle:(NSString *)title message:(NSString *)message {
    CGSize size = [title sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]}];
    CGRect frame = CGRectMake(0, 8.0f, size.width + 12.0f, size.height + 12.0f);
    CGFloat x = self.mapView.frame.size.width / 2.0 - frame.size.width / 2.0f;
    frame.origin.x = x;
    if (_mapTypeLabel == nil) {
        _mapTypeLabel = [[UILabel alloc] initWithFrame:frame];
        _mapTypeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        _mapTypeLabel.layer.cornerRadius = 4.0f;
        _mapTypeLabel.layer.borderWidth = 0.5;
        _mapTypeLabel.layer.borderColor = [[UIColor otDarkBlue] CGColor];
        _mapTypeLabel.clipsToBounds = YES;
        _mapTypeLabel.textAlignment = NSTextAlignmentCenter;
        _mapTypeLabel.font = [UIFont systemFontOfSize:16];
        _mapTypeLabel.textColor = [UIColor otDarkBlue];
    } else {
        _mapTypeLabel.frame = frame;
    }
    _mapTypeLabel.text = title;
    [self.mapView addSubview:_mapTypeLabel];
}

- (void)configureDownloadTilesStatusLabelForTitle:(NSString *)title message:(NSString *)message {
    CGSize size = [title sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]}];
    CGRect frame = CGRectMake(0, self.mapView.frame.size.height - size.height - 10.0f, size.width + 12.0f, size.height + 12.0f);
    CGFloat x = self.mapView.frame.size.width / 2.0 - frame.size.width / 2.0f;
    frame.origin.x = x;
    if (_downloadTilesStatusLabel == nil) {
        _downloadTilesStatusLabel = [[UILabel alloc] initWithFrame:frame];
        _downloadTilesStatusLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        _downloadTilesStatusLabel.layer.cornerRadius = 4.0f;
        _downloadTilesStatusLabel.layer.borderWidth = 0.5;
        _downloadTilesStatusLabel.layer.borderColor = [[UIColor colorWithRed:1.0f green:204.0f/255.0f blue:0.0f alpha:1.0f] CGColor];
        _downloadTilesStatusLabel.clipsToBounds = YES;
        _downloadTilesStatusLabel.textAlignment = NSTextAlignmentCenter;
        _downloadTilesStatusLabel.font = [UIFont systemFontOfSize:16];
        _downloadTilesStatusLabel.textColor = [UIColor colorWithRed:1.0f green:204.0f/255.0f blue:0.0f alpha:1.0f];
        [self.mapView addSubview:_downloadTilesStatusLabel];
    } else {
        _downloadTilesStatusLabel.frame = frame;
    }
    _downloadTilesStatusLabel.text = title;
}

#pragma mark - OTShowcase & OTShowcaseDelegate methods
- (void)configureShowcase {
    showcase = [[OTShowcase alloc] init];
    showcase.delegate = self;
    [showcase setBackgroundColor:[UIColor otDarkBlue]];
    [showcase setTitleColor:[UIColor greenColor]];
    [showcase setDetailsColor:[UIColor whiteColor]];
    [showcase setHighlightColor:[UIColor whiteColor]];
    [showcase setContainerView:[[[[[UIApplication sharedApplication] delegate] window] subviews] objectAtIndex:0]];
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
    
    // Set zoomLevel to maxZoom for showing file download button
    MKCoordinateRegion region = self.mapView.region;
    region.span = MKCoordinateSpanMake(0.01f, 0.01f);
    [self.mapView setRegion:region animated:NO];
    
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
        if (!_customShowcase)
            [[NSNotificationCenter defaultCenter] postNotificationName:kSetMainTabBarIndexNotificationName object:[NSNumber numberWithInteger:0] userInfo:nil];
        else
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
            if (!_customShowcase)
                [[NSNotificationCenter defaultCenter] postNotificationName:kSetMainTabBarIndexNotificationName object:[NSNumber numberWithInteger:2] userInfo:@{@"action":@"showcase"}];
            else
                [[NSNotificationCenter defaultCenter] postNotificationName:kSetClaimTabBarIndexNotificationName object:[NSNumber numberWithInteger:2] userInfo:@{@"action":@"showcase"}];
        }
    }
}

#pragma mark - configure
- (void)configureSideBarMenu {
    _sideBarItems = [[OTSideBarItems alloc] initWithStyle:UITableViewStylePlain];
    NSArray *cells = @[@{@"title" : NSLocalizedStringFromTable(@"map_type_standard", @"Additional", nil)},
                       @{@"title" : NSLocalizedStringFromTable(@"map_type_satellite", @"Additional", nil)},
                       @{@"title" : NSLocalizedStringFromTable(@"map_type_hybird", @"Additional", nil)},
                       @{@"title" : NSLocalizedString(@"map_provider_google_normal", nil)},
                       @{@"title" : NSLocalizedString(@"map_provider_google_hybrid", nil)},
                       @{@"title" : NSLocalizedString(@"map_provider_google_satellite", nil)},
                       @{@"title" : NSLocalizedString(@"map_provider_google_terrain", nil)},
                       @{@"title" : NSLocalizedString(@"map_provider_osm_mapnik", nil)},
                       @{@"title" : NSLocalizedString(@"map_provider_osm_mapquest", nil)},
                       @{@"title" : NSLocalizedString(@"map_provider_local_tiles", nil)},
                       @{@"title" : NSLocalizedString(@"map_provider_geoserver", nil)}];
    
    [_sideBarItems setCells:cells];
    __strong typeof(self) self_ = self;
    _sideBarItems.itemAction = ^void(NSInteger section, NSInteger itemIndex) {
        switch (itemIndex) {
            case 0: {
                if ([self_.mapView.overlays containsObject:self_->tileOverlay])
                    [self_.mapView removeOverlay:self_->tileOverlay];
                
                [self_.mapView setMapType:MKMapTypeStandard];
                
                [self_ configureMapTypeLabelForTitle:[[cells objectAtIndex:itemIndex] objectForKey:@"title"] message:nil];
                break;
            }
            case 1:
                if ([self_.mapView.overlays containsObject:self_->tileOverlay])
                    [self_.mapView removeOverlay:self_->tileOverlay];
                
                [self_.mapView setMapType:MKMapTypeSatellite];
                
                [self_ configureMapTypeLabelForTitle:[[cells objectAtIndex:itemIndex] objectForKey:@"title"] message:nil];
                break;
                
            case 2:
                if ([self_.mapView.overlays containsObject:self_->tileOverlay])
                    [self_.mapView removeOverlay:self_->tileOverlay];
                
                [self_.mapView setMapType:MKMapTypeHybrid];
                
                [self_ configureMapTypeLabelForTitle:[[cells objectAtIndex:itemIndex] objectForKey:@"title"] message:nil];
                break;
                
            case 3: {
                if ([self_.mapView.overlays containsObject:self_->tileOverlay]) {
                    [self_.mapView removeOverlay:self_->tileOverlay];
                    [self_.mapView setNeedsDisplay];
                }
                [self_.mapView setMapType:MKMapTypeStandard];
                CGFloat scale = [[UIScreen mainScreen] scale];
                NSString *urlTemplate = @"http://mts0.google.com/vt/lyrs=m,r?x={x}&y={y}&z={z}&scale={scale}";
                if (scale > 2.0) {
                    urlTemplate = @"http://mts0.google.com/vt/lyrs=m,r?x={x}&y={y}&z={z}&scale=2";
                    scale = 2.0;
                }
                self_->tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:urlTemplate];
                [self_->tileOverlay setCanReplaceMapContent:YES];
                CGSize tileSize = [self_->tileOverlay tileSize];
                tileSize.height *= scale;
                tileSize.width *= scale;
                [self_->tileOverlay setTileSize:tileSize];
                [self_.mapView insertOverlay:self_->tileOverlay belowOverlay:self_.shapes];
                
                [self_ configureMapTypeLabelForTitle:[[cells objectAtIndex:itemIndex] objectForKey:@"title"] message:nil];
                break;
            }
            case 4: {
                if ([self_.mapView.overlays containsObject:self_->tileOverlay]) {
                    [self_.mapView removeOverlay:self_->tileOverlay];
                    [self_.mapView setNeedsDisplay];
                }
                [self_.mapView setMapType:MKMapTypeStandard];
                CGFloat scale = [[UIScreen mainScreen] scale];
                NSString *urlTemplate = @"http://mts0.google.com/vt/lyrs=s,l,r&x={x}&y={y}&z={z}&scale={scale}";
                if (scale > 2.0) {
                    urlTemplate = @"http://mts0.google.com/vt/lyrs=s,l,r&x={x}&y={y}&z={z}&scale=2";
                    scale = 2.0;
                }
                self_->tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:urlTemplate];
                [self_->tileOverlay setCanReplaceMapContent:YES];
                CGSize tileSize = [self_->tileOverlay tileSize];
                tileSize.height *= scale;
                tileSize.width *= scale;
                [self_->tileOverlay setTileSize:tileSize];
                [self_.mapView insertOverlay:self_->tileOverlay belowOverlay:self_.shapes];
                
                [self_ configureMapTypeLabelForTitle:[[cells objectAtIndex:itemIndex] objectForKey:@"title"] message:nil];
                break;
            }
            case 5: {
                if ([self_.mapView.overlays containsObject:self_->tileOverlay]) {
                    [self_.mapView removeOverlay:self_->tileOverlay];
                    [self_.mapView setNeedsDisplay];
                }
                [self_.mapView setMapType:MKMapTypeStandard];
                CGFloat scale = [[UIScreen mainScreen] scale];
                NSString *urlTemplate = @"http://mts0.google.com/vt/lyrs=s&x={x}&y={y}&z={z}&scale={scale}";
                if (scale > 2.0) {
                    urlTemplate = @"http://mts0.google.com/vt/lyrs=s&x={x}&y={y}&z={z}&scale=2";
                    scale = 2.0;
                }
                self_->tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:urlTemplate];
                [self_->tileOverlay setCanReplaceMapContent:YES];
                CGSize tileSize = [self_->tileOverlay tileSize];
                tileSize.height *= scale;
                tileSize.width *= scale;
                [self_->tileOverlay setTileSize:tileSize];
                [self_.mapView insertOverlay:self_->tileOverlay belowOverlay:self_.shapes];
                
                [self_ configureMapTypeLabelForTitle:[[cells objectAtIndex:itemIndex] objectForKey:@"title"] message:nil];
                break;
            }
            case 6: {
                if ([self_.mapView.overlays containsObject:self_->tileOverlay]) {
                    [self_.mapView removeOverlay:self_->tileOverlay];
                    [self_.mapView setNeedsDisplay];
                }
                [self_.mapView setMapType:MKMapTypeStandard];
                CGFloat scale = [[UIScreen mainScreen] scale];
                NSString *urlTemplate = @"http://mts0.google.com/vt/lyrs=t,r&x={x}&y={y}&z={z}&scale={scale}";
                if (scale > 2.0) {
                    urlTemplate = @"http://mts0.google.com/vt/lyrs=t,r&x={x}&y={y}&z={z}&scale=2";
                    scale = 2.0;
                }
                self_->tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:urlTemplate];
                [self_->tileOverlay setCanReplaceMapContent:YES];
                CGSize tileSize = [self_->tileOverlay tileSize];
                tileSize.height *= scale;
                tileSize.width *= scale;
                [self_->tileOverlay setTileSize:tileSize];
                [self_.mapView insertOverlay:self_->tileOverlay belowOverlay:self_.shapes];
                
                [self_ configureMapTypeLabelForTitle:[[cells objectAtIndex:itemIndex] objectForKey:@"title"] message:nil];
                break;
            }
            case 7: {
                if ([self_.mapView.overlays containsObject:self_->tileOverlay]) {
                    [self_.mapView removeOverlay:self_->tileOverlay];
                    [self_.mapView setNeedsDisplay];
                }
                [self_.mapView setMapType:MKMapTypeStandard];
                
                NSString *urlTemplate = @"http://otile1.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png";
                self_->tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:urlTemplate];
                [self_->tileOverlay setCanReplaceMapContent:YES];
                [self_.mapView insertOverlay:self_->tileOverlay belowOverlay:self_.shapes];
                
                [self_ configureMapTypeLabelForTitle:[[cells objectAtIndex:itemIndex] objectForKey:@"title"] message:nil];
                break;
            }
            case 8: {
                if ([self_.mapView.overlays containsObject:self_->tileOverlay]) {
                    [self_.mapView removeOverlay:self_->tileOverlay];
                    [self_.mapView setNeedsDisplay];
                }
                [self_.mapView setMapType:MKMapTypeStandard];
                
                NSString *urlTemplate = @"http://otile2.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.png";
                self_->tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:urlTemplate];
                [self_->tileOverlay setCanReplaceMapContent:YES];
                [self_.mapView insertOverlay:self_->tileOverlay belowOverlay:self_.shapes];
                
                [self_ configureMapTypeLabelForTitle:[[cells objectAtIndex:itemIndex] objectForKey:@"title"] message:nil];
                break;
            }
            case 9: { // Offline
                if ([self_.mapView.overlays containsObject:self_->tileOverlay]) {
                    [self_.mapView removeOverlay:self_->tileOverlay];
                    [self_.mapView setNeedsDisplay];
                }
                [self_.mapView setMapType:MKMapTypeStandard];
                
                self_->tileOverlay = [[OTWMSTileOverlay alloc] initWithWMSUrlString:[OTSetting getGeoServerURL] layers:[OTSetting getGeoServerLayers] tileSize:CGSizeMake(TILE_SIZE, TILE_SIZE)];
                [self_->tileOverlay setOffline:YES];
                [self_->tileOverlay setCanReplaceMapContent:YES];
                [self_.mapView insertOverlay:self_->tileOverlay belowOverlay:self_.shapes];
                
                [self_ configureMapTypeLabelForTitle:[[cells objectAtIndex:itemIndex] objectForKey:@"title"] message:nil];
                break;
            }
            case 10: { // Online
                if ([self_.mapView.overlays containsObject:self_->tileOverlay]) {
                    [self_.mapView removeOverlay:self_->tileOverlay];
                    [self_.mapView setNeedsDisplay];
                }
                [self_.mapView setMapType:MKMapTypeStandard];
                
                self_->tileOverlay = [[OTWMSTileOverlay alloc] initWithWMSUrlString:[OTSetting getGeoServerURL] layers:[OTSetting getGeoServerLayers] tileSize:CGSizeMake(TILE_SIZE, TILE_SIZE)];
                [self_->tileOverlay setOffline:NO];
                [self_->tileOverlay setCanReplaceMapContent:YES];
                [self_.mapView insertOverlay:self_->tileOverlay belowOverlay:self_.shapes];
                
                [self_ configureMapTypeLabelForTitle:[[cells objectAtIndex:itemIndex] objectForKey:@"title"] message:nil];
                break;
            }
        }
        [self_.sideBarMenu dismiss];
    };

    self.sideBarMenu = [[CDRTranslucentSideBar alloc] initWithDirectionFromRight:YES];
    [self.sideBarMenu setTranslucent:YES];
    self.sideBarMenu.translucentStyle = UIBarStyleDefault;
    self.sideBarMenu.tag = 1;
    [self.sideBarMenu setSideBarWidth:260];
    [self.sideBarMenu setContentViewInSideBar:_sideBarItems.tableView];
}

- (void)configureCommunityArea {
    if (![OTSetting getInitialization]) return;
    if (communityArea != nil)
        [_mapView removeOverlay:communityArea];
    // Update community area
    NSString *polygonCommunityArea = [OTSetting getCommunityArea];
    ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:polygonCommunityArea];
    if (polygon.geometry != nil) {
        communityArea = polygon.geometry;
        [_mapView insertOverlay:communityArea aboveOverlay:_shapes];
        if (_claim == nil || _claim.mappedGeometry == nil)
            [_mapView setVisibleMapRect:polygon.geometry.boundingMapRect animated:YES];
    }
}

- (void)configureNotifications {
    // Add a observer to receive notification when the CommunityServerAPI get all claims successful
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getAllClaimsActionSuccessful:) name:kGetAllClaimsSuccessNotificationName object:nil];
    
    // Add a observer to receive notification when the CommunityServerAPI get one claim successful
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getClaimActionSuccessful:) name:kGetClaimSuccessNotificationName object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:dataContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseDidSave:) name:NSManagedObjectContextDidSaveNotification object:dataContext];
}

/*!
 Quản lý thao tác nhấn giữ trên map
 */
- (void)configureGestures {
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    //user needs to press for 0.5 seconds
    lpgr.minimumPressDuration = 0.5;
    [_mapView addGestureRecognizer:lpgr];
}

- (UIButton *)createButtonWithFrame:(CGRect)frame
                                tag:(NSInteger)tag
                             action:(SEL)action
                          imageName:(NSString *)imageName {
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
//    button.layer.borderColor = [UIColor otDarkBlue].CGColor;
//    button.layer.borderWidth = 0.2;
//    button.layer.cornerRadius = 5;
    button.tag = tag;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    return button;
}

- (void)configureDashboard {
    // Show marker control
    self.dashboardMenu = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 32)];
    
    CGRect frame = CGRectMake(0, 0, 32, 32);
    UIButton *buttonActionRemove = [self createButtonWithFrame:frame
                                                           tag:0
                                                        action:@selector(dashboardMenuAction:)
                                                     imageName:@"ic_action_remove"];
    
    frame.origin.x = 64;
    UIButton *buttonActionMove = [self createButtonWithFrame:frame
                                                         tag:1
                                                      action:@selector(dashboardMenuAction:)
                                                   imageName:@"ic_action_move"];
    
    frame.origin.x = 128;
    UIButton *buttonActionBlock = [self createButtonWithFrame:frame
                                                          tag:2
                                                       action:@selector(dashboardMenuAction:)
                                                    imageName:@"ic_action_block"];
    
    [_dashboardMenu addSubview:buttonActionRemove];
    [_dashboardMenu addSubview:buttonActionMove];
    [_dashboardMenu addSubview:buttonActionBlock];
    
    // Moving dashboard:
    
    self.dashboardAction = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 224)];

    // Close button
    UIButton *buttonActionBlock1 = [self createButtonWithFrame:frame
                                                           tag:2
                                                        action:@selector(dashboardMenuAction:)
                                                     imageName:@"ic_action_block"];

    // Goto button
    frame.origin.x = 64;
    UIButton *buttonActionGoto = [self createButtonWithFrame:frame
                                                         tag:3
                                                      action:@selector(dashboardMenuAction:)
                                                   imageName:@"ic_action_goto"];

    // Add button
    frame.origin.x = 0;
    UIButton *buttonActionAdd = [self createButtonWithFrame:frame
                                                        tag:4
                                                     action:@selector(dashboardMenuAction:)
                                                  imageName:@"ic_action_add"];

    // Move to the left button
    frame.origin.x = 0;
    frame.origin.y = 128;
    UIButton *buttonActionLeft = [self createButtonWithFrame:frame
                                                         tag:5
                                                      action:@selector(dashboardMenuAction:)
                                                   imageName:@"ic_action_left"];
    
    // Move to up button
    frame.origin.x = 64;
    frame.origin.y = 64;
    UIButton *buttonActionUp = [self createButtonWithFrame:frame
                                                       tag:6
                                                    action:@selector(dashboardMenuAction:)
                                                 imageName:@"ic_action_up"];

    // Move to the right button
    frame.origin.x = 128;
    frame.origin.y = 128;
    UIButton *buttonActionRight = [self createButtonWithFrame:frame
                                                          tag:7
                                                       action:@selector(dashboardMenuAction:)
                                                    imageName:@"ic_action_right"];

    // Move to down button
    frame.origin.x = 64;
    frame.origin.y = 192;
    UIButton *buttonActionDown = [self createButtonWithFrame:frame
                                                         tag:8
                                                      action:@selector(dashboardMenuAction:)
                                                   imageName:@"ic_action_down"];

    [_dashboardAction addSubview:buttonActionBlock1];
    [_dashboardAction addSubview:buttonActionGoto];
    [_dashboardAction addSubview:buttonActionAdd];
    [_dashboardAction addSubview:buttonActionLeft];
    [_dashboardAction addSubview:buttonActionUp];
    [_dashboardAction addSubview:buttonActionRight];
    [_dashboardAction addSubview:buttonActionDown];
}

- (void)updateDashboard {
    if (_dashboardMenuShowing) {
        CGRect frame = [_selectedMarkerView frame];
        frame.origin.x -= 64;
        frame.origin.y += 64;
        frame.size.width = 160;
        frame.size.height = 32;
        _dashboardMenu.frame = frame;
        [self.mapView addSubview:_dashboardMenu];
        
        // Add red marker
        if (_redMarkerView == nil) {
            _redMarkerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ot_red_marker"]];
            _redMarkerView.userInteractionEnabled = NO;
        }
        [_selectedMarkerView addSubview:_redMarkerView];
    }
    if (_dashboardActionShowing) {
        CGRect frame = [_selectedMarkerView frame];
        frame.origin.x -= 64;
        frame.origin.y += 64;
        frame.size.width = 160;
        frame.size.height = 224;
        _dashboardAction.frame = frame;
        [self.mapView addSubview:_dashboardAction];
    }
}

- (void)closeDashboard {
    [_mapView deselectAnnotation:[_selectedMarkerView annotation] animated:YES];
    _dashboardMenuShowing = NO;
    [_dashboardMenu removeFromSuperview];
    
    _dashboardActionShowing = NO;
    [_dashboardAction removeFromSuperview];

    [workingVertex setDragging:NO];
    workingVertex = nil;
    workingAnnotationView = nil;
    _selectedMarkerView = nil;
    [_mapView removeAnnotation:_customAnnotation];
    
    // Remove red marker
    [_redMarkerView removeFromSuperview];
}

- (IBAction)dashboardMenuAction:(id)sender {
    UIButton *button = (UIButton *)sender;
    double tolerance = 30;
    MKZoomScale zoomScale = _mapView.bounds.size.width / _mapView.visibleMapRect.size.width;
    double roadWith = MKRoadWidthAtZoomScale(zoomScale);
    MKMapPoint point = MKMapPointForCoordinate(_customAnnotation.coordinate);
    MKMapRect mapRect = MKMapRectMake(point.x, point.y, roadWith/tolerance, roadWith/tolerance);
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
    CLLocationCoordinate2D coordinate = _customAnnotation.coordinate;

    switch (button.tag) {
        case 0: // Remove marker
            if ([[_selectedMarkerView annotation] accessibilityValue] != nil) {
                [self updateNotBoundaryWithAnnotation:[_selectedMarkerView annotation] remove:YES];
            } else {
                [self updatePolygonAnnotations:[_selectedMarkerView annotation] remove:YES];
            }
            _dashboardMenuShowing = NO;
            [_dashboardMenu removeFromSuperview];
            break;
            
        case 1: // Show action dashboard
            _dashboardMenuShowing = NO;
            [_dashboardMenu removeFromSuperview];
            _dashboardActionShowing = YES;
            [self updateDashboard];
            //Add marker
            [self updateCustomMarkerState:YES];
            [_mapView selectAnnotation:_customAnnotation animated:YES];
            _customAnnotation.subtitle = @"";
            break;
        
        case 2: // Close dashboard
            [self closeDashboard];
            break;
            
        case 3: { // Goto action
            [[_selectedMarkerView annotation] setCoordinate:_customAnnotation.coordinate];
            NSString *objectIDString = [[_selectedMarkerView annotation] accessibilityValue];
            if (objectIDString != nil) { // Not boundary marker
                for (Location *location in _claim.locations) {
                    if ([objectIDString isEqualToString:[location.objectID.URIRepresentation lastPathComponent]]) {
                        ShapeKitPoint *point = [[ShapeKitPoint alloc] initWithCoordinate:_customAnnotation.coordinate];
                        location.mappedLocation = point.wktGeom;
                    }
                }
            } else {
                workingVertex.latitude = _customAnnotation.coordinate.latitude;
                workingVertex.longitude = _customAnnotation.coordinate.longitude;
                [self updateOverlay:_shapes];
            }
            break;
        }
        case 4: { // Add action
            if (_claim.getViewType == OTViewTypeAdd) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_save_claim_before_adding_content", nil)];
            } else if (_claim.getViewType == OTViewTypeView) {
                return;
            } else {
                MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
                point.coordinate = _customAnnotation.coordinate;
                point.isAccessibilityElement = YES;
                GeoShapeVertex *test = [[GeoShapeVertex alloc] initWithLatitude:point.coordinate.latitude longitude:point.coordinate.longitude];
                if (![test isEqual:workingVertex]) {   
                    [self confirmAddingMarkerFromAnnotation:point];
                    [self closeDashboard];
                }
            }
            break;
        }
        case 5: { // Move to the left
            coordinate.longitude -= region.span.longitudeDelta;
            _customAnnotation.title = [NSString stringWithFormat:@"{Lat: %.10f, Lon: %.10f}", coordinate.latitude, coordinate.longitude];
            CLLocationCoordinate2D baseCoordinate = [[_selectedMarkerView annotation] coordinate];
            CLLocation *localtion1 = [[CLLocation alloc] initWithLatitude:baseCoordinate.latitude longitude:baseCoordinate.longitude];
            CLLocation *localtion2 = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
            CLLocationDistance distance = [localtion2 distanceFromLocation:localtion1];
            _customAnnotation.subtitle = [NSString stringWithFormat:@"Distance: %.3f", distance];
            
            [_customAnnotation setCoordinate:coordinate];
            break;
        }
        case 6: {// Move to go up
            coordinate.latitude += region.span.latitudeDelta;
            
            _customAnnotation.title = [NSString stringWithFormat:@"{Lat: %.10f, Lon: %.10f}", coordinate.latitude, coordinate.longitude];
            CLLocationCoordinate2D baseCoordinate = [[_selectedMarkerView annotation] coordinate];
            CLLocation *localtion1 = [[CLLocation alloc] initWithLatitude:baseCoordinate.latitude longitude:baseCoordinate.longitude];
            CLLocation *localtion2 = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
            CLLocationDistance distance = [localtion2 distanceFromLocation:localtion1];
            _customAnnotation.subtitle = [NSString stringWithFormat:@"Distance: %.3f", distance];

            [_customAnnotation setCoordinate:coordinate];
            break;
        }
        case 7: {// Move to the right
            coordinate.longitude += region.span.longitudeDelta;
            
            _customAnnotation.title = [NSString stringWithFormat:@"{Lat: %.10f, Lon: %.10f}", coordinate.latitude, coordinate.longitude];
            CLLocationCoordinate2D baseCoordinate = [[_selectedMarkerView annotation] coordinate];
            CLLocation *localtion1 = [[CLLocation alloc] initWithLatitude:baseCoordinate.latitude longitude:baseCoordinate.longitude];
            CLLocation *localtion2 = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
            CLLocationDistance distance = [localtion2 distanceFromLocation:localtion1];
            _customAnnotation.subtitle = [NSString stringWithFormat:@"Distance: %.3f", distance];
            
            [_customAnnotation setCoordinate:coordinate];
            break;
        }
        case 8: { // Move to go down
            coordinate.latitude -= region.span.latitudeDelta;
            
            _customAnnotation.title = [NSString stringWithFormat:@"{Lat: %.10f, Lon: %.10f}", coordinate.latitude, coordinate.longitude];
            CLLocationCoordinate2D baseCoordinate = [[_selectedMarkerView annotation] coordinate];
            CLLocation *localtion1 = [[CLLocation alloc] initWithLatitude:baseCoordinate.latitude longitude:baseCoordinate.longitude];
            CLLocation *localtion2 = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
            CLLocationDistance distance = [localtion2 distanceFromLocation:localtion1];
            _customAnnotation.subtitle = [NSString stringWithFormat:@"Distance: %.3f", distance];

            [_customAnnotation setCoordinate:coordinate];
            break;
        }
    }
}

- (void)updateCustomMarkerState:(BOOL)state {
    if (!state) { // remove
        if (_customAnnotation) [_mapView removeAnnotation:_customAnnotation];
        return;
    }
    if (_customAnnotation == nil) _customAnnotation = [[MKPointAnnotation alloc] init];
    _customAnnotation.coordinate = [[_selectedMarkerView annotation] coordinate];
    _customAnnotation.title = [NSString stringWithFormat:@"{Lat: %.10f, Lon: %.10f}", _customAnnotation.coordinate.latitude, _customAnnotation.coordinate.longitude];
    _customAnnotation.accessibilityLabel = @"OTAnnotationView1";
    [_mapView addAnnotation:_customAnnotation];
}

#pragma handler touch on the map

- (IBAction)handleLongPress:(id)sender {
    if (_claim.getViewType == OTViewTypeAdd) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_save_claim_before_adding_content", nil)];
    } else if (_claim.getViewType == OTViewTypeView) {
        return;
    } else {
        UIGestureRecognizer *gestureRecognizer = sender;
        if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
            return;

        CGPoint touchPoint = [gestureRecognizer locationInView:_mapView];
        CLLocationCoordinate2D touchMapCoordinate = [_mapView convertPoint:touchPoint toCoordinateFromView:_mapView];
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        point.coordinate = touchMapCoordinate;
        point.isAccessibilityElement = YES;
        [self confirmAddingMarkerFromAnnotation:point];
    }
}

- (void)confirmAddingMarkerFromAnnotation:(MKPointAnnotation *)point {
    NSString *coordinateString = [NSString stringWithFormat:@"{Lat: %f, Lon: %f}", point.coordinate.latitude, point.coordinate.longitude];
    point.subtitle = coordinateString;
    NSString *alertTitle = NSLocalizedString(@"message_add_marker", nil);
    NSString *alertMessage = coordinateString;
    NSString *cancelButtonTitle = NSLocalizedString(@"cancel", nil);
    NSArray *otherButtonTitles = @[NSLocalizedString(@"not_boundary", nil), NSLocalizedString(@"confirm", nil)];
    [UIAlertView showWithTitle:alertTitle
                       message:alertMessage
             cancelButtonTitle:cancelButtonTitle
             otherButtonTitles:otherButtonTitles tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                 if (buttonIndex == 1) { // Not boundary
                     [self updateNotBoundaryWithAnnotation:point remove:NO];
                 } else if (buttonIndex == 2) { // Boundary
                     [self updatePolygonAnnotations:point remove:NO];
                 }
             }];
}

- (void)updatePolygonAnnotations:(MKPointAnnotation *)point remove:(BOOL)remove {
    if (_shapes.workingOverlay == nil) {
        // Tạo mới shape
        GeoShape *shape = [_shapes createShapeWithCenterCoordinate:point.coordinate];
        [_shapes setWorkingOverlay:shape];
        shape.title = [[NSUUID UUID] UUIDString];
        shape.subtitle = [[NSDate date] description];
        point.title = @"1";
        [_mapView addAnnotation:point];
        [_workingAnnotations addObject:point];
    } else {
        MKZoomScale currentZoomScale = _mapView.bounds.size.width / _mapView.visibleMapRect.size.width;
        if (!remove) {
            NSInteger tag = [_shapes addPointToWorkingOverlay:point.coordinate currentZoomScale:currentZoomScale];
            point.title = [@(tag) stringValue];
            [_mapView addAnnotation:point];
            [_workingAnnotations addObject:point];
        } else {
            [_shapes removePointFromWorkingOverlay:point.coordinate];
            [_mapView removeAnnotation:point];
            [self updateOverlay:_shapes];
            [_workingAnnotations removeObject:point];
            ALog(@"Working annotations count : %tu", _workingAnnotations.count);
        }
    }
    [self updateOverlay:_shapes];
}

- (void)updateNotBoundaryWithAnnotation:(MKPointAnnotation *)point remove:(BOOL)remove {
    if (!remove) {
        NSString *alertTitle = NSLocalizedString(@"title_add_non_boundary", nil);
        NSString *alertMessage = NSLocalizedString(@"message_enter_description", nil);
        NSString *cancelButtonTitle = NSLocalizedString(@"cancel", nil);
        NSArray *otherButtonTitles = @[NSLocalizedString(@"confirm", nil)];

        [UIAlertView showWithTitle:alertTitle
                           message:alertMessage
                             style:UIAlertViewStylePlainTextInput
                 cancelButtonTitle:cancelButtonTitle
                 otherButtonTitles:otherButtonTitles
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex != alertView.cancelButtonIndex) {
                                  NSString *title = [[alertView textFieldAtIndex:0] text];
                                  LocationEntity *locationEntity = [[LocationEntity alloc] init];
                                  [locationEntity setManagedObjectContext:_claim.managedObjectContext];
                                  Location *location = [locationEntity create];
                                  location.locationId = [[[NSUUID UUID] UUIDString] lowercaseString];
                                  location.claimId = _claim.claimId;
                                  location.claim = _claim;
                                  
                                  location.note = title;
                                  
                                  ShapeKitPoint *gpsPoint = [[ShapeKitPoint alloc] initWithCoordinate:_mapView.userLocation.coordinate];
                                  location.gpsLocation = gpsPoint.wktGeom;
                                  ShapeKitPoint *mappedPoint = [[ShapeKitPoint alloc] initWithCoordinate:point.coordinate];
                                  location.mappedLocation = mappedPoint.wktGeom;
                                  [location.managedObjectContext save:nil];
                                  
                                  point.title = title;
                                  point.accessibilityHint = @"AdditionalAnnotation";
                                  point.accessibilityValue = [location.objectID.URIRepresentation lastPathComponent];
                                  
                                  [_mapView addAnnotation:point];
                                  [_workingAnnotations addObject:point];
                              }
                          }];
    } else {
        [_additionalMarkers removeObject:point];
        [_mapView removeAnnotation:point];
        Location *locationToRemove = nil;
        for (Location *location in _claim.locations) {
            if ([point.accessibilityValue isEqualToString:[location.objectID.URIRepresentation lastPathComponent]]) {
                locationToRemove = location;
                break;
            }
        }
        if (locationToRemove != nil) {
            [_claim removeLocationsObject:locationToRemove];
        }
    }
}

- (void)updateOverlay:(id<MKOverlay>)overlay {
    [[NSOperationQueue new] addOperationWithBlock:^{
        [_shapes.workingOverlay updatePoints]; // Cập nhật lại điểm cho workingOverlay
        GeoShapeOverlayRenderer *overlayRenderer = (GeoShapeOverlayRenderer *)[_mapView rendererForOverlay:overlay];
        MKMapRect mapRect = [_shapes.workingOverlay boundingMapRect];
        [overlayRenderer setNeedsDisplayInMapRect:mapRect];
    }];
    TBClusterAnnotation *label = [[TBClusterAnnotation alloc] initWithCoordinate:_shapes.workingOverlay.coordinate count:1];
    label.title = _claim.claimName;
}

- (void)addAnnotation:(MKPointAnnotation *)annotation {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_mapView addAnnotation:annotation];
        [_workingAnnotations addObject:annotation];
    });
}

#pragma handler notifications

/*!
 Receive notification when the CommunityServerAPI get all new claims successful.
 @result
 New claims list to add or update
 */
- (void)getAllClaimsActionSuccessful:(NSNotification *)notification {
    NSMutableArray *objects = [notification object];
    if (objects.count > 0) {
        _totalItemsToDownload = objects.count;
        _totalItemsDownloaded = 0;
        _totalItemsDownloadError = 0;
        [self setDownloading:YES];
        [SVProgressHUD showProgress:0.0
                             status:NSLocalizedString(@"title_claim__downloading_map", nil)
                           maskType:SVProgressHUDMaskTypeGradient];
        // <
        NSMutableArray *operations = [NSMutableArray array];
        for (NSString *claimId in objects) {
            DownloadClaimTask *downloadClaimTask = [[DownloadClaimTask alloc] initWithClaimId:claimId];
            downloadClaimTask.delegate = self;
            [operations addObject:downloadClaimTask];
        }
        [self.parseQueue addOperations:operations waitUntilFinished:NO];
        // >
    } else {
        [SVProgressHUD dismiss];
    }
}

/*!
 Receive notification when the CommunityServerAPI get one claim successful
 */
- (void)getClaimActionSuccessful:(NSNotification *)notification {
    _totalItemsDownloaded += 1;
    double progress = (double)_totalItemsDownloaded / (double)_totalItemsToDownload;
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showProgress:progress
                             status:NSLocalizedString(@"title_claim__downloading_map", nil)
                           maskType:SVProgressHUDMaskTypeGradient];
    });
    if (progress >= 1.0) {
        dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"message_claims_downloaded", @"Claims correctly downloaded")];
        });
        // Update quad tree for clustering
        [_coordinateQuadTree buildTreeFromAnnotations:_annotations];
        [self mapView:_mapView regionDidChangeAnimated:NO];
    }
}

- (void)databaseDidChange:(NSNotification *)notification {
    if (_handleDeletedClaims == nil) _handleDeletedClaims = [NSMutableArray array];
    [_handleDeletedClaims removeAllObjects];
    if (_handleDeletedAttachments == nil) _handleDeletedAttachments = [NSMutableArray array];
    [_handleDeletedAttachments removeAllObjects];
    if (_handleDeletedPersons == nil) _handleDeletedPersons = [NSMutableArray array];
    [_handleDeletedPersons removeAllObjects];
    NSMutableArray *deletedObjects = [NSMutableArray arrayWithArray:[[dataContext deletedObjects] allObjects]];
    NSUInteger n = [deletedObjects count];
    if (n > 0) {
        for (NSManagedObject *object in deletedObjects) {
            if ([object isKindOfClass:[Claim class]]) {
                [_handleDeletedClaims addObject:object];
            }
            if ([object isKindOfClass:[Attachment class]]) {
                [_handleDeletedAttachments addObject:object];
            }
            if ([object isKindOfClass:[Person class]]) {
                [_handleDeletedPersons addObject:object];
            }
        }
    }
}

- (void)databaseDidSave:(NSNotification *)notification {
    for (Person *person in _handleDeletedPersons) {
        BOOL success = [FileSystemUtilities deleteClaimant:person.personId];
        ALog(@"Delete claimamt folder: %d", success);
    }
    for (Claim *claim in _handleDeletedClaims) {
        // Xóa annotation
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(uuid CONTAINS[cd] %@)", claim.claimId];
        TBClusterAnnotation *annotation = [[_annotations filteredArrayUsingPredicate:predicate] firstObject];
        if (annotation != nil) {
            [_annotations removeObject:annotation];
            [_mapView removeAnnotation:annotation];
        }
        BOOL success = [FileSystemUtilities deleteClaim:claim.claimId];
        ALog(@"Delete claim folder: %d", success);
    }
    [_handleDeletedClaims removeAllObjects];
    [_handleDeletedAttachments removeAllObjects];
    [_handleDeletedPersons removeAllObjects];
    [_coordinateQuadTree buildTreeFromAnnotations:_annotations];
}

- (void)configureGeoShape:(GeoShape *)shape forClaim:(Claim *)object {
    shape.title = object.claimId;
    if ([object.statusCode isEqualToString:@"unmoderated"]) {
        shape.strokeColor = [UIColor colorWithRed:1.0f green:204.0f/255.0f blue:0.0f alpha:1.0f];
    }
    if ([object.statusCode isEqualToString:@"withdrawn"]) {
        shape.strokeColor = [UIColor otEarth];
        shape.lineWidth = 1.0;
        shape.fillColor = [UIColor clearColor];
    }
    if ([object.statusCode isEqualToString:@"reviewed"]) {
        shape.strokeColor = [UIColor greenColor];
        shape.lineWidth = 1.0;
        shape.fillColor = [UIColor clearColor];
    }
    if ([object.statusCode isEqualToString:@"moderated"]) {
        shape.strokeColor = [UIColor otGreen];
        shape.lineWidth = 1.0;
        shape.fillColor = [UIColor clearColor];
    }
    if ([object.statusCode isEqualToString:@"created"]) {
        shape.strokeColor = [UIColor otDarkBlue];
        shape.lineWidth = 1.0;
        shape.fillColor = [UIColor clearColor];
    }
}

/*!
 Vẽ tất cả các mappedGeometrys của claim đang có lên map. Gọi một lần ở viewDidload
 */
- (void)drawMappedGeometry {
    [SVProgressHUD show];
    id collection = [ClaimEntity getCollection];
    
    for (Claim *object in collection) {
        [self processClaim:object];
    }
    [_shapes setWorkingOverlay:nil];
    // Cập nhật hiển thị điểm
    [_coordinateQuadTree buildTreeFromAnnotations:_annotations];
    [self mapView:_mapView regionDidChangeAnimated:NO];
    [SVProgressHUD dismiss];
}

#pragma Bar Buttons Action

- (IBAction)zoomToCommunityArea:(id)sender {
    if ([OTSetting getInitialization]) {
        [self configureCommunityArea];
    } else {
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"message_app_not_yet_initialized", nil)];
    }
}

/*!
 Download all new claims by current map rect.
 @result
 Send broadcasting information
 */
- (IBAction)downloadClaims:(id)sender {
    
    if ([self isDownloading]) return;
    
    if (![OTAppDelegate authenticated]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedStringFromTable(@"message_login_before", @"ActivityLogin", nil)];
        return;
    }

    self.parseQueue = [NSOperationQueue new];
    
    // observe the keypath change to get notified of the end of the parser operation to hide the activity indicator
    [self.parseQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];

    MKMapRect mRect = _mapView.visibleMapRect;
    MKMapPoint neMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), mRect.origin.y);
    MKMapPoint swMapPoint = MKMapPointMake(mRect.origin.x, MKMapRectGetMaxY(mRect));
    CLLocationCoordinate2D neCoord = MKCoordinateForMapPoint(neMapPoint);
    CLLocationCoordinate2D swCoord = MKCoordinateForMapPoint(swMapPoint);

    NSArray *coords = [NSArray arrayWithObjects:
                       [NSNumber numberWithDouble:swCoord.longitude],
                       [NSNumber numberWithDouble:swCoord.latitude],
                       [NSNumber numberWithDouble:neCoord.longitude],
                       [NSNumber numberWithDouble:neCoord.latitude], nil];
    [SVProgressHUD showWithStatus:NSLocalizedString(@"title_claim__downloading_map", @"Downloading Claims")];
    [CommunityServerAPI getAllClaimsByBox:coords completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSMutableArray *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                NSArray *newClaimIds = [self getValidClaimsToDownload:objects];
                if (newClaimIds.count > 0) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGetAllClaimsSuccessNotificationName object:newClaimIds];
                } else {
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"message_no_claim_to_download", nil)];
                }
            } else {
                NSString *errorString = NSLocalizedString(@"error_generic_conection", @"An error has occurred during connection");
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [OT handleError:reportError];
            }
        }
    }];
}

- (UIImage *)screenshot {
    UIGraphicsBeginImageContextWithOptions(self.mapView.bounds.size, NO, [UIScreen mainScreen].scale);
    
    [self.mapView drawViewHierarchyInRect:self.mapView.bounds afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (IBAction)mapSnapshot:(id)sender {
    GeoShape *shape = _shapes.workingOverlay;
    [shape updatePoints];
    // Zoom đến polygon
    MKMapRect mapRect = shape.boundingMapRect;
    CGFloat width = mapRect.size.width > mapRect.size.height ? mapRect.size.width : mapRect.size.height;
    mapRect.origin.x -= (width - mapRect.size.width) / 2.0;
    mapRect.origin.y -= (width - mapRect.size.height) / 2.0;
    mapRect.size.width = width;
    mapRect.size.height = width;
    [_mapView setVisibleMapRect:mapRect];
    
    // Lưu claim trước khi snapshot
    [_claim.managedObjectContext save:nil];
    
    [FileSystemUtilities createClaimFolder:_claim.claimId];
    
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    options.region = shape.region;
    options.scale = [UIScreen mainScreen].scale;
    options.size = self.mapView.frame.size;
    
    //MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD show];
    });

    // Kiểm tra phiên bản map attached. Xóa nếu tồn tại bản cũ
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(typeCode.code == %@)", @"cadastralMap"];
    NSSet *cadastralObjects = [_claim.attachments filteredSetUsingPredicate:predicate];

    for (Attachment *attachment in cadastralObjects)
        [_claim.managedObjectContext deleteObject:attachment];
    [_claim.managedObjectContext save:nil];
    
    UIImage *finalImage = [self screenshot];
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize size = finalImage.size;
    float min = size.width < size.height ? size.width : size.height;
    size.height = min * scale;
    size.width = min * scale;
    finalImage = [finalImage cropToSize:size];
    
    NSData *imageData = UIImagePNGRepresentation(finalImage);
    NSNumber *fileSize = [NSNumber numberWithUnsignedInteger:imageData.length];
    NSString *md5 = [imageData md5];
    NSString *fileName = @"_map_.png";
    NSString *file = [[FileSystemUtilities getAttachmentFolder:_claim.claimId] stringByAppendingPathComponent:fileName];
    ALog(@"%@", file);
    [imageData writeToFile:[[[FileSystemUtilities applicationDocumentsDirectory] path] stringByAppendingPathComponent:file] atomically:YES];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:[[[OT dateFormatter] stringFromDate:[NSDate date]] substringToIndex:10] forKey:@"documentDate"];
    [dictionary setValue:@"image/png" forKey:@"mimeType"];
    [dictionary setValue:file  forKey:@"fileName"];
    [dictionary setValue:@"png" forKey:@"fileExtension"];
    [dictionary setValue:[[[NSUUID UUID] UUIDString] lowercaseString] forKey:@"id"];
    [dictionary setValue:fileSize forKey:@"size"];
    [dictionary setValue:md5 forKey:@"md5"];
    [dictionary setValue:kAttachmentStatusCreated forKey:@"status"];
    [dictionary setValue:file forKey:@"filePath"];
    
    [dictionary setValue:@"Map" forKey:@"description"];
    [dictionary setValue:@"cadastralMap" forKey:@"typeCode"];
    
    AttachmentEntity *attachmentEntity = [AttachmentEntity new];
    [attachmentEntity setManagedObjectContext:_claim.managedObjectContext];
    Attachment *attachment = [attachmentEntity create];
    [attachment importFromJSON:dictionary];
    
    attachment.claim = _claim;
    
    predicate = [NSPredicate predicateWithFormat:@"(code == %@)", @"cadastralMap"];
    // Nạp lại sau khi claim đã save
    DocumentTypeEntity *docTypeEntity = [DocumentTypeEntity new];
    [docTypeEntity setManagedObjectContext:_claim.managedObjectContext];
    NSArray *docTypeCollection = [docTypeEntity getCollection];
    
    DocumentType *docType = [[docTypeCollection filteredArrayUsingPredicate:predicate] firstObject];
    attachment.typeCode = docType;
    
    [attachment.managedObjectContext save:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"saved", nil)];
    });
    /*
    [snapshotter startWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
        
        // get the image associated with the snapshot
        
        UIImage *image = snapshot.image;
        
        // Get the size of the final image
        
        CGRect finalImageRect = CGRectMake(0, 0, image.size.width, image.size.height);
        
        // ok, let's start to create our final image
        
        UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
        
        // first, draw the image from the snapshotter
        
        [image drawAtPoint:CGPointMake(0, 0)];
        MKZoomScale currentZoomScale = _mapView.bounds.size.width / _mapView.visibleMapRect.size.width;
        NSMutableArray *overlays = [NSMutableArray arrayWithArray:[_shapes shapesInMapRect:_mapView.visibleMapRect zoomScale:currentZoomScale]];
        [overlays removeObject:shape];
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetStrokeColorWithColor(context, [[UIColor otEarth] CGColor]);
        CGContextSetLineWidth(context, 2.0f);
        CGContextBeginPath(context);
        
        // Vẽ các thửa liền kề
        for (GeoShape *aShape in overlays) {
            CLLocationCoordinate2D *coordinates = aShape.coordinates;
            CGPoint point = [snapshot pointForCoordinate:coordinates[0]];
            CGContextMoveToPoint(context, point.x, point.y);
            for (int i = 1; i < aShape.pointCount; i++) {
                CGPoint point = [snapshot pointForCoordinate:coordinates[i]];
                CGContextAddLineToPoint(context, point.x, point.y);
            }
            CGContextClosePath(context);
        }
        CGContextStrokePath(context);
        
        // Vẽ thửa chính
        CGContextSetStrokeColorWithColor(context, [[UIColor otDarkBlue] CGColor]);
        CLLocationCoordinate2D *coordinates = shape.coordinates;
        for (int i = 0; i < shape.pointCount; i++) {
            CGPoint point = [snapshot pointForCoordinate:coordinates[i]];
            if (i == 0) {
                CGContextMoveToPoint(context, point.x, point.y);
            } else {
                CGContextAddLineToPoint(context, point.x, point.y);
            }
        }
        CGContextClosePath(context);
        
        CGContextStrokePath(context);

        // Vẽ đỉnh của thửa
        MKAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@"CustomAnnotation"];
        UIImage *pinImage = [UIImage imageNamed:@"ot_blue_marker"];
        
        pin.centerOffset = CGPointMake(0, -14);
        
        for (int i = 0; i < shape.pointCount; i++) {
            CGPoint point = [snapshot pointForCoordinate:coordinates[i]];
            if (CGRectContainsPoint(finalImageRect, point)) { // this is too conservative, but you get the idea
                point.x -= 14.5;
                point.y -= 29.0;
                [pinImage drawAtPoint:point];
            }
        }
        
        // Vẽ additional marker
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@"AdditionalAnnotation"];
        pinImage = [UIImage imageNamed:@"ot_orange_marker"];
        
        pin.centerOffset = CGPointMake(0, -14);
        
        for (Location *location in _claim.locations) {
            ShapeKitPoint *shapeKitPoint = [[ShapeKitPoint alloc] initWithWKT:location.mappedLocation];
            CGPoint point = [snapshot pointForCoordinate:shapeKitPoint.geometry.coordinate];
            if (CGRectContainsPoint(finalImageRect, point)) { // this is too conservative, but you get the idea
                point.x -= 14.5;
                point.y -= 29.0;
                [pinImage drawAtPoint:point];
            }
        }

        // Tạo điểm và nhãn cho polygon theo tâm của đường bao.
        TBClusterAnnotation *center = [[TBClusterAnnotation alloc] initWithCoordinate:shape.coordinate count:1];
        center.title = _claim.claimName;
        pinImage = [UIImage imageNamed:@"centroid"];
        CGPoint point = [snapshot pointForCoordinate:center.coordinate];
        if (CGRectContainsPoint(finalImageRect, point)) { // this is too conservative, but you get the idea
            point.x -= 14.5;
            point.y -= 14.5;
            [pinImage drawAtPoint:point];
            
            // Vẽ nhãn
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
            //Set line break mode
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            //Set text alignment
            paragraphStyle.alignment = NSTextAlignmentCenter;
            NSShadow *shadow = [[NSShadow alloc] init];
            shadow.shadowColor = [UIColor lightGrayColor];
            shadow.shadowBlurRadius = 0.0;
            shadow.shadowOffset = CGSizeMake(0.5, 0.5);
            NSDictionary *attributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:12], NSForegroundColorAttributeName:[UIColor otDarkBlue], NSShadowAttributeName:shadow, NSParagraphStyleAttributeName:paragraphStyle};
            point.y += 30;
            [_claim.claimName drawAtPoint:point withAttributes:attributes];
        }
        

        // grab the final image
        
        UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // and save it
        finalImage = [self screenshot];
        NSData *imageData = UIImagePNGRepresentation(finalImage);
        NSNumber *fileSize = [NSNumber numberWithUnsignedInteger:imageData.length];
        NSString *md5 = [imageData md5];
        NSString *fileName = @"_map_.png";
        NSString *file = [[FileSystemUtilities getAttachmentFolder:_claim.claimId] stringByAppendingPathComponent:fileName];
        ALog(@"%@", file);
        [imageData writeToFile:[[[FileSystemUtilities applicationDocumentsDirectory] path] stringByAppendingPathComponent:file] atomically:YES];
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setValue:[[[OT dateFormatter] stringFromDate:[NSDate date]] substringToIndex:10] forKey:@"documentDate"];
        [dictionary setValue:@"image/png" forKey:@"mimeType"];
        [dictionary setValue:file  forKey:@"fileName"];
        [dictionary setValue:@"png" forKey:@"fileExtension"];
        [dictionary setValue:[[[NSUUID UUID] UUIDString] lowercaseString] forKey:@"id"];
        [dictionary setValue:fileSize forKey:@"size"];
        [dictionary setValue:md5 forKey:@"md5"];
        [dictionary setValue:kAttachmentStatusCreated forKey:@"status"];
        [dictionary setValue:file forKey:@"filePath"];
        
        [dictionary setValue:@"Map" forKey:@"description"];
        [dictionary setValue:@"cadastralMap" forKey:@"typeCode"];
        
        AttachmentEntity *attachmentEntity = [AttachmentEntity new];
        [attachmentEntity setManagedObjectContext:_claim.managedObjectContext];
        Attachment *attachment = [attachmentEntity create];
        [attachment importFromJSON:dictionary];
        
        attachment.claim = _claim;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(code == %@)", @"cadastralMap"];
        // Nạp lại sau khi claim đã save
        DocumentTypeEntity *docTypeEntity = [DocumentTypeEntity new];
        [docTypeEntity setManagedObjectContext:_claim.managedObjectContext];
        NSArray *docTypeCollection = [docTypeEntity getCollection];
        
        DocumentType *docType = [[docTypeCollection filteredArrayUsingPredicate:predicate] firstObject];
        attachment.typeCode = docType;
        
        [attachment.managedObjectContext save:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"saved", nil)];
        });
    }];
     */
}

- (IBAction)done:(id)sender {
    [self.sideBarMenu dismiss];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addMarker:(id)sender {
    MKPointAnnotation *mylocation = [[MKPointAnnotation alloc] init];
    mylocation.coordinate = _mapView.userLocation.coordinate;
    mylocation.isAccessibilityElement = YES;
    [self confirmAddingMarkerFromAnnotation:mylocation];
}

- (IBAction)showMenu:(id)sender {
    if ([self.sideBarMenu hasShown])
        [self.sideBarMenu dismiss];
    else
        [self.sideBarMenu showInViewController:self];
}

- (IBAction)login:(id)sender {
    if ([OTSetting getInitialization]) {
        [OT login];
    } else {
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"message_app_not_yet_initialized", nil)];
    }
}

- (IBAction)logout:(id)sender {
    [OT login];
}

// observe the queue's operationCount, stop activity indicator if there is no operatation ongoing.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.parseQueue && [keyPath isEqualToString:@"operationCount"]) {
        if (self.parseQueue.operationCount == 0) {
//            ALog(@"Dismiss");
//            dispatch_async(dispatch_get_main_queue(), ^{
//               [SVProgressHUD dismiss];
//            });
        }
    }
//    else if (object == self.downloadTileQueue && [keyPath isEqualToString:@"operationCount"]) {
//        if (self.downloadTileQueue.operationCount == 0) {
//            ALog(@"Download tiles finished!");
//        }
//    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma handler download result

/*!
 Kiểm tra sự tồn tại của claim trên local (những claim đã tải về). Cập nhật trạng thái cho các claims đã tải về nếu có sự thay đổi từ phía server.
 @result
 Danh sách các claim mới tải về
 */
- (NSArray *)getValidClaimsToDownload:(NSArray *)objects {
    
    // < Lấy ra danh sách claimId=statusCode của tất cả bản ghi hiện tại
    ClaimEntity *claimEntity = [ClaimEntity new];
    
    NSArray *claimCollection = [claimEntity getCollectionWithProperties:@[@"statusCode", @"claimId"]];
    
//    NSArray *statusCodesLocal = [claimCollection valueForKeyPath:@"statusCode"];
    NSArray *claimIdsLocal = [claimCollection valueForKeyPath:@"claimId"];
//    NSDictionary *claimsDictLocal = [[NSDictionary alloc] initWithObjects:statusCodesLocal
//                                                                  forKeys:claimIdsLocal];
    // >
    
    // < Tạo danh sách claimId=statusCode của tất cả bản ghi vừa tải về
//    NSArray *statusCodesDownloaded = [objects valueForKeyPath:@"statusCode"];
    NSArray *claimIdsDownloaded = [objects valueForKeyPath:@"id"];
//    NSDictionary *claimsDictDownloaded = [[NSDictionary alloc] initWithObjects:statusCodesDownloaded
//                                                                       forKeys:claimIdsDownloaded];
    // >
    
    // < Kiểm tra sự tồn tại của claimId
    NSMutableArray *newClaimIds = [NSMutableArray array];
    for (NSString *claimId in claimIdsDownloaded) {
        if (![claimIdsLocal containsObject:claimId]) {
            [newClaimIds addObject:claimId];
        } // TODO check for updateable
    }
    return newClaimIds;
}

/*!
 Receive notification when the CommunityServerAPI get one claim successful
 */
- (void)processClaim:(Claim *)claim {
    if (claim.mappedGeometry == nil) return;
    
    // Tạo polygon. Phải đảm bảo dữ liệu geometry của claim không có lỗi
    ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:claim.mappedGeometry];
    
    if (![claim.claimId isEqualToString:_claim.claimId]) {
        GeoShape *shape = [_shapes createShapeFromPolygon:polygon.geometry];
        [self configureGeoShape:shape forClaim:claim];
        [_shapes setWorkingOverlay:shape];
        [self updateOverlay:_shapes];
    }
    
    // Tạo điểm và nhãn cho polygon theo tâm của đường bao.
    TBClusterAnnotation *center = [[TBClusterAnnotation alloc] initWithCoordinate:polygon.geometry.coordinate count:1];
    center.title = claim.claimName;
    center.subtitle = claim.claimId;
    center.icon = @"centroid";
    // Gán uuid của claim cho MKPointAnnotation để phục vụ tìm kiếm theo annotation trên bản đồ
    center.uuid = claim.claimId;
    
    // Thêm điểm vào mảng annotations dùng chung
    [_annotations addObject:center];
}

#pragma TBAnnotationClustering methods

- (void)addBounceAnnimationToView:(UIView *)view {
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    bounceAnimation.values = @[@(0.05), @(1.1), @(0.9), @(1)];
    
    bounceAnimation.duration = 0.6;
    NSMutableArray *timingFunctions = [[NSMutableArray alloc] initWithCapacity:bounceAnimation.values.count];
    for (NSUInteger i = 0; i < bounceAnimation.values.count; i++) {
        [timingFunctions addObject:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    }
    [bounceAnimation setTimingFunctions:timingFunctions.copy];
    bounceAnimation.removedOnCompletion = NO;
    
    [view.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

- (void)updateMapViewAnnotationsWithAnnotations:(NSArray *)annotations {
    NSMutableSet *before = [NSMutableSet setWithArray:self.mapView.annotations];
    // Không cho cluster đối với các đỉnh của polygon
    for (id <MKAnnotation>object in [self.workingAnnotations copy])
        if ([object conformsToProtocol:@protocol(MKAnnotation)]) {
            [before removeObject:object];
        }
    //
    if ([_customAnnotation conformsToProtocol:@protocol(MKAnnotation)]) {
        [before removeObject:_customAnnotation];
    }
    // Không cho cluster đối với additional markers
    for (id <MKAnnotation>object in [self.additionalMarkers copy])
        if ([object conformsToProtocol:@protocol(MKAnnotation)]) {
            [before removeObject:object];
        }
    
    [before removeObject:[self.mapView userLocation]];
    NSSet *after = [NSSet setWithArray:annotations];
    
    NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
    [toKeep intersectSet:after];
    
    NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
    [toAdd minusSet:toKeep];
    
    NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
    [toRemove minusSet:after];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.mapView addAnnotations:[toAdd allObjects]];
        [self.mapView removeAnnotations:[toRemove allObjects]];
    }];
}

#pragma MKMapViewDelegate methods
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self updateDashboard];
    // Updating clustered annotations within MapRect
    [[NSOperationQueue new] addOperationWithBlock:^{
        double scale = self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;
        NSArray *annotations = [self.coordinateQuadTree clusteredAnnotationsWithinMapRect:mapView.visibleMapRect withZoomScale:scale];
        [self updateMapViewAnnotationsWithAnnotations:annotations];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMapZoomLevelNotificationName object:[NSNumber numberWithInteger:[self mapZoomLevel]] userInfo:nil];
}

- (int)mapZoomLevel {
    // Tính zoomLevel để hiển thị nút download tiles
    CGFloat scale = [[UIScreen mainScreen] scale] > 1.0 ? 2.0 : 1.0;
    double zoomScale = scale * (self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width);
    return log2(zoomScale) + 20.0f;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *polylineView = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        polylineView.strokeColor = [UIColor otDarkBlue];
        polylineView.lineWidth = 2.0;
        
        return polylineView;
        
    } else if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer *polygonView = [[MKPolygonRenderer alloc] initWithOverlay:overlay];
        polygonView.strokeColor = [UIColor otEarth];
        polygonView.lineWidth = 2.0;
        //polygonView.fillColor = [UIColor otLightGreen];
        
        return polygonView;
    } else if ([overlay isKindOfClass:[GeoShapeCollection class]]) {
        GeoShapeOverlayRenderer *overlayRenderer = [[GeoShapeOverlayRenderer alloc] initWithOverlay:overlay];
        overlayRenderer.strokeColor = [UIColor otDarkBlue];
        return overlayRenderer;
    } else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        // Tile providers: Google map tiles, OpenStreetMap tiles
        MKTileOverlayRenderer *overlayRenderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
        return overlayRenderer;
    } else if ([overlay isKindOfClass:[OTWMSTileOverlay class]]) {
        MKTileOverlayRenderer *overlayRenderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
        return overlayRenderer;
    }
	
	return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    NSString *reuseIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([annotation isKindOfClass:[MKUserLocation class]]) return nil;
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        if ([((MKPointAnnotation *)annotation) isAccessibilityElement]) {
            NSString *annotationIdentifier = @"CustomAnnotation";
            if ([[((MKPointAnnotation *)annotation) accessibilityHint] isEqualToString:@"AdditionalAnnotation"])
                annotationIdentifier = @"AdditionalAnnotation";
            
            GeoShapeAnnotationView *pin = (GeoShapeAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
            if (!pin) {
                pin = [[GeoShapeAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
                
                pin.draggable = (_claim.getViewType == OTViewTypeView) ? NO : YES;
                pin.canShowCallout = YES;
//                UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(1, 0, 25, 25)];
//                UIImage *btnImage = [UIImage imageNamed:@"Icon-remove"];
//                [deleteButton setImage:btnImage forState:UIControlStateNormal];
//                if (_claim.getViewType != OTViewTypeView)
//                    pin.rightCalloutAccessoryView = deleteButton;
            }
            [pin setSelected:YES animated:YES];
            return pin;
        }
        
        //
        if ([[((MKPointAnnotation *)annotation) accessibilityLabel] isEqualToString:@"OTAnnotationView1"]) {
            static NSString * const annotationIdentifier = @"OTAnnotationView1";
            OTAnnotationView1 *pin = (OTAnnotationView1 *)[_mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
            if (!pin) {
                pin = [[OTAnnotationView1 alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
                
                pin.draggable = NO;
                pin.canShowCallout = YES;
            }
            [pin setSelected:YES animated:YES];
            return pin;
        }
        
        static NSString *defaultPinID = @"DropedPin";
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:defaultPinID];
        }
        [annotationView setEnabled:YES];
        [annotationView setCanShowCallout:YES];
        [annotationView setAnimatesDrop:YES];
        [annotationView setDraggable:YES];
        [annotationView setSelected:YES animated:YES];
        [annotationView setLeftCalloutAccessoryView:nil];
        
        return annotationView;
    }
    TBClusterAnnotation *ann = annotation;
    if (ann.count == 1) {
        TBClusterAnnotationView *view = [[TBClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
        NSString *imageName = ann.icon;
        view.image = [UIImage imageNamed:imageName];
        
        // 29x29
        // |-------|
        // |-------|
        // |---x---|
        // |-------|
        // |---x---|
        
        //Cho ảnh kích thước 29x29 @2x:58x58
        view.center = CGPointMake(14.5, -14.5);
        
        //Offset vị trí xuống chân
        view.centerOffset = CGPointMake(0, -14.5);
        
        //Offset vị trí vào giữa
        view.centerOffset = CGPointMake(0, 0);
        
        view.canShowCallout = YES;
        return view;
    } else if (ann.count > 1) {
        TBClusterAnnotationView *view = (TBClusterAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];
        if (!view) {
            view = [[TBClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
        }
        view.canShowCallout = NO;
        view.count = [(TBClusterAnnotation *)annotation count];
        return view;
    } else {
        return nil;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[TBClusterAnnotation class]]) {
        TBClusterAnnotation *annotation = (TBClusterAnnotation *)view.annotation;
        if (annotation.count > 1) {
            [self.mapView setVisibleMapRect:annotation.boundingMapRect animated:YES];
        } else {
            [self.mapView setCenterCoordinate:annotation.coordinate animated:YES];
        }
    } else if ([view isKindOfClass:[GeoShapeAnnotationView class]]) {
        if (!_dashboardActionShowing) {
            _dashboardMenuShowing = (_claim.getViewType == OTViewTypeView) ? NO : YES;
            _selectedMarkerView = view; // Dùng để xác định frame khi hiện bảng điều khiển marker
            NSInteger tag = 0;
            NSString *title = [view.annotation title];
            if (title != nil) tag = [title integerValue];
            workingAnnotationView = view;
            for (GeoShapeVertex *vertex in _shapes.workingOverlay.vertices) {
                if (vertex.tag == tag) {
                    [vertex setDragging:YES];
                    workingVertex = vertex;
                }
            }
            [self updateDashboard];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    // Remove marker control
    
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    
    CLLocationCoordinate2D coordinate = [view.annotation coordinate];

    BOOL additionalMarker = [[((MKPointAnnotation *)view.annotation) accessibilityHint] isEqualToString:@"AdditionalAnnotation"];
    
    NSInteger tag = 0;
    NSString *title = [view.annotation title];
    if (title != nil) tag = [title integerValue];
    if (newState == MKAnnotationViewDragStateStarting) {
        [self closeDashboard];
        [self setDragging:YES];
        workingAnnotationView = view;
        
        // Duyệt các vertex của workingOverlay để xác định điểm nào sẽ di chuyển
        // sau đó [vertex setDragging:YES];
        // workingVertex = vertex
        if (!additionalMarker) {
            for (GeoShapeVertex *vertex in _shapes.workingOverlay.vertices) {
                if (vertex.tag == tag) {
                    [vertex setDragging:YES];
                    workingVertex = vertex;
                }
            }
        }
    } else if (newState == MKAnnotationViewDragStateEnding) {
        if (!additionalMarker) {
            for (GeoShapeVertex *vertex in _shapes.workingOverlay.vertices) {
                if ([vertex isDragging]) {
                    workingVertex = vertex;
                    ALog(@"found");
                    break;
                }
            }
            if (snapped) {
                CLLocationCoordinate2D snappedCoord = [_shapes snappedCoordinate];
                workingVertex.latitude = snappedCoord.latitude;
                workingVertex.longitude = snappedCoord.longitude;
            } else {
                // Trả lại trạng thái cho workingVertex
                workingVertex.latitude = coordinate.latitude;
                workingVertex.longitude = coordinate.longitude;
            }
            [self updateOverlay:_shapes];
            [workingVertex setDragging:NO];
            [_mapView removeAnnotation:view.annotation];
            [_workingAnnotations removeObject:view.annotation];
            
            // Làm cho annotation không select
            MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
            point.title = [@(workingVertex.tag) stringValue];
            point.subtitle = workingVertex.locationAsString;
            point.coordinate = workingVertex.coordinate;
            point.isAccessibilityElement = YES;
            [self addAnnotation:point];
        } else {
            _dashboardActionShowing = YES;
            NSString *objectIDString = [(MKPointAnnotation *)[view annotation] accessibilityValue];
            if (objectIDString != nil) { // Not boundary marker
                for (Location *location in _claim.locations) {
                    if ([objectIDString isEqualToString:[location.objectID.URIRepresentation lastPathComponent]]) {
                        ShapeKitPoint *point = [[ShapeKitPoint alloc] initWithCoordinate:view.annotation.coordinate];
                        location.mappedLocation = point.wktGeom;
                    }
                }
            }
            [self performSelector:@selector(setDashboardActionShowing:) withObject:nil afterDelay:0.05];
        }
    } else if (newState == MKAnnotationViewDragStateNone && oldState == MKAnnotationViewDragStateCanceling) {
        if (!additionalMarker) {
            for (GeoShapeVertex *vertex in _shapes.workingOverlay.vertices) {
                if ([vertex isDragging]) {
                    workingVertex = vertex;
                    ALog(@"found");
                    break;
                }
            }
            workingVertex.latitude = coordinate.latitude;
            workingVertex.longitude = coordinate.longitude;
            [self updateOverlay:_shapes];
            [self setDragging:NO];
        }
    } else if (newState == MKAnnotationViewDragStateDragging) {
        if (!additionalMarker) {
            [self setDragging:YES];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([self isDragging]) {
        CGPoint draggingPoint = workingAnnotationView.frame.origin;
        draggingPoint.y += 29;
        draggingPoint.x += 14.5;
        CLLocationCoordinate2D currentCoord = [_mapView convertPoint:draggingPoint toCoordinateFromView:_mapView];
        workingVertex.latitude = currentCoord.latitude;
        workingVertex.longitude = currentCoord.longitude;
        if (snapped) {
            workingVertex.latitude = _shapes.snappedCoordinate.latitude;
            workingVertex.longitude = _shapes.snappedCoordinate.longitude;
        }
        [self updateOverlay:_shapes];
        [self updateSnapFromCoordinate:currentCoord];
    } else
        [super touchesMoved:touches withEvent:event];
}

- (void)updateSnapFromCoordinate:(CLLocationCoordinate2D)cooordinate {
    //    [[NSOperationQueue new] addOperationWithBlock:^{
    dispatch_async(dispatch_get_main_queue(), ^{
        MKZoomScale currentZoomScale = _mapView.bounds.size.width / _mapView.visibleMapRect.size.width;
        snapped = [_shapes getSnapFromMapPoint:cooordinate mapRect:_mapView.visibleMapRect zoomScale:currentZoomScale snapMode:SnapModeEndPoint];
    });
    //    }];
}

#pragma DownloadClaimTaskDelegate method

- (void)downloadClaimTask:(DownloadClaimTask *)controller didFinishWithSuccess:(BOOL)success {
    _totalItemsDownloaded += 1;
    double progress = (double)_totalItemsDownloaded / (double)_totalItemsToDownload;
    ALog(@"downloadClaimTask didFinishWithSuccess %d, progress: %f", success, progress);
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showProgress:progress
                             status:NSLocalizedString(@"title_claim__downloading_map", nil)
                           maskType:SVProgressHUDMaskTypeGradient];
    });
    if (progress >= 1.0 || _totalItemsDownloaded == _totalItemsToDownload) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"message_claims_downloaded", @"Claims correctly downloaded")];
            
            ALog(@"Claim correctly downloaded %tu/%tu.", _totalItemsDownloaded - _totalItemsDownloadError, _totalItemsToDownload);
            
            _totalItemsToDownload = 0;
            _totalItemsDownloaded = 0;
            _totalItemsDownloadError = 0;
            [self setDownloading:NO];
        });
        // Update quad tree for clustering
        [_coordinateQuadTree buildTreeFromAnnotations:_annotations];
        [self mapView:_mapView regionDidChangeAnimated:NO];
        saveTemporaryContext;
        // Cập nhật hiển thị điểm
    }
    
    if (success) {
        [self processClaim:controller.claim];
    } else {
        _totalItemsDownloadError++;
    }
}

#pragma Actions
- (IBAction)showSettings:(id)sender {
    UINavigationController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingViewController"];
    settingViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:settingViewController animated:YES completion:nil];
}

- (IBAction)downloadMapTiles:(id)sender {
    if ([self isTileDownloading]) {
        NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"message_downloading_tiles", @"Additional", nil), _totalTilesDownloaded, _totalTilesToDownload];
        [UIAlertView showWithTitle:NSLocalizedString(@"app_name", nil) message:message cancelButtonTitle:NSLocalizedStringFromTable(@"stop", @"Additional", nil) otherButtonTitles:@[NSLocalizedStringFromTable(@"continue", @"Additional", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == alertView.cancelButtonIndex) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD show];
                });
                [self performSelector:@selector(stopAllDownloads:) withObject:nil afterDelay:0.3];
                return;
            } else {
                return;
            }
        }];
    } else {
        MKMapRect mRect = self.mapView.visibleMapRect;
        MKMapPoint neMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), mRect.origin.y);
        MKMapPoint swMapPoint = MKMapPointMake(mRect.origin.x, MKMapRectGetMaxY(mRect));
        CLLocationCoordinate2D neCoord = MKCoordinateForMapPoint(neMapPoint);
        CLLocationCoordinate2D swCoord = MKCoordinateForMapPoint(swMapPoint);
        OTWMSTileOverlay *wmsTileOverlay = [[OTWMSTileOverlay alloc] initWithWMSUrlString:[OTSetting getGeoServerURL] layers:[OTSetting getGeoServerLayers] tileSize:CGSizeMake(TILE_SIZE, TILE_SIZE)];
        [wmsTileOverlay setOffline:YES];
        NSArray *tiles = [wmsTileOverlay tilesForNorthEast:neCoord southWest:swCoord startZoom:[self mapZoomLevel] endZoom:20];
        
        NSString *tileQueued = [NSString stringWithFormat:NSLocalizedString(@"tiles_queued", nil), tiles.count];
        
        if (tiles.count == 0) {
            [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"all_tiles_downloaded", nil)];
            return;
        } else {
            [UIAlertView showWithTitle:NSLocalizedString(@"app_name", nil) message:tileQueued cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"confirm", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex != alertView.cancelButtonIndex) {
                    _totalTilesToDownload = tiles.count;
                    _totalTilesDownloaded = 0;
                    _totalTilesDownloadError = 0;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *formatString = NSLocalizedString(@"too_many_tiles_queued", nil);
                        [SVProgressHUD showWithStatus:[NSString stringWithFormat:formatString, tiles.count] maskType:SVProgressHUDMaskTypeGradient];
                        [self configureDownloadTilesStatusLabelForTitle:[NSString stringWithFormat:formatString, tiles.count] message:nil];
                    });
                    [self performSelector:@selector(createDownloadList:) withObject:tiles afterDelay:0.3];
                }
            }];
        }
    }
}

- (void)createDownloadList:(NSArray *)tiles {
    if (_downloadTilesQueue == nil)
        _downloadTilesQueue = [[NSOperationQueue alloc] init];
    
    _downloadTilesQueue.maxConcurrentOperationCount = 4;
    
    NSBlockOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD show];
            });
            [self performSelector:@selector(stopAllDownloads:) withObject:nil afterDelay:0.3];
            NSString *message = NSLocalizedString(@"all_tiles_downloaded", nil);
            [SVProgressHUD showInfoWithStatus:message];
            
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertBody = message;
            localNotification.alertAction = nil;
            
            //On sound
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            
            //increase the badge number of application plus 1
            localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
            
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        }];
    }];
    
    [self setTileDownloading:YES];
    for (NSDictionary *dict in tiles) {
        NSURL *sourceUrl = [dict objectForKey:@"sourceUrl"];
        NSString *filePath = [dict objectForKey:@"filePath"];
        NSURL *appUrl = [[FileSystemUtilities applicationDocumentsDirectory] URLByAppendingPathComponent:@"tiles"];
        NSURL *destinationUrl = [appUrl URLByAppendingPathComponent:filePath];
        
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            _totalTilesDownloaded++;
            NSData *data = [NSData dataWithContentsOfURL:sourceUrl];
            [data writeToFile:destinationUrl.path atomically:YES];
            NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"message_downloading_tiles", @"Additional", nil), _totalTilesDownloaded, _totalTilesToDownload];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self configureDownloadTilesStatusLabelForTitle:message message:nil];
            });
        }];
        [completionOperation addDependency:operation];
    }
    
    [_downloadTilesQueue addOperations:completionOperation.dependencies waitUntilFinished:NO];
    [_downloadTilesQueue addOperation:completionOperation];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}

- (IBAction)stopAllDownloads:(id)sender {
    [_downloadTilesQueue cancelAllOperations];
    [_downloadTilesQueue waitUntilAllOperationsAreFinished];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_downloadTilesStatusLabel removeFromSuperview];
        _downloadTilesStatusLabel = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    });
    [self setTileDownloading:NO];
}

@end
