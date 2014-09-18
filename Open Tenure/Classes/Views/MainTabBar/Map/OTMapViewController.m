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

#import "OTCoordinate.h"
#import "OTGeometry.h"
#import "OTGeometryCollection.h"
#import "OTPointAnnotationView.h"

#import "DownloadClaimTask.h"

@interface OTMapViewController () <DownloadClaimTaskDelegate>

// Quad tree coordinate for handle cluster annotations
@property (strong, nonatomic) TBCoordinateQuadTree *coordinateQuadTree;

// Managing annotations on the mapView
@property (nonatomic) NSMutableArray *annotations;

@property (nonatomic, strong) OTGeometryCollection *geometryCollection;
@property (nonatomic, assign, getter = isDragging) BOOL dragging;

// Progress handle
@property (nonatomic, assign) NSInteger totalItemsToDownload;
@property (nonatomic, assign) NSInteger totalItemsDownloaded;
@property (nonatomic, assign) NSInteger totalItemsDownloadError;
@property (nonatomic, assign, getter = isDownloading) BOOL downloading;

@property (assign) OTViewType viewType;

// Dữ liệu tọa độ dùng hiển thị polygon (new & edit)
// Quản lý các annotations tại các đỉnh của polygon, không bị xóa bỏ cũng không tham gia tạo cluster
@property (nonatomic) NSMutableArray *workingAnnotations;
@property (nonatomic) MKPolygon *workingOverlay;

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
    
    // Khởi tạo geometryCollection
    _geometryCollection = [[OTGeometryCollection alloc] init];
    
    // Tạo mới một Geometry
    [_geometryCollection newGeometryWithName:_claim.claimId];
    
    self.workingAnnotations = [NSMutableArray array];
    
    if (_claim.mappedGeometry != nil) {
        // Lấy dữ liệu polygon
        ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:_claim.mappedGeometry];
        // Zoom đến polygon
        [_mapView setRegion:MKCoordinateRegionForMapRect(polygon.geometry.boundingMapRect) animated:YES];
        // Chuyển các đỉnh vào _workingAnnotation
        NSMutableArray *points = [NSMutableArray array];
        for (NSInteger i = 0; i < polygon.geometry.pointCount; i++) {
            CLLocationCoordinate2D coordinate = MKCoordinateForMapPoint(polygon.geometry.points[i]);
            MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
            pointAnnotation.coordinate = coordinate;
            [_workingAnnotations addObject:pointAnnotation];
            
            OTCoordinate *coord = [[OTCoordinate alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
            
            [points addObject:coord];
        }
        [[_geometryCollection workingGeometry] setPoints:points];
        
        _workingOverlay = polygon.geometry;
        
        [self renderAnnotations];
    } else {
        
    }
    
    // Init Quad tree coordinate
    _coordinateQuadTree = [[TBCoordinateQuadTree alloc] init];
    _coordinateQuadTree.mapView = _mapView;

    // Init annotations array
    _annotations = [NSMutableArray array];
    
    [self drawMappedGeometry];
}

// Chuyển qua tab khác
- (void)viewWillDisappear:(BOOL)animated{
    // TODO: Lưu mapedGeometry trong trường hợp tạo mới hoặc sửa
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

- (void)configureOperation {
    
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
        point.isAccessibilityElement = YES;
        [self updatePolygonAnnotations:point remove:NO];
    }
}

- (void)updatePolygonAnnotations:(MKPointAnnotation *)pointAnnotation remove:(BOOL)remove {
    CLLocationCoordinate2D coordinate = pointAnnotation.coordinate;
    if (remove) {
        ALog(@"Remove point");
        [_geometryCollection removePointFromWorkingGeometry:coordinate];
    } else {
        ALog(@"Add point");
        MKZoomScale currentZoomScale = _mapView.bounds.size.width / _mapView.visibleMapRect.size.width;
        [_geometryCollection addPointToWorkingGeometry:coordinate currentZoomScale:currentZoomScale];
    }
    ALog(@"N Point: %tu", [[[_geometryCollection workingGeometry] points] count]);
    [self renderAnnotations];
}

