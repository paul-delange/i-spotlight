//
//  SpotlightView.m
//  Rad Exam
//
//  Created by Paul DE LANGE on 26/02/13.
//  Copyright (c) 2013 xxx. All rights reserved.
//

#import "SpotlightView.h"

#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>

#define kSpotlightViewTag  91431
#define kSpotlightLabelViewTag  91432

static UIImage *CFIImageFromView(UIView *view) {
	
#ifdef __IPHONE_7_0
#error 'Not ready'
    //See Session 226 WWDC 2013 (Video time: 14:30)
    //      -> will want to use snapshotView:
    if( [UIView respondsToSelector: @selector(drawViewHeirachyInRect:)]) {
        CGSize size = view.bounds.size;
        
        CGFloat scale = UIScreen.mainScreen.scale;
        size.width *= scale;
        size.height *= scale;
        
        UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(ctx, scale, scale);
        
        [view drawViewHierachyInRect: view.bounds];
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image;

    }
    else {
#endif
        CGSize size = view.bounds.size;
        
        CGFloat scale = UIScreen.mainScreen.scale;
        size.width *= scale;
        size.height *= scale;
        
        UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(ctx, scale, scale);
        
        [view.layer renderInContext:ctx];
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image;
#ifdef __IPHONE_7_0
    }
#endif
}

@interface SpotlightView ()

@property (weak, nonatomic) UIView* target;
@property (readonly, nonatomic) UILabel* labelView;
@property (copy, nonatomic) kSpotlightDismissedCallback callback;

@end

@implementation SpotlightView

+ (NSTimeInterval) animationDuration {
    return [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
}

+ (UIWindow*) window {
    return [UIApplication sharedApplication].windows[0];
}

+ (UIView*) hostView {
    UIWindow* window = [self window];
    UIViewController* rootViewController = window.rootViewController;
    NSParameterAssert(rootViewController);
    NSParameterAssert(rootViewController.isViewLoaded);
    return rootViewController.view;
}

+ (instancetype) spotlight: (UIView*) viewToSpotlight andDisplayText: (id) text {
    return [self spotlight: viewToSpotlight andDisplayText: text dismissedCallback: nil];
}

+ (instancetype) spotlight: (UIView*) viewToSpotlight andDisplayText: (id) text dismissedCallback:(kSpotlightDismissedCallback)completion {
    if(!viewToSpotlight.superview)
        return nil;
    
    UIView* window = [self hostView];
    SpotlightView* oldSpotlight = (SpotlightView*)[window viewWithTag: kSpotlightViewTag];
    if( oldSpotlight )
        return nil;
    
    SpotlightView *newSpotlight = [[SpotlightView alloc] initWithFrame: window.bounds];
    newSpotlight.target = viewToSpotlight;

    NSParameterAssert([text isKindOfClass: [NSString class]] || [text isKindOfClass: [NSAttributedString class]]);
    
    if( [text isKindOfClass: [NSString class]] )
        newSpotlight.labelView.text = text;
    else if( [text isKindOfClass: [NSAttributedString class]] )
        newSpotlight.labelView.attributedText = text;

    newSpotlight.backgroundColor = [UIColor clearColor];
    newSpotlight.callback = completion;
    newSpotlight.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    newSpotlight.tag = kSpotlightViewTag;
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget: newSpotlight action: @selector(tapRecognized:)];
    [newSpotlight addGestureRecognizer: tap];
    
    [UIView transitionWithView: window
                      duration: [self animationDuration]
                       options: UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^{
                        [window addSubview: newSpotlight];
                    } completion: ^(BOOL finished) {
                        NSParameterAssert([text respondsToSelector: @selector(length)]);
                        [newSpotlight performSelector: @selector(dismissAnimated:)
                                           withObject: newSpotlight
                                           afterDelay: [text length] * 0.25];
                    }];
    
    return newSpotlight;
}

- (void) dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
}

- (void) didMoveToSuperview {
    [super didMoveToSuperview];
    
    //Start focusing animation
}

- (CGRect) rectToHighlight {
    UIView* window = [self.class hostView];
    CGRect wanted = [window convertRect: self.target.frame fromView: self.target.superview];
    return wanted;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = CGRectInset(self.bounds, 20.f, 20.f);
    CGRect highlightRect = [self rectToHighlight];
    CGSize labelSize = [self.labelView.text sizeWithFont: self.labelView.font
                                       constrainedToSize: bounds.size
                                           lineBreakMode: NSLineBreakByWordWrapping];
    
    
    //Find a good rectangle to display our text
    CGRect labelRect = CGRectZero;
    CGFloat heightBelow = CGRectGetHeight(self.bounds) - CGRectGetMaxY(highlightRect);
    CGFloat heightAbove = CGRectGetMinY(highlightRect);
    CGFloat xOffset = (CGRectGetWidth(self.bounds) - labelSize.width)/2.f;
    
    if( heightAbove > heightBelow ) {
        //Have to go above
        labelRect = CGRectMake(xOffset, 0, labelSize.width, heightAbove);
    }
    else if( heightAbove == 0 && heightBelow == 0 ) {
        labelRect = CGRectMake(xOffset, CGRectGetMaxY(highlightRect) * 0.75, labelSize.width, labelSize.height);
    }
    else {
        //Go below by default
        labelRect = CGRectMake(xOffset, CGRectGetMaxY(highlightRect), labelSize.width, heightBelow);
    }
    
    self.labelView.frame = labelRect;
    
}

