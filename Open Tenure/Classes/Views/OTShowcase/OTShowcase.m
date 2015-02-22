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

#import "OTShowcase.h"

@interface OTShowcase() <UIWebViewDelegate>

- (void)setupBackground;
- (void)setupTextWithTitle: (NSString*) title detailsText : (NSString*) details;
- (void)onAnimationComplete;
- (UITapGestureRecognizer*)getGesture;

@property (nonatomic) UIColor *titleColor;
@property (nonatomic) UIColor *detailsColor;
@property (nonatomic) UIColor *backgroundColor;
@property (nonatomic) UIColor *highlightColor;
@property (nonatomic) UIFont *titleFont;
@property (nonatomic) UIFont *detailsFont;
@property (nonatomic) NSTextAlignment titleAlignment;
@property (nonatomic) NSTextAlignment detailsAlignment;
@property (nonatomic) CGFloat radius;
@property (nonatomic) int iType;
@property (nonatomic, retain) id containerView;

@property (nonatomic) CGRect showcaseRect;
@property (nonatomic, assign) UIOffset offsetFromCenter;

@end

@implementation OTShowcase

int const TYPE_NONE = -1;
int const TYPE_CIRCLE = 0;
int const TYPE_RECTANGLE = 1;

@synthesize delegate;
@synthesize showcaseImageView;
@synthesize detailsLabel;
@synthesize showcaseRect;
@synthesize containerView;
@synthesize nextButton;
@synthesize skipButton;

- (id)init {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionShowcase:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    return [self initWithTitleFont:[UIFont boldSystemFontOfSize:24.0f] detailsFont:[UIFont systemFontOfSize:16.0f] titleColor:[UIColor whiteColor] detailsColor:[UIColor whiteColor]];
}

- (id)initWithTitleFont:(UIFont *)titleFont detailsFont:(UIFont *)detailsFont {
    return [self initWithTitleFont:titleFont detailsFont:detailsFont titleColor:[UIColor whiteColor] detailsColor:[UIColor whiteColor]];
}

- (id)initWithTitleColor:(UIColor *)titleColor detailsColor:(UIColor *)detailsColor {
    return [self initWithTitleFont:[UIFont boldSystemFontOfSize:24.0f] detailsFont:[UIFont systemFontOfSize:16.0f] titleColor:titleColor detailsColor:detailsColor];
}

- (id)initWithTitleFont:(UIFont *)titleFont detailsFont:(UIFont *)detailsFont titleColor:(UIColor *)titleColor detailsColor:(UIColor *)detailsColor {
    self.backgroundColor = [UIColor blackColor];
    self.titleFont = titleFont;
    self.titleColor = titleColor;
    self.detailsFont = detailsFont;
    self.detailsColor = detailsColor;
    self.highlightColor = [OTShowcase colorFromHexString:@"#1397C5"];
    self.titleAlignment = NSTextAlignmentCenter;
    self.detailsAlignment = NSTextAlignmentCenter;
    self.iType = TYPE_RECTANGLE;
    self.radius = 25.0f;
    
    CGRect frame = [[UIScreen mainScreen] bounds];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
        } else {
            frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
        }
    }
    
    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |  UIViewAutoresizingFlexibleRightMargin;
    return [self initWithFrame:frame];
}

- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle {
    self.transform = CGAffineTransformMakeRotation(angle);
    self.center = CGPointMake(newCenter.x + self.offsetFromCenter.horizontal, newCenter.y + self.offsetFromCenter.vertical);
}

- (void)setupShowcaseForTarget:(id)target title:(NSString *)title details:(NSString *)details {
    if ([target isKindOfClass:[NSArray class]]) {
        CGRect rect = CGRectNull;
        for (UIView *view in target) {
            CGRect frame = [view convertRect:[view bounds] toView:containerView];
            rect = CGRectUnion(rect, frame);
        }
        [self setupShowcaseForLocation:rect title:title details:details];
    } else {
        CGRect frame = [target convertRect:[target bounds] toView:containerView];
        CGFloat width = frame.size.height > frame.size.width ? frame.size.height : frame.size.width;
        self.radius = width / 2.0;
        [self setupShowcaseForLocation:[target convertRect:[target bounds] toView:containerView] title:title details:details];
    }
}