- (void)renderAnnotations {
    
    // Gỡ polygon cũ khỏi map
    if (_workingOverlay != nil)
        [self.mapView removeOverlay:_workingOverlay];
    
    // Xóa polygon khỏi bộ nhớ
    _workingOverlay = nil;
    
    // Gỡ các đỉnh của polygon khỏi map
    for (id <MKAnnotation>object in [self.workingAnnotations copy]) {
        if ([object conformsToProtocol:@protocol(MKAnnotation)]) {
            [self.mapView removeAnnotation:object];
            [self.workingAnnotations removeObject:object];
        }
    }

    OTGeometry *otGeometry = [self.geometryCollection workingGeometry];
    if (otGeometry.points.count > 2) {
        NSUInteger pointCount = otGeometry.polygon.pointCount;
        CLLocationCoordinate2D coords[pointCount];
        for (NSUInteger i = 0; i < pointCount; i++) {
            coords[i] = MKCoordinateForMapPoint(otGeometry.polygon.points[i]);
        }
        ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithCoordinates:coords count:(unsigned int)pointCount];

        // Tạo điểm và nhãn cho polygon theo tâm của đường bao.
        ShapeKitPoint *point = [[ShapeKitPoint alloc] initWithGeosGeometry:[polygon centroid].geosGeom];
        
        // Nếu là đa giác lõm (điểm nhãn không nằm trong polygon) thì thực hiện việc xác định lại điểm nhãn
        if (![point isWithinGeometry:polygon]) {
            // Tạo điểm nhãn cho polygon theo phương pháp khác
            point = [[ShapeKitPoint alloc] initWithGeosGeometry:[polygon pointOnSurface].geosGeom];
        }
        _claim.gpsGeometry = point.wktGeom;
        _claim.mappedGeometry = polygon.wktGeom;
        
        [self.mapView addOverlay:polygon.geometry];
        self.workingOverlay = polygon.geometry;
    } else {
        _claim.gpsGeometry = nil;
        _claim.mappedGeometry = nil;
    }

    [self renderActiveGeometry];
}