- (void) dismissAnimated: (BOOL) animated {
    UIView* window = [self.class hostView];
    [UIView transitionWithView: window
                      duration: [self.class animationDuration] * (animated ? 1 : 0)
                       options: UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^{
                        [self removeFromSuperview];
                    } completion:^(BOOL finished) {
                        if( self.callback ) {
                            self.callback(self, animated);
                        }
                    }];
}

#if ENABLE_BLUR_EFFECT
+ (UIImage*) blurredBackgroundImage {
    //TODO: Apple provide an official category to do this:
    //      https://github.com/justinmfischer/core-background/blob/master/core-background/CBG/Categories/UIImage%2BImageEffects.h
    
    UIImage* image = CFIImageFromView([SpotlightView hostView]);
    int boxSize = 21;
    
    CGImageRef img = image.CGImage;
    
    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    void *pixelBuffer;
    
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL,
                                       0, 0, boxSize, boxSize, NULL,
                                       kvImageEdgeExtend);
    
    
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(
                                             outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             CGImageGetBitmapInfo(image.CGImage));
    
    CGImageRef imgRef = CGBitmapContextCreateImage (ctx);
    
    UIImage* returnImage = [UIImage imageWithCGImage: imgRef];
    
    CGImageRelease(imgRef);
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    CFRelease(inBitmapData);
    
    return returnImage;
}

#endif

- (void) drawRect:(CGRect)rect {
    if( self.target.superview ) {
        
        CGRect highlightRect = [self rectToHighlight];
        
        float roundness = 1.f;//CGRectGetHeight(highlightRect) / CGRectGetWidth(highlightRect);
        
        CGPoint highlightPoint = CGPointMake(CGRectGetMidX(highlightRect), CGRectGetMidY(highlightRect)/roundness);
        CGFloat startRadius = MIN(CGRectGetWidth(highlightRect) * 0.8, 100);
        CGFloat endRadius = startRadius * 1.25;
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(context, 1, roundness);
        
#if ENABLE_BLUR_EFFECT
        UIImage* background = [SpotlightView blurredBackgroundImage];
        
        UIBezierPath* clipPath = [UIBezierPath bezierPathWithRect: CGRectInfinite];
        clipPath.usesEvenOddFillRule = YES;
        
        CGFloat radius = (startRadius + endRadius) / 2.f;
        CGRect circle = CGRectMake(highlightPoint.x-radius, highlightPoint.y-radius, radius*2.f, radius*2.f);
        
        [clipPath appendPath: [UIBezierPath bezierPathWithOvalInRect: circle]];
        
        
        CGContextSaveGState(context); {
            [clipPath addClip];
            [background drawInRect: [SpotlightView hostView].bounds];
            
        } CGContextRestoreGState(context);
#endif
        
        UIColor* blue = IMAIOS_BLUE;
        const CGFloat* blueComponents = CGColorGetComponents(blue.CGColor);
        
        size_t locationsCount = 3;
        CGFloat locations[3] = {
            0.0f,
            0.5f,
            1.0f
        };
        CGFloat colors[12] = {
            blueComponents[0], blueComponents[1], blueComponents[2], .0f,
            blueComponents[0], blueComponents[1], blueComponents[2], 1.0f,
            0.0f,0.0f,0.0f,0.5f
        };
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
        
        CGContextDrawRadialGradient(context, gradient, highlightPoint, startRadius, highlightPoint, endRadius, kCGGradientDrawsAfterEndLocation);
        
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
    }
}

- (UILabel*) labelView {
    UILabel* label = (UILabel*)[self viewWithTag: kSpotlightLabelViewTag];
    if( !label ) {
        label = [[UILabel alloc] initWithFrame: self.bounds];
        label.tag = kSpotlightLabelViewTag;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 0;
        label.shadowColor = [UIColor blackColor];
        label.shadowOffset = CGSizeMake(1., 1.);
        label.adjustsFontSizeToFitWidth = YES;
        [self addSubview: label];
    }
    return label;
}

- (IBAction) tapRecognized: (UITapGestureRecognizer*)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [self dismissAnimated: YES];
}

@end