- (void)setupShowcaseForLocation:(CGRect)location title:(NSString *)title details:(NSString *)details {
    self.showcaseRect = location;
    [self setupBackground];
    [self setupTextWithTitle:title detailsText:details];
    
    [self addSubview:showcaseImageView];
    [self addSubview:detailsLabel];
    
    [self addSubview:skipButton];
    [self addSubview:nextButton];
    
    //[self addGestureRecognizer:[self getGesture]];
}

- (void)show {
    [self setShowing:YES];
    [self showInContainer:containerView];
}

- (void)showInContainer:(id)container {
    containerView = container;
    self.alpha = 1.0f;
    for (UIView* view in [container subviews])
    {
        [view setUserInteractionEnabled:NO];
    }
    
    [UIView transitionWithView:container
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [container addSubview:self];
                    }
                    completion:^(BOOL finished) {
                        [delegate OTShowcaseShown];
                    }];
}

- (UIButton *)customButtonWithTitle:(NSString *)title {
    NSDictionary *attribute = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:17.0]};
    CGSize size = [title sizeWithAttributes:attribute];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, size.width + 24.0f, size.height + 16.0f);
    button.backgroundColor = [UIColor colorWithRed:0.0f green:122.0f/255.0f blue:1.0f alpha:1.0f];
    button.layer.cornerRadius = 2.0;
    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:17.0]];
    [button setShowsTouchWhenHighlighted:YES];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [button setTitle:title forState:UIControlStateNormal];
    return button;
}

- (IBAction)positionShowcase:(NSNotification *)notification {
    if ([self isShowing])
        [self showcaseTapped];
    [self setShowing:NO];
    CGRect frame = CGRectMake(0, 0, [containerView bounds].size.width, [containerView bounds].size.height);
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        frame = CGRectMake(0, 0, [containerView bounds].size.height, [containerView bounds].size.width);
    }
    self.frame = frame;
}

- (IBAction)nextPressed:(id)sender {
    if (self.nextActionBlock) {
        [self.nextButton setHighlighted:!self.nextButton.highlighted];
        self.nextActionBlock();
        [self.nextButton setHighlighted:!self.nextButton.highlighted];
    }
}

- (IBAction)skipPressed:(id)sender {
    if (self.skipActionBlock) {
        [self.skipButton setHighlighted:!self.skipButton.highlighted];
        self.skipActionBlock();
        [self.skipButton setHighlighted:!self.skipButton.highlighted];
    }
}

- (void)setupBackground
{
    // Black Background
    UIGraphicsBeginImageContextWithOptions([containerView bounds].size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [self.backgroundColor CGColor]);
    CGContextFillRect(context, [containerView bounds]);
    
    if (self.iType == TYPE_RECTANGLE )
    {
        // Outer Highlight
        CGRect highlightRect = CGRectMake(showcaseRect.origin.x - 15, showcaseRect.origin.y - 15, showcaseRect.size.width + 30, showcaseRect.size.height + 30);
        CGContextSetShadowWithColor(context, CGSizeZero, 30.0f, self.highlightColor.CGColor);
        CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
        CGContextSetStrokeColorWithColor(context, self.highlightColor.CGColor);
        CGContextAddPath(context, [UIBezierPath bezierPathWithRect:highlightRect].CGPath);
        CGContextDrawPath(context, kCGPathFillStroke);
        
        // Inner Highlight
        CGContextSetLineWidth(context, 3.0f);
        CGContextAddPath(context, [UIBezierPath bezierPathWithRect:showcaseRect].CGPath);
        CGContextDrawPath(context, kCGPathFillStroke);
        
        UIImage *showcase = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // Clear Region
        UIGraphicsBeginImageContext(showcase.size);
        [showcase drawAtPoint:CGPointZero];
        context = UIGraphicsGetCurrentContext();
        CGContextClearRect(context, showcaseRect);
    }
    else if (self.iType == TYPE_CIRCLE)
    {
        CGPoint center = CGPointMake(showcaseRect.origin.x + showcaseRect.size.width / 2.0f, showcaseRect.origin.y + showcaseRect.size.height / 2.0f);
        
        // Draw Highlight
        CGContextSetLineWidth(context, 2.54f);
        CGContextSetShadowWithColor(context, CGSizeZero, 30.0f, self.highlightColor.CGColor);
        CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
        CGContextSetStrokeColorWithColor(context, self.highlightColor.CGColor);
        CGContextAddArc(context, center.x, center.y, self.radius * 2.0f, 0, 2 * M_PI, 0);
        CGContextDrawPath(context, kCGPathFillStroke);
        CGContextAddArc(context, center.x, center.y, self.radius, 0, 2 * M_PI, 0);
        CGContextDrawPath(context, kCGPathFillStroke);
        
        // Clear Circle
        CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
        CGContextSetBlendMode(context, kCGBlendModeClear);
        CGContextAddArc(context, center.x, center.y, self.radius - 0.54, 0, 2 * M_PI, 0);
        CGContextDrawPath(context, kCGPathFill);
        CGContextSetBlendMode(context, kCGBlendModeNormal);
    }
    showcaseImageView = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
    [showcaseImageView setAlpha:0.75f];
}