- (void)renderActiveGeometry {
    NSUInteger n = [[[self.geometryCollection workingGeometry] points] count];
    for (NSUInteger i = 0; i < n; i++) {
        OTCoordinate *otCoordinate = [[[self.geometryCollection workingGeometry] points] objectAtIndex:i];
        MKPointAnnotation *mapPointAnnotation = [[MKPointAnnotation alloc] init];
        mapPointAnnotation.coordinate = otCoordinate.coordinate;
        mapPointAnnotation.title = [NSString stringWithFormat:@"(%tu), %@", i, otCoordinate.locationAsString];
        mapPointAnnotation.isAccessibilityElement = YES;
        [self.mapView addAnnotation:mapPointAnnotation];
        [self.workingAnnotations addObject:mapPointAnnotation];
    }
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
        
        // Gán uuid của claim cho overlay để phục vụ tìm kiếm polygon overlay trên bản đồ
        polygon.geometry.title = object.claimId;
        
        // Đưa polygon geometry (overlay) lên bản đồ
        [_mapView addOverlay:polygon.geometry];
        
        // Tạo điểm và nhãn cho polygon theo tâm của đường bao.
        ShapeKitPoint *point = [[ShapeKitPoint alloc] initWithGeosGeometry:[polygon centroid].geosGeom];
        
        // Nếu là đa giác lõm (điểm nhãn không nằm trong polygon) thì thực hiện việc xác định lại điểm nhãn
        if (![point isWithinGeometry:polygon]) {
            // Tạo điểm nhãn cho polygon theo phương pháp khác
            point = [[ShapeKitPoint alloc] initWithGeosGeometry:[polygon pointOnSurface].geosGeom];
        }
        
        // Gán nhãn của điểm là tên của claim
        point.geometry.title = object.claimName;
        
        // Gán nhãn phụ của điểm là uuid của claim
        point.geometry.subtitle = object.claimId;
        
        // Gán kiển ký hiệu điểm
        point.geometry.icon = @"centroid";
        
        // Gán uuid của claim cho MKPointAnnotation để phục vụ tìm kiếm theo annotation trên bản đồ
        point.geometry.uuid = object.claimId;
        
        // Thêm điểm vào mảng annotations dùng chung
        [_annotations addObject:point.geometry];
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
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Underconstruction"
                                                   message: @"Bugs is fixing"
                                                  delegate: self
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@"OK",nil];
    
    
    [alert show];
    return;
    
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
    ShapeKitPolygon *polygon = [[ShapeKitPolygon alloc] initWithWKT:_claim.mappedGeometry];
    // Zoom đến polygon
    [_mapView setRegion:MKCoordinateRegionForMapRect(polygon.geometry.boundingMapRect) animated:NO];
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    options.region = self.mapView.region;
    options.scale = [UIScreen mainScreen].scale;
    options.size = self.mapView.frame.size;
    
    MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];
    [snapshotter startWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
        
        // get the image associated with the snapshot
        
        UIImage *image = snapshot.image;
        
        // Get the size of the final image
        
        CGRect finalImageRect = CGRectMake(0, 0, image.size.width, image.size.height);
        
        // Get a standard annotation view pin. Clearly, Apple assumes that we'll only want to draw standard annotation pins!
        
//        static NSString * const annotationIdentifier = @"CustomAnnotation";
//        MKAnnotationView *annotationView = [_mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
//        if (annotationView) {
//            annotationView.annotation = annotation;
//        } else {
//            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
//            
//            annotationView.image = [UIImage imageNamed:@"ot_blue_marker"];
//        }
//        
//        // 29x29
//        // |-------|
//        // |-------|
//        // |---x---|
//        // |-------|
//        // |---x---|
//        
//        //Offset vị trí vào giữa
//        annotationView.centerOffset = CGPointMake(0, -15);
//        
//        annotationView.draggable = (_viewType == OTViewTypeView) ? NO : YES;
//        
//        annotationView.canShowCallout = NO;
//        
//        return annotationView;
//        
//        
//        
//        
        MKAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
        UIImage *pinImage = [UIImage imageNamed:@"ot_blue_marker"];
        
        pin.centerOffset = CGPointMake(0, -15);
        
        // ok, let's start to create our final image
        
        UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
        
        // first, draw the image from the snapshotter
        
        [image drawAtPoint:CGPointMake(0, 0)];
        
        // now, let's iterate through the annotations and draw them, too
        
        for (id<MKAnnotation>annotation in self.mapView.annotations)
        {
            CGPoint point = [snapshot pointForCoordinate:annotation.coordinate];
            if (CGRectContainsPoint(finalImageRect, point)) // this is too conservative, but you get the idea
            {
                CGPoint pinCenterOffset = pin.centerOffset;
                point.x -= pin.bounds.size.width / 2.0;
                point.y -= pin.bounds.size.height / 2.0;
                point.x += pinCenterOffset.x;
                point.y += pinCenterOffset.y;
                
                [pinImage drawAtPoint:point];
            }
        }
        
        // grab the final image
        
        UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // and save it
        
        NSData *imageData = UIImageJPEGRepresentation(finalImage, 1.0);
        NSNumber *fileSize = [NSNumber numberWithUnsignedInteger:imageData.length];
        NSString *md5 = [imageData md5];
        NSString *fileName = @"_map_.jpg";
        NSString *file = [[FileSystemUtilities getAttachmentFolder:_claim.claimId] stringByAppendingPathComponent:fileName];
        [imageData writeToFile:file atomically:YES];
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setValue:[[OT dateFormatter] stringFromDate:[NSDate date]] forKey:@"documentDate"];
        [dictionary setValue:@"image/jpeg" forKey:@"mimeType"];
        [dictionary setValue:fileName  forKey:@"fileName"];
        [dictionary setValue:@"jpg" forKey:@"fileExtension"];
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
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"saved", nil)];
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


/*
 Check the exisitence of a claim in local. Update status of downloaded claims if there is any change
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
 Receive notification when the CommunityServerAPI get all new claims successful.
 @result
 New claims list to add or update
 */
