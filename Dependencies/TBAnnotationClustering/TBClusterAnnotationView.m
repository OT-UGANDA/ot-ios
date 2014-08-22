//
//  TBClusterAnnotationView.m
//  TBAnnotationClustering
//
//  Created by Theodore Calmes on 10/4/13.
//  Copyright (c) 2013 Theodore Calmes. All rights reserved.
//  Modified by Tran Trung Chuyen on 2/10/2014
//

#import "TBClusterAnnotationView.h"

CGPoint TBRectCenter(CGRect rect) {
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CGRect TBCenterRect(CGRect rect, CGPoint center) {
    CGRect r = CGRectMake(center.x - rect.size.width/2.0,
                          center.y - rect.size.height/2.0,
                          rect.size.width,
                          rect.size.height);
    return r;
}

static CGFloat const TBScaleFactorAlpha = 0.3;
static CGFloat const TBScaleFactorBeta = 0.4;

CGFloat TBScaledValueForValue(CGFloat value) {
    return 1.0 / (1.0 + expf(-1 * TBScaleFactorAlpha * powf(value, TBScaleFactorBeta)));
}

@interface TBClusterAnnotationView ()
@property (strong, nonatomic) UILabel* countLabel;
@end

@implementation TBClusterAnnotationView

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setupLabel];
        [self setCount:1];
    }
    return self;
}

- (void)setupLabel
{
    _countLabel = [[UILabel alloc] initWithFrame:self.frame];
    _countLabel.backgroundColor = [UIColor clearColor];
    _countLabel.textColor = [UIColor whiteColor];
    _countLabel.textAlignment = NSTextAlignmentCenter;
    _countLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.75];
    _countLabel.shadowOffset = CGSizeMake(0, -1);
    _countLabel.adjustsFontSizeToFitWidth = YES;
    _countLabel.numberOfLines = 1;
    _countLabel.font = [UIFont boldSystemFontOfSize:12];
    _countLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    [self addSubview:_countLabel];
}

