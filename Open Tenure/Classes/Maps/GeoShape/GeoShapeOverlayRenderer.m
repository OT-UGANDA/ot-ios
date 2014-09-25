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

#import "GeoShapeOverlayRenderer.h"
#import "GeoShapeCollection.h"
#import "GeoShape.h"

static CGFloat const ScaleFactorAlpha = 0.3;
static CGFloat const ScaleFactorBeta = 0.4;

CGFloat ScaledValueForValue(CGFloat value) {
    return 1.0 / (1.0 + expf(-1 * ScaleFactorAlpha * powf(value, ScaleFactorBeta)));
}

CGPoint GMRectCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CGRect GMCenterRect(CGRect rect, CGPoint center) {
    CGRect r = CGRectMake(center.x - rect.size.width/2.0,
                          center.y - rect.size.height/2.0,
                          rect.size.width,
                          rect.size.height);
    return r;
}

@implementation GeoShapeOverlayRenderer

- (id)initWithOverlay:(id<MKOverlay>)overlay {
    if (self = [super initWithOverlay:overlay]) {
        
    }
    return self;
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    CGFloat lineWidth = 0.3*MKRoadWidthAtZoomScale(zoomScale);
    GeoShapeCollection *shapes = (GeoShapeCollection *)self.overlay;
    NSArray *objects = [shapes shapesInMapRect:mapRect zoomScale:zoomScale];
    if (objects.count == 0) return;
    CGMutablePathRef path = CGPathCreateMutable();
    [shapes lockForReading];
    for (GeoShape *overlay in objects) {
        if (overlay.pointCount == 0) continue;
        MKMapPoint point, lastPoint = overlay.points[0];
        CGPoint lastCGPoint = [self pointForMapPoint:lastPoint];
        CGPathMoveToPoint(path, NULL, lastCGPoint.x, lastCGPoint.y);
        for (long i = 0; i < overlay.pointCount; i++) {
            point = overlay.points[i];
            CGPoint cgPoint = [self pointForMapPoint:point];
            CGPathAddLineToPoint(path, NULL, cgPoint.x, cgPoint.y);
            lastPoint = point;
        }
        CGPathCloseSubpath(path);
        if (overlay.isAccessibilityElement) {
            [self drawLabel:context at:MKMapPointForCoordinate(overlay.coordinate) text:overlay.title rotate:0 bgColor:[UIColor otDarkBlue] color:[UIColor otDarkBlue] zoomScale:zoomScale];
        }
    }
    [shapes unlockForReading];
    if (path != NULL) {
        CGContextAddPath(context, path);
        CGContextSetStrokeColorWithColor(context, [[UIColor otDarkBlue] CGColor]);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextSetLineWidth(context, lineWidth);
        CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFillStroke);
        CGPathRelease(path);
    }
}

- (void)drawVertex:(CGContextRef)context point:(MKMapPoint)point text:(NSString *)text rotate:(double)theta bgColor:(UIColor *)bgColor color:(UIColor *)color zoomScale:(double)zoomScale {
    double size = MKRoadWidthAtZoomScale(zoomScale);
    CGPoint pm = [self pointForMapPoint:point];
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, pm.x, pm.y);
    UIGraphicsPushContext(context);
    CGRect newBounds = CGRectZero;
    newBounds.size.width = roundf(size);
    newBounds.size.height = roundf(size);
    CGRect frame = GMCenterRect(newBounds, CGPointZero);
    [bgColor setFill];
    [color setStroke];
    CGContextFillEllipseInRect(context, frame);
    CGContextStrokeEllipseInRect(context, frame);
    UIGraphicsPopContext();
    CGContextRestoreGState(context);
}

- (void)drawLabel:(CGContextRef)context at:(MKMapPoint)centerPoint text:(NSString *)text rotate:(double)theta bgColor:(UIColor *)bgColor color:(UIColor *)color zoomScale:(double)zoomScale {
    double size = MKRoadWidthAtZoomScale(zoomScale);
    CGPoint pm = [self pointForMapPoint:centerPoint];
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, pm.x, pm.y);
    UIGraphicsPushContext(context);
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    //Set line break mode
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    //Set text alignment
    paragraphStyle.alignment = NSTextAlignmentCenter;
    double fontSize = size * 2.8 * ScaledValueForValue(1);
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor lightGrayColor];
    shadow.shadowBlurRadius = 0.0;
    shadow.shadowOffset = CGSizeMake(0.5, 0.5);
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:fontSize], NSForegroundColorAttributeName:color, NSShadowAttributeName:shadow, NSParagraphStyleAttributeName:paragraphStyle};
    [@"✖️" drawAtPoint:CGPointMake(0, 0) withAttributes:attributes];

    [text drawAtPoint:CGPointMake(0, fontSize) withAttributes:attributes];

    UIGraphicsPopContext();
    CGContextRestoreGState(context);
}

@end
