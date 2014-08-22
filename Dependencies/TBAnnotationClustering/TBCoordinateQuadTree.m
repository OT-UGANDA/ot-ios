//
//  TBCoordinateQuadTree.m
//  TBAnnotationClustering
//
//  Created by Theodore Calmes on 9/27/13.
//  Copyright (c) 2013 Theodore Calmes. All rights reserved.
//  Modified by Tran Trung Chuyen on 2/10/2014
//

#import "TBCoordinateQuadTree.h"
#import "TBClusterAnnotation.h"

typedef struct TBInfo {
    char* title;
    char* subtitle;
} TBInfo;

TBQuadTreeNodeData TBDataFromLine(NSString *line)
{
    NSArray *components = [line componentsSeparatedByString:@","];
    double latitude = [components[1] doubleValue];
    double longitude = [components[0] doubleValue];

    TBInfo* info = malloc(sizeof(TBInfo));

    NSString *title = [components[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    info->title = malloc(sizeof(char) * title.length + 1);
    strncpy(info->title, [title UTF8String], title.length + 1);

    NSString *subtitle = [[components lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    info->subtitle = malloc(sizeof(char) * subtitle.length + 1);
    strncpy(info->subtitle, [subtitle UTF8String], subtitle.length + 1);

    return TBQuadTreeNodeDataMake(0, 0, 0, 0, latitude, longitude, info);
}

TBBoundingBox TBBoundingBoxForMapRect(MKMapRect mapRect)
{
    CLLocationCoordinate2D topLeft = MKCoordinateForMapPoint(mapRect.origin);
    CLLocationCoordinate2D botRight = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)));

    CLLocationDegrees minLat = botRight.latitude;
    CLLocationDegrees maxLat = topLeft.latitude;

    CLLocationDegrees minLon = topLeft.longitude;
    CLLocationDegrees maxLon = botRight.longitude;

    return TBBoundingBoxMake(minLat, minLon, maxLat, maxLon);
}

MKMapRect TBMapRectForBoundingBox(TBBoundingBox boundingBox)
{
    MKMapPoint topLeft = MKMapPointForCoordinate(CLLocationCoordinate2DMake(boundingBox.x0, boundingBox.y0));
    MKMapPoint botRight = MKMapPointForCoordinate(CLLocationCoordinate2DMake(boundingBox.xf, boundingBox.yf));

    return MKMapRectMake(topLeft.x, botRight.y, fabs(botRight.x - topLeft.x), fabs(botRight.y - topLeft.y));
}

NSInteger TBZoomScaleToZoomLevel(MKZoomScale scale)
{
    double totalTilesAtMaxZoom = MKMapSizeWorld.width / 256.0;
    NSInteger zoomLevelAtMaxZoom = log2(totalTilesAtMaxZoom);
    NSInteger zoomLevel = MAX(0, zoomLevelAtMaxZoom + floor(log2f(scale) + 0.5));

    return zoomLevel;
}

float TBCellSizeForZoomScale(MKZoomScale zoomScale)
{
    NSInteger zoomLevel = TBZoomScaleToZoomLevel(zoomScale);

    switch (zoomLevel) {
        case 13:
        case 14:
        case 15:
            return 64;
        case 16:
        case 17:
        case 18:
            return 32;
        case 19:
            return 16;

        default:
            return 88;
    }
}

@implementation TBCoordinateQuadTree

- (void)buildTreeFromFile:(NSString *)fileName {
    @autoreleasepool {
        NSString *data = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileName ofType:@"csv"] encoding:NSASCIIStringEncoding error:nil];
        NSArray *lines = [data componentsSeparatedByString:@"\n"];

        NSInteger count = lines.count - 1;

        TBQuadTreeNodeData *dataArray = malloc(sizeof(TBQuadTreeNodeData) * count);
        CLLocationDegrees minLon = 180.;
        CLLocationDegrees minLat = 90.;
        CLLocationDegrees maxLon = -180;
        CLLocationDegrees maxLat = -90;
        for (NSInteger i = 0; i < count; i++) {
            dataArray[i] = TBDataFromLine(lines[i]);
            minLat = MIN(minLat, dataArray[i].x);
            minLon = MIN(minLon, dataArray[i].y);
            maxLat = MAX(maxLat, dataArray[i].x);
            maxLon = MAX(maxLon, dataArray[i].y);
        }
        
        CLLocationCoordinate2D sw = CLLocationCoordinate2DMake(minLat, minLon);
        CLLocationCoordinate2D ne = CLLocationCoordinate2DMake(maxLat, maxLon);
        MKMapPoint pSW = MKMapPointForCoordinate(sw);
        MKMapPoint pNE = MKMapPointForCoordinate(ne);
        double antimeridianOveflow = (ne.longitude > sw.longitude) ? 0 : MKMapSizeWorld.width;
        MKMapRect mapRect = MKMapRectMake(pSW.x, pNE.y, (pNE.x - pSW.x) + antimeridianOveflow, (pSW.y - pNE.y));
        [self.mapView setVisibleMapRect:mapRect animated:YES];
        
        TBBoundingBox world = TBBoundingBoxMake(minLat, minLon, maxLat, maxLon);
        _root = TBQuadTreeBuildWithData(dataArray, (int)count, world, 4);
    }
}