/*
- (void)getClaim:(ResponseClaim *)responseObject {
    [CommunityServerAPI getClaim:responseObject.claimId completionHandler:^(NSError *error, NSHTTPURLResponse *httpResponse, NSData *data) {
        if (error != nil) {
            [OT handleError:error];
        } else {
            if ((([httpResponse statusCode]/100) == 2) && [[httpResponse MIMEType] isEqual:@"application/json"]) {
                NSError *errorJSON = nil;
                NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&errorJSON];
                if (errorJSON != nil) {
                    [OT handleError:errorJSON];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        // Gửi thông báo để xử lý progress nếu cần
                        [[NSNotificationCenter defaultCenter] postNotificationName:kGetClaimSuccessNotificationName object:object userInfo:nil];
                        
                        // Tạo ResponseClaim từ JSON
                        ResponseClaim *responseObject = [ResponseClaim claimDetailWithDictionary:object];
                        
                        // Kiểm tra việc cập nhật chi tiết cho claim
                        Claim *claim = [ClaimEntity updateDetailFromResponseObject:responseObject];
                        
                        if (claim != nil) {
                            
                            // Lấy thông tin person
                            NSDictionary *dict = [object objectForKey:@"claimant"];
                            
                            // Tạo mới person từ JSON
                            Person *person = [PersonEntity createFromDictionary:dict];
                            
                            // Gán claim cho person và lưu
                            [person setClaim:claim];
                            [person.managedObjectContext save:nil];
                            
                            // Chuyển xử lý để vẽ
                            //[self processClaim:object];
                        }
                    });
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
*/
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
    for (id object in _workingAnnotations)
        [before removeObject:object];
    
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
    }
	
	return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    NSString *reuseIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([annotation isKindOfClass:[MKUserLocation class]]) return nil;
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        if ([((MKPointAnnotation *)annotation) isAccessibilityElement]) {
            static NSString * const annotationIdentifier = @"CustomAnnotation";
            OTPointAnnotationView *pin = (OTPointAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
            
            if (!pin) {
                pin = [[OTPointAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
                
                pin.draggable = (_viewType == OTViewTypeView) ? NO : YES;
                pin.canShowCallout = YES;
            }
            
            [pin setSelected:YES animated:YES];
            
            if (_viewType == OTViewTypeAdd || _viewType == OTViewTypeEdit) {
                UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(1, 0, 25, 25)];
                UIImage *btnImage = [UIImage imageNamed:@"Icon-remove"];
                [deleteButton setImage:btnImage forState:UIControlStateNormal];
                pin.rightCalloutAccessoryView = deleteButton;
            }
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
        view.center = CGPointMake(14, -14);
        
        //Offset vị trí xuống chân
        view.centerOffset = CGPointMake(0, -14);
        
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
    
    if ([view isKindOfClass:[OTPointAnnotationView class]]) {
        if([[view rightCalloutAccessoryView] isEqual:control]){
            [self updatePolygonAnnotations:[view annotation] remove:YES];
            [self renderAnnotations];
        }
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState{
    
    CLLocationCoordinate2D annotationCoordinate = [view.annotation coordinate];
    
    OTCoordinate *tempCoordinate = [[OTCoordinate alloc] initWithLatitude:annotationCoordinate.latitude longitude:annotationCoordinate.longitude];
    
    if (newState == MKAnnotationViewDragStateStarting) {
        
        [self setDragging:YES];

        for (OTCoordinate *coordinate in [[self.geometryCollection workingGeometry] points]) {
            if ([coordinate isEqual:tempCoordinate]) {
                [coordinate setIsDragging:YES];
            }
        }
        
    } else if (newState == MKAnnotationViewDragStateEnding) {
        
        for (OTCoordinate *coordinate in [[self.geometryCollection workingGeometry] points]) {
            if ([coordinate isDragging]) {
                [coordinate setIsDragging:NO];
                coordinate.latitude = annotationCoordinate.latitude;
                coordinate.longitude = annotationCoordinate.longitude;
                break;
            }
        }
        
    } else if (newState == MKAnnotationViewDragStateNone && oldState == MKAnnotationViewDragStateEnding) {
        [self renderAnnotations];
        [self setDragging:NO];
    }
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