- (void)setupTextWithTitle:(NSString *)title detailsText:(NSString *)details {
    CGRect frame = [[UIScreen mainScreen] bounds];
    detailsLabel = [[UIWebView alloc] initWithFrame:frame];
    detailsLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [detailsLabel setDelegate:self];
    [detailsLabel setBackgroundColor:[UIColor clearColor]];
    [detailsLabel setOpaque:NO];
    [detailsLabel setScalesPageToFit:NO];
    [SVProgressHUD show];
    NSString *htmlFormat = @"<!DOCTYPE html><html><head><meta charset='UTF-8'><style>#container{display:table;height:%.0fpx;}#content{display:table-cell;vertical-align:middle;}body{font-family:'Helvetica Neue', Helvetica, Arial, sans-serif;padding-left:20px;padding-right:20px;}h1{color:#0aff0a}p,div{color:#ffffff}</style></head><body><div id='container'><div id='content'><h1>%@</h1><div>%@</div></div></div></body></html>";
    NSString *htmlContent = [NSString stringWithFormat:htmlFormat, frame.size.height, title, details];
    [detailsLabel loadHTMLString:htmlContent baseURL:nil];
    
    // Setup buttons
    skipButton = [self customButtonWithTitle:NSLocalizedStringFromTable(@"skip", @"Showcase", nil)];
    CGRect skipButtonFrame = skipButton.frame;
    
    skipButtonFrame.origin.x = 16.0f;
    skipButtonFrame.origin.y = [containerView bounds].size.height - skipButtonFrame.size.height - 16.0f;
    skipButton.frame = skipButtonFrame;
    [skipButton addTarget:self action:@selector(skipPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    nextButton = [self customButtonWithTitle:NSLocalizedStringFromTable(@"next", @"Showcase", nil)];
    CGRect nextButtonFrame = nextButton.frame;
    nextButtonFrame.origin.x = [containerView bounds].size.width - nextButtonFrame.size.width - 16.0f;
    nextButtonFrame.origin.y = [containerView bounds].size.height - nextButtonFrame.size.height - 16.0f;
    nextButton.frame = nextButtonFrame;
    [nextButton addTarget:self action:@selector(nextPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (UITapGestureRecognizer *)getGesture {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showcaseTapped)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    return singleTap;
}

- (void)showcaseTapped {
    [UIView animateWithDuration:0.5 animations:^{ self.alpha = 0.0f; } completion:^(BOOL finished) { [self onAnimationComplete]; } ];
}

- (void)onAnimationComplete {
    for (UIView *view in [self.containerView subviews])
    {
        [view setUserInteractionEnabled:YES];
    }
    [showcaseImageView removeFromSuperview];
    showcaseImageView = NULL;
    [detailsLabel removeFromSuperview];
    detailsLabel = NULL;
    [self removeFromSuperview];
    
    [skipButton removeFromSuperview];
    skipButton = NULL;
    [nextButton removeFromSuperview];
    nextButton = NULL;
    
    [delegate OTShowcaseDismissed];
}

+ (UIColor *)colorFromHexString:(NSString *)hexCode {
    NSString *cleanString = [hexCode stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    float alpha = ((baseValue >> 0) & 0xFF)/255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    
}

#pragma mark - UIWebViewDelegate method

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [SVProgressHUD dismiss];
}

@end
