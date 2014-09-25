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

#import "GeoShape.h"
#import "GeoShapeVertex.h"
#import "GeoShapeCollection.h"
#import "GeoShapeOverlayRenderer.h"
#import "GeoShapeAnnotationView.h"

#import "DownloadClaimTask.h"

@interface OTMapViewController () <DownloadClaimTaskDelegate> {
    MKAnnotationView *workingAnnotationView;
    GeoShapeVertex *workingVertex;
    BOOL snapped;
}

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

@property (assign) OTViewType viewType;

@property (nonatomic) NSOperationQueue *parseQueue;

@property (nonatomic, strong) NSMutableArray *handleDeletedClaims;
@property (nonatomic, strong) NSMutableArray *handleDeletedAttachments;
@property (nonatomic, strong) NSMutableArray *handleDeletedPersons;

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
    
    //[self configureOperation];
    [self configureGestures];
    [self configureNotifications];
    [self configureCommunityArea];
    
    self.viewType = _claim.getViewType;
    if (_viewType == OTViewTypeView) { // Readonly
        // TODO: Vẽ các marker cho polygon (không cho phép sửa
    } else if (_viewType == OTViewTypeEdit) { // Editable
        
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

    if (_claim.mappedGeometry != nil) {
        // Lấy dữ liệu polygon
        ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:_claim.mappedGeometry];
        // Zoom đến polygon
        [_mapView setRegion:MKCoordinateRegionForMapRect(polygon.geometry.boundingMapRect) animated:YES];
        
        // Tạo workingOverlay
        GeoShape *shape = [_shapes createShapeWithTitle:_claim.claimName subtitle:nil];
        [_shapes setWorkingOverlay:shape];
        shape.isAccessibilityElement = YES;
        
        // Chuyển các đỉnh vào workingOverlay
        for (NSInteger i = 0; i < polygon.geometry.pointCount-1; i++) {
            CLLocationCoordinate2D coordinate = MKCoordinateForMapPoint(polygon.geometry.points[i]);
            [_shapes addPointToWorkingOverlay:coordinate currentZoomScale:CGFLOAT_MIN];
            MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
            pointAnnotation.title = [@(i) stringValue];
            pointAnnotation.subtitle = [NSString stringWithFormat:@"{Lat: %.10f, Lon: %.10f}", coordinate.latitude, coordinate.longitude];
            pointAnnotation.isAccessibilityElement = YES;
            pointAnnotation.coordinate = coordinate;
            [_workingAnnotations addObject:pointAnnotation];

            [_mapView addAnnotation:pointAnnotation];
        }
    } else {
        
    }
    
    [self drawMappedGeometry];
}

// Chuyển qua tab khác
- (void)viewWillDisappear:(BOOL)animated{
    // TODO: Lưu mapedGeometry trong trường hợp tạo mới hoặc sửa
    if ([_claim getViewType] == OTViewTypeView) return;
    
    if (_shapes.workingOverlay.vertexs.count > 2) {
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
    if (_claim.isSaved && [_claim.managedObjectContext hasChanges]) {
        [_claim.managedObjectContext save:nil];
    }
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureCommunityArea {
    [CommunityServerAPI getCommunityArea:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSMutableArray *objects = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    NSString *polygonCommunityArea = [objects valueForKey:@"result"];
                    ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:polygonCommunityArea];
                    if (polygon.geometry != nil) {
                        [_mapView addOverlay:polygon.geometry];
                        if (_claim == nil)
                            [_mapView setVisibleMapRect:polygon.geometry.boundingMapRect animated:YES];
                    }
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

#pragma handler touch on the map

- (IBAction)handleLongPress:(id)sender {
    if (_viewType == OTViewTypeAdd) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"message_save_claim_before_adding_content", nil)];
    } else if (_viewType == OTViewTypeView) {
        return;
    } else {
        UIGestureRecognizer *gestureRecognizer = sender;
        if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
            return;

        CGPoint touchPoint = [gestureRecognizer locationInView:_mapView];
        CLLocationCoordinate2D touchMapCoordinate = [_mapView convertPoint:touchPoint toCoordinateFromView:_mapView];
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        point.coordinate = touchMapCoordinate;
        point.title = [NSString stringWithFormat:@"{Lat: %f, Lon: %f}", point.coordinate.latitude, point.coordinate.longitude];
        point.isAccessibilityElement = YES;
        [self updatePolygonAnnotations:point remove:NO];
    }
}