- (void)setCount:(NSUInteger)count
{
    _count = count;
    if (_count > 1) {
        CGRect newBounds = CGRectMake(0, 0, roundf(88 * TBScaledValueForValue(1)+TBScaledValueForValue(1) * [[@(_count) stringValue] length]), roundf(88 * TBScaledValueForValue(1)+TBScaledValueForValue(1) * [[@(_count) stringValue] length]));
        self.frame = TBCenterRect(newBounds, self.center);
        CGRect newLabelBounds = CGRectMake(0, 0, newBounds.size.width / 1.3, newBounds.size.height / 1.3);
        self.countLabel.frame = TBCenterRect(newLabelBounds, TBRectCenter(newBounds));
        _countLabel.backgroundColor = [UIColor clearColor];
        _countLabel.textColor = [UIColor whiteColor];
        _countLabel.textAlignment = NSTextAlignmentCenter;
        _countLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.75];
        _countLabel.shadowOffset = CGSizeMake(1, 0.5);
        _countLabel.adjustsFontSizeToFitWidth = YES;
        _countLabel.numberOfLines = 1;
        _countLabel.font = [UIFont boldSystemFontOfSize:12];
        _countLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        self.countLabel.text = [@(_count) stringValue];
    } else {
        CGRect newBounds = CGRectMake(0, 0, roundf(44 * TBScaledValueForValue(1) + TBScaledValueForValue(1) * [[@(_count) stringValue] length]), roundf(44 * TBScaledValueForValue(1) + TBScaledValueForValue(1) * [[@(_count) stringValue] length]));
        self.frame = TBCenterRect(newBounds, self.center);
        CGRect newLabelBounds = CGRectMake(0, 0, newBounds.size.width / 1.3, newBounds.size.height / 1.3);
        newLabelBounds.size.width = roundf(([[self.annotation title] length] + 1) * 11 * TBScaledValueForValue(count));
        if (newLabelBounds.size.width == 0)
            newLabelBounds.size.width = newBounds.size.width;
        newLabelBounds.size.height = 20;
        CGRect frame = TBCenterRect(newLabelBounds, TBRectCenter(newBounds));
        frame.origin.y = 32;
        self.countLabel.frame = frame;
        self.countLabel.backgroundColor = [UIColor clearColor];
        self.countLabel.layer.cornerRadius = 3;
        self.countLabel.clipsToBounds = YES;
        self.countLabel.textColor = [UIColor otDarkBlue];
        self.countLabel.textAlignment = NSTextAlignmentCenter;
        self.countLabel.shadowColor = [UIColor otLightGrey];
        self.countLabel.shadowOffset = CGSizeMake(1, 0.5);
        self.countLabel.adjustsFontSizeToFitWidth = NO;
        self.countLabel.numberOfLines = 1;
        self.countLabel.font = [UIFont boldSystemFontOfSize:12];
        self.countLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        self.countLabel.text = [self.annotation title];
    }

    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGRect newBounds = CGRectMake(0, 0, roundf(88 * TBScaledValueForValue(1)+
                                               TBScaledValueForValue(1) * [[@(_count) stringValue] length]),
                                  roundf(88 * TBScaledValueForValue(1)+
                                         TBScaledValueForValue(1) * [[@(_count) stringValue] length]));
    self.frame = TBCenterRect(newBounds, self.center);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetAllowsAntialiasing(context, true);
    
    CGFloat r = 102.0/255.0; CGFloat g = 204.0/255.0; CGFloat b = 51.0/255.0;
    
    UIColor *defaultColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
    UIColor *color1 = [UIColor colorWithRed:r green:g blue:b alpha:0.8];
    UIColor *color2 = [UIColor colorWithRed:r green:g blue:b alpha:0.5];
    UIColor *color3 = [UIColor colorWithRed:r green:g blue:b alpha:0.2];
    
    CGFloat startAngle1 = 220.0*M_PI/180.0;
    CGFloat endAngle1 = 320.0*M_PI/180.0;
    CGFloat startAngle2 = 340.0*M_PI/180.0;
    CGFloat endAngle2 = 80.0*M_PI/180.0;
    CGFloat startAngle3 = 100.0*M_PI/180.0;
    CGFloat endAngle3 = 200.0*M_PI/180.0;
    
    CGRect circleFrame = CGRectInset(rect, 4, 4);
    CGFloat x = circleFrame.origin.x + circleFrame.size.width / 2.0;
    CGFloat y = circleFrame.origin.y + circleFrame.size.height / 2.0;
    CGFloat radius = circleFrame.size.height / 2.0;
    
    [color3 setStroke];
    CGContextSetLineWidth(context, 3);
    CGContextAddArc(context, x, y, radius, startAngle1, endAngle1, 0);
    CGContextStrokePath(context);
    CGContextAddArc(context, x, y, radius, startAngle2, endAngle2, 0);
    CGContextStrokePath(context);
    CGContextAddArc(context, x, y, radius, startAngle3, endAngle3, 0);
    CGContextStrokePath(context);
    
    circleFrame.size.width -= 8;
    circleFrame.size.height -= 8;
    radius = circleFrame.size.height / 2.0;
    circleFrame = TBCenterRect(circleFrame, TBRectCenter(newBounds));
    [color2 setStroke];
    CGContextSetLineWidth(context, 3);
    CGContextAddArc(context, x, y, radius, startAngle1, endAngle1, 0);
    CGContextStrokePath(context);
    CGContextAddArc(context, x, y, radius, startAngle2, endAngle2, 0);
    CGContextStrokePath(context);
    CGContextAddArc(context, x, y, radius, startAngle3, endAngle3, 0);
    CGContextStrokePath(context);

    circleFrame.size.width -= 8;
    circleFrame.size.height -= 8;
    radius = circleFrame.size.height / 2.0;
    circleFrame = TBCenterRect(circleFrame, TBRectCenter(newBounds));
    [color1 setStroke];
    CGContextSetLineWidth(context, 3);
    CGContextAddArc(context, x, y, radius, startAngle1, endAngle1, 0);
    CGContextStrokePath(context);
    CGContextAddArc(context, x, y, radius, startAngle2, endAngle2, 0);
    CGContextStrokePath(context);
    CGContextAddArc(context, x, y, radius, startAngle3, endAngle3, 0);
    CGContextStrokePath(context);

    circleFrame.size.width -= 5;
    circleFrame.size.height -= 5;
    circleFrame = TBCenterRect(circleFrame, TBRectCenter(newBounds));
    [defaultColor setFill];
    CGContextFillEllipseInRect(context, circleFrame);
}

@end