- (void)buildTreeFromAnnotations:(NSArray *)annotations {
    @autoreleasepool {
        if (annotations.count == 0 || annotations == nil) {
            //annotations = self.mapView.annotations;
        }
        TBQuadTreeNodeData *dataArray = malloc(sizeof(TBQuadTreeNodeData) * annotations.count);
        NSInteger i = 0;
        CLLocationDegrees minLon = 180.;
        CLLocationDegrees minLat = 90.;
        CLLocationDegrees maxLon = -180;
        CLLocationDegrees maxLat = -90;
        for (TBClusterAnnotation *annotation in annotations) {
            if ([NSStringFromClass([annotation class]) isEqualToString:@"TBClusterAnnotation"]) {
                NSString *title = [NSString stringWithFormat:@"%@", annotation.title];
                NSString *subtitle = [NSString stringWithFormat:@"%@", annotation.subtitle];
                NSString *icon = [NSString stringWithFormat:@"%@", annotation.icon];
                NSString *uuid = [NSString stringWithFormat:@"%@", annotation.uuid];
                
                // Sửa lỗi chuyển đổi từ CString sang NSString = null
                //(cho về dạng % trước khi chuyển qua CString)
                title = [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                subtitle = [subtitle stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                icon = [icon stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                uuid = [uuid stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                TBInfo *info = malloc(sizeof(TBInfo));
                info->title = malloc(sizeof(char) * title.length + 1);
                strncpy(info->title, [title UTF8String], title.length + 1);
                info->subtitle = malloc(sizeof(char) * subtitle.length + 1);
                strncpy(info->subtitle, [subtitle UTF8String], subtitle.length + 1);
                char* cIcon = malloc(sizeof(char) * icon.length + 1);
                char* cUUID = malloc(sizeof(char) * uuid.length + 1);
                strcpy(cIcon, [icon UTF8String]);
                strcpy(cUUID, [uuid UTF8String]);
                dataArray[i++] = TBQuadTreeNodeDataMake(annotation.index, annotation.tag, cIcon, cUUID, annotation.coordinate.latitude, annotation.coordinate.longitude, info);
                minLat = MIN(minLat, annotation.coordinate.latitude);
                minLon = MIN(minLon, annotation.coordinate.longitude);
                maxLat = MAX(maxLat, annotation.coordinate.latitude);
                maxLon = MAX(maxLon, annotation.coordinate.longitude);
            }
        }
        
//        CLLocationCoordinate2D sw = CLLocationCoordinate2DMake(minLat, minLon);
//        CLLocationCoordinate2D ne = CLLocationCoordinate2DMake(maxLat, maxLon);
//        MKMapPoint pSW = MKMapPointForCoordinate(sw);
//        MKMapPoint pNE = MKMapPointForCoordinate(ne);
//        double antimeridianOveflow = (ne.longitude > sw.longitude) ? 0 : MKMapSizeWorld.width;
//        MKMapRect mapRect = MKMapRectMake(pSW.x, pNE.y, (pNE.x - pSW.x) + antimeridianOveflow, (pSW.y - pNE.y));
//        [self.mapView setVisibleMapRect:mapRect animated:YES];

        TBBoundingBox world = TBBoundingBoxMake(minLat, minLon, maxLat, maxLon);
        _root = TBQuadTreeBuildWithData(dataArray, (int)i, world, 4);
    }
}

- (NSArray *)clusteredAnnotationsWithinMapRect:(MKMapRect)rect withZoomScale:(double)zoomScale
{
    double TBCellSize = TBCellSizeForZoomScale(zoomScale);
    double scaleFactor = zoomScale / TBCellSize;

    NSInteger minX = floor(MKMapRectGetMinX(rect) * scaleFactor);
    NSInteger maxX = floor(MKMapRectGetMaxX(rect) * scaleFactor);
    NSInteger minY = floor(MKMapRectGetMinY(rect) * scaleFactor);
    NSInteger maxY = floor(MKMapRectGetMaxY(rect) * scaleFactor);

    NSMutableArray *clusteredAnnotations = [[NSMutableArray alloc] init];
    for (NSInteger x = minX; x <= maxX; x++) {
        for (NSInteger y = minY; y <= maxY; y++) {
            MKMapRect mapRect = MKMapRectMake(x / scaleFactor, y / scaleFactor, 1.0 / scaleFactor, 1.0 / scaleFactor);
            
            __block double totalX = 0;
            __block double totalY = 0;
            __block int count = 0;

            NSMutableArray *titles = [NSMutableArray array];
            NSMutableArray *subtitles = [NSMutableArray array];
            NSMutableArray *indexs = [NSMutableArray array];
            NSMutableArray *tags = [NSMutableArray array];
            NSMutableArray *icons = [NSMutableArray array];
            NSMutableArray *uuids = [NSMutableArray array];

            TBQuadTreeGatherDataInRange(self.root, TBBoundingBoxForMapRect(mapRect), ^(TBQuadTreeNodeData data) {
                totalX += data.x;
                totalY += data.y;
                count++;
                
                TBInfo info = *(TBInfo *)data.info;
                
                NSString *title = [NSString stringWithCString:info.title encoding:NSUTF8StringEncoding];
                NSString *subtitle = [NSString stringWithCString:info.subtitle encoding:NSUTF8StringEncoding];
                NSString *icon = [NSString stringWithCString:data.icon encoding:NSUTF8StringEncoding];
                NSString *uuid = [NSString stringWithCString:data.uuid encoding:NSUTF8StringEncoding];
                title = [NSString stringWithFormat:@"%@", title];
                subtitle = [NSString stringWithFormat:@"%@", subtitle];
                icon = [NSString stringWithFormat:@"%@", icon];
                uuid = [NSString stringWithFormat:@"%@", uuid];
//
//                if (title == NULL) {
//                    title = @"";
//                }
//                if (subtitle == NULL) {
//                    subtitle = @"";
//                }
                
                // Sửa lỗi chuyển đổi từ CString sang NSString = null
                // (bỏ % sau khi chuyển qua NSString)
                title = [title stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                subtitle = [subtitle stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                icon = [icon stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                uuid = [uuid stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [titles addObject:title];
                [subtitles addObject:subtitle];
                [indexs addObject:[NSNumber numberWithUnsignedInteger:data.index]];
                [tags addObject:[NSNumber numberWithInteger:data.tag]];
                [icons addObject:icon];
                [uuids addObject:uuid];
            });

            if (count == 1) {
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(totalX, totalY);
                TBClusterAnnotation *annotation = [[TBClusterAnnotation alloc] initWithCoordinate:coordinate count:count];
                annotation.title = [titles lastObject];
                annotation.subtitle = [subtitles lastObject];
                annotation.icon = [icons lastObject];
                annotation.uuid = [uuids lastObject];
                annotation.index = [[indexs lastObject] unsignedIntegerValue];
                annotation.tag = [[tags lastObject] unsignedIntegerValue];
                [clusteredAnnotations addObject:annotation];
            }

            if (count > 1) {
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(totalX / count, totalY / count);
                TBClusterAnnotation *annotation = [[TBClusterAnnotation alloc] initWithCoordinate:coordinate count:count];
                annotation.boundingMapRect = mapRect;
                annotation.subtitle = indexs.description;
                [clusteredAnnotations addObject:annotation];
            }
        }
    }

    return [NSArray arrayWithArray:clusteredAnnotations];
}

@end