- (void)updatePolygonAnnotations:(MKPointAnnotation *)point remove:(BOOL)remove {
    if (_shapes.workingOverlay == nil) {
        // Tạo mới shape
        GeoShape *shape = [_shapes createShapeWithCenterCoordinate:point.coordinate];
        [_shapes setWorkingOverlay:shape];
        shape.title = [[NSUUID UUID] UUIDString];
        shape.subtitle = [[NSDate date] description];
        [_mapView addAnnotation:point];
        [_workingAnnotations addObject:point];
    } else {
        MKZoomScale currentZoomScale = _mapView.bounds.size.width / _mapView.visibleMapRect.size.width;
        if (!remove) {
            [_shapes addPointToWorkingOverlay:point.coordinate currentZoomScale:currentZoomScale];
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
                             status:NSLocalizedString(@"title_claim_downloading_map", nil)
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
                             status:NSLocalizedString(@"title_claim_downloading_map", nil)
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
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uuid CONTAINS[cd] %@", claim.claimId];
        TBClusterAnnotation *annotation = [[_annotations filteredArrayUsingPredicate:predicate] firstObject];
        if (annotation != nil) {
            [_annotations removeObject:annotation];
        }
        annotation = nil;
        annotation = [[_mapView.annotations filteredArrayUsingPredicate:predicate] firstObject];
        if (annotation != nil) {
            [_mapView removeAnnotation:annotation];
        }
        // Xóa boundary
        predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", claim.claimId];
        id overlay = [[_mapView.overlays filteredArrayUsingPredicate:predicate] firstObject];
        if (overlay != nil)
            [_mapView removeOverlay:overlay];
        
        BOOL success = [FileSystemUtilities deleteClaim:claim.claimId];
        ALog(@"Delete claim folder: %d", success);
    }
    [_handleDeletedClaims removeAllObjects];
    [_handleDeletedAttachments removeAllObjects];
    [_handleDeletedPersons removeAllObjects];
    [_coordinateQuadTree buildTreeFromAnnotations:_annotations];
}

/*!
 Vẽ tất cả các mappedGeometrys của claim đang có lên map. Gọi một lần ở viewDidload
 */
- (void)drawMappedGeometry {
    [SVProgressHUD show];
    id collection = [ClaimEntity getCollection];
    
    for (Claim *object in collection) {
        if (object.mappedGeometry == nil) continue;
        if ([object.claimId isEqualToString:_claim.claimId]) continue;
        
        // Tạo polygon. Phải đảm bảo dữ liệu geometry của claim không có lỗi
        ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:object.mappedGeometry];
        
        GeoShape *shape = [_shapes createShapeFromPolygon:polygon.geometry];
        shape.title = object.claimId;

        // Tạo điểm và nhãn cho polygon theo tâm của đường bao.
        TBClusterAnnotation *center = [[TBClusterAnnotation alloc] initWithCoordinate:shape.coordinate count:1];
        center.title = object.claimName;
        center.subtitle = object.claimId;
        center.icon = @"centroid";
        // Gán uuid của claim cho MKPointAnnotation để phục vụ tìm kiếm theo annotation trên bản đồ
        center.uuid = object.claimId;

        // Thêm điểm vào mảng annotations dùng chung
        [_annotations addObject:center];
    }
    // Cập nhật hiển thị điểm
    [_coordinateQuadTree buildTreeFromAnnotations:_annotations];
    [self mapView:_mapView regionDidChangeAnimated:NO];
    [SVProgressHUD dismiss];
}

#pragma Bar Buttons Action

/*!
 Download all new claims by current map rect.
 @result
 Send broadcasting information
 */
- (IBAction)downloadClaims:(id)sender {
    
    if ([self isDownloading]) return;
    
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
    [SVProgressHUD showWithStatus:NSLocalizedString(@"title_claim_downloading_map", @"Downloading Claims")];
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

- (IBAction)mapSnapshot:(id)sender {
    GeoShape *shape = _shapes.workingOverlay;
    // Zoom đến polygon
    [_mapView setRegion:shape.region animated:YES];
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    options.region = shape.region;
    options.scale = [UIScreen mainScreen].scale;
    options.size = self.mapView.frame.size;
    
    MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD show];
    });

    // Kiểm tra phiên bản map attached. Xóa nếu tồn tại bản cũ
    for (Attachment *attachment in _claim.attachments) {
        if ([attachment.typeCode.code isEqualToString:@"cadastralMap"] &&
            [attachment.note isEqualToString:@"Map"]) {
            [_claim.managedObjectContext deleteObject:attachment];
        }
    }
    
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
        
        NSData *imageData = UIImagePNGRepresentation(finalImage);
        NSNumber *fileSize = [NSNumber numberWithUnsignedInteger:imageData.length];
        NSString *md5 = [imageData md5];
        NSString *fileName = @"_map_.png";
        NSString *file = [[FileSystemUtilities getAttachmentFolder:_claim.claimId] stringByAppendingPathComponent:fileName];
        [imageData writeToFile:file atomically:YES];
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setValue:[[OT dateFormatter] stringFromDate:[NSDate date]] forKey:@"documentDate"];
        [dictionary setValue:@"image/png" forKey:@"mimeType"];
        [dictionary setValue:fileName  forKey:@"fileName"];
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
}

- (IBAction)showMenu:(id)sender {
    
}

