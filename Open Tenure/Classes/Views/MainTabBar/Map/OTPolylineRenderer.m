//
//  OTPolylineRenderer.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 7/24/15.
//  Copyright (c) 2015 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTPolylineRenderer.h"

static CGFloat const TBScaleFactorAlpha = 0.3;
static CGFloat const TBScaleFactorBeta = 0.4;

NS_INLINE CGFloat GMScaledValueForValue(CGFloat value) {
    return 1.0 / (1.0 + expf(-1 * TBScaleFactorAlpha * powf(value, TBScaleFactorBeta)));
}

@implementation OTPolylineRenderer

- (id)initWithPolyline:(MKPolyline *)polyline {
    if (self = [super initWithPolyline:polyline]) {
        CGMutablePathRef path = CGPathCreateMutable();
        BOOL pathIsEmpty = YES;
        for (int i=0;i< polyline.pointCount;i++){
            CGPoint point = [self pointForMapPoint:polyline.points[i]];
            if (pathIsEmpty){
                CGPathMoveToPoint(path, nil, point.x, point.y);
                pathIsEmpty = NO;
            } else {
                CGPathAddLineToPoint(path, nil, point.x, point.y);
            }
        }
        self.path = path;
    }
    return self;
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    //calculate CG values from circle coordinate and radius...
    CGFloat lineWidth = MKRoadWidthAtZoomScale(zoomScale);
    MKPolyline *overlay = self.overlay;
    if (overlay.accessibilityLabel != nil) {
        CGContextAddPath(context, self.path);
        MKMapPoint *points = overlay.points;
        MKMapPoint midPoint = MKMapPointMake(points[0].x + ((points[1].x - points[0].x) / 2.0),
                                             points[0].y + ((points[1].y - points[0].y) / 2.0));
        CLLocationDistance distance = MKMetersBetweenMapPoints(points[0], points[1]);
        NSString *text = [NSString stringWithFormat:@"%0.3f", distance];

        CGContextSetStrokeColorWithColor(context, [[UIColor blueColor] CGColor]);
        CGContextSetFillColorWithColor(context,  [[UIColor blueColor] CGColor]);
        CGContextSetLineWidth(context, lineWidth / 10);
        CGContextStrokePath(context);
        
        [self drawLabel:context at:midPoint text:text rotate:0 bgColor:[UIColor otDarkBlue] color:[UIColor whiteColor] zoomScale:zoomScale];
    } else {
        [super drawMapRect:mapRect zoomScale:zoomScale inContext:context];
    }
}

- (void)drawLabel:(CGContextRef)context at:(MKMapPoint)centerPoint text:(NSString *)text rotate:(double)theta bgColor:(UIColor *)bgColor color:(UIColor *)color zoomScale:(double)zoomScale {
    double size = MKRoadWidthAtZoomScale(zoomScale);
    CGPoint pm = [self pointForMapPoint:centerPoint];
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, pm.x, pm.y);
    CGContextRotateCTM(context, theta);
    UIGraphicsPushContext(context);
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    //Set line break mode
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    //Set text alignment
    paragraphStyle.alignment = NSTextAlignmentCenter;
    double fontSize = size * 2. * GMScaledValueForValue(1);
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor lightGrayColor];
    shadow.shadowBlurRadius = 0.0;
    shadow.shadowOffset = CGSizeMake(0.5, 0.5);
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:fontSize], NSForegroundColorAttributeName:color, NSShadowAttributeName:shadow, NSParagraphStyleAttributeName:paragraphStyle};
    
    // Ve background
    
    CGRect frame = CGRectMake(0, 0,
                              roundf(size*GMScaledValueForValue(1) / 2. + [text length] * fontSize / 2.),
                              roundf(fontSize));
    // Set the starting point of the shape.
    // |^---------|
    // |  ABCDEF  |
    // |----------|
    [bgColor setFill];
    [bgColor setStroke];
    UIBezierPath *aPath = [UIBezierPath bezierPath];
    double space = size * 2.;
    CGPoint p0 = CGPointMake(-space / 6., size / 4.);
    CGPoint cp1 = CGPointMake( space / 8., space);
    CGPoint p1 = CGPointMake(space / 3, space);
    CGPoint p2 = CGPointMake(frame.size.width, space);
    CGPoint p3 = CGPointMake(frame.size.width, frame.size.height + space);
    CGPoint p4 = CGPointMake(0, frame.size.height + space);
    CGPoint p5 = CGPointMake(0, space);
    
    [aPath moveToPoint:p0];
    [aPath addQuadCurveToPoint:p1 controlPoint:cp1];
    [aPath addLineToPoint:p2];
    [aPath addLineToPoint:p3];
    [aPath addLineToPoint:p4];
    [aPath addLineToPoint:p5];
    [aPath addLineToPoint:p0];
    [aPath fill];
    CGMutablePathRef path = CGPathCreateMutableCopy(aPath.CGPath);
    if (path) {
        CGContextAddPath(context, path);
        CGContextSetLineWidth(context, size / 10.);
        CGContextStrokePath(context);
        CGPathRelease(path);
    }
    CGContextTranslateCTM(context, frame.origin.x, frame.origin.y + space - GMScaledValueForValue(1) * size / 2.);
    // Quay nguoc lai
    if ((theta < 3.*M_PI_2) && (theta > M_PI_2)) {
        CGContextTranslateCTM(context, frame.size.width, frame.origin.y + space - GMScaledValueForValue(1) * size / 2.);
        CGContextRotateCTM(context, M_PI);
    }
    
    [text drawAtPoint:CGPointMake(0, size / 6.) withAttributes:attributes];
    
    UIGraphicsPopContext();
    CGContextRestoreGState(context);
}

@end