// observe the queue's operationCount, stop activity indicator if there is no operatation ongoing.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.parseQueue && [keyPath isEqualToString:@"operationCount"]) {
        if (self.parseQueue.operationCount == 0) {
            ALog(@"Dismiss");
            dispatch_async(dispatch_get_main_queue(), ^{
               [SVProgressHUD dismiss];
            });
        }
    } else {
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
    
    // Create polygon
    ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:claim.mappedGeometry];
    polygon.geometry.title = claim.claimId;
    [_mapView addOverlay:polygon.geometry];
    
    // Create point
    ShapeKitPoint *point = [[ShapeKitPoint alloc] initWithGeosGeometry:[polygon centroid].geosGeom];
    if (![point isWithinGeometry:polygon])
        point = [[ShapeKitPoint alloc] initWithGeosGeometry:[polygon pointOnSurface].geosGeom];
    
    point.geometry.title = claim.claimName;
    point.geometry.subtitle = claim.claimId;
    point.geometry.icon = @"centroid";
    point.geometry.uuid = claim.claimId;

    // Add claim's centroid to mapView annotations
    [_annotations addObject:point.geometry];
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

    // Updating clustered annotations within MapRect
    [[NSOperationQueue new] addOperationWithBlock:^{
        double scale = self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;
        NSArray *annotations = [self.coordinateQuadTree clusteredAnnotationsWithinMapRect:mapView.visibleMapRect withZoomScale:scale];
        [self updateMapViewAnnotationsWithAnnotations:annotations];
    }];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *polylineView = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        polylineView.strokeColor = [UIColor otDarkBlue];
        polylineView.lineWidth = 2.0;
        
        return polylineView;
        
    } else if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer *polygonView = [[MKPolygonRenderer alloc] initWithOverlay:overlay];
        polygonView.strokeColor = [UIColor otDarkBlue];
        polygonView.lineWidth = 2.0;
        //polygonView.fillColor = [UIColor otLightGreen];
        
        return polygonView;
    } else if ([overlay isKindOfClass:[GeoShapeCollection class]]) {
        GeoShapeOverlayRenderer *overlayRenderer = [[GeoShapeOverlayRenderer alloc] initWithOverlay:overlay];
        return overlayRenderer;
    }
	
	return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    NSString *reuseIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([annotation isKindOfClass:[MKUserLocation class]]) return nil;
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        if ([((MKPointAnnotation *)annotation) isAccessibilityElement]) {
            static NSString * const annotationIdentifier = @"CustomAnnotation";
            GeoShapeAnnotationView *pin = (GeoShapeAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
            if (!pin) {
                pin = [[GeoShapeAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
                
                pin.draggable = (_viewType == OTViewTypeView) ? NO : YES;;
                pin.canShowCallout = YES;
                UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(1, 0, 25, 25)];
                UIImage *btnImage = [UIImage imageNamed:@"Icon-remove"];
                [deleteButton setImage:btnImage forState:UIControlStateNormal];
                pin.rightCalloutAccessoryView = deleteButton;
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
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    
    if ([view isKindOfClass:[GeoShapeAnnotationView class]]) {
        if([[view rightCalloutAccessoryView] isEqual:control]){
            [self updatePolygonAnnotations:[view annotation] remove:YES];
        }
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    
    CLLocationCoordinate2D coordinate = [view.annotation coordinate];
    GeoShapeVertex *templateVertex = [[GeoShapeVertex alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    
    if (newState == MKAnnotationViewDragStateStarting) {
        [self setDragging:YES];
        workingAnnotationView = view;
        
        // Duyệt các vertex của workingOverlay để xác định điểm nào sẽ di chuyển
        // sau đó [vertex setDragging:YES];
        // workingVertex = vertex
        for (GeoShapeVertex *vertex in _shapes.workingOverlay.vertexs) {
            if ([vertex isEqual:templateVertex]) {
                [vertex setDragging:YES];
                workingVertex = vertex;
                break;
            }
        }
    } else if (newState == MKAnnotationViewDragStateEnding) {
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
        point.coordinate = workingVertex.coordinate;
        point.title = workingVertex.locationAsString;
        point.isAccessibilityElement = YES;
        [self addAnnotation:point];
    } else if (newState == MKAnnotationViewDragStateNone && oldState == MKAnnotationViewDragStateCanceling) {
        workingVertex.latitude = coordinate.latitude;
        workingVertex.longitude = coordinate.longitude;
        [self updateOverlay:_shapes];
        [self setDragging:NO];
    } else if (newState == MKAnnotationViewDragStateDragging) {
        [self setDragging:YES];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([self isDragging]) {
        CGPoint draggingPoint = workingAnnotationView.frame.origin;
        draggingPoint.y += 29;
        draggingPoint.x += 14;
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
                             status:NSLocalizedString(@"title_claim_downloading_map", nil)
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
    }
    
    if (success) {
        [self processClaim:controller.claim];
    } else {
        _totalItemsDownloadError++;
    }
}

@end
