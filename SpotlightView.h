//
//  SpotlightView.h
//  Rad Exam
//
//  Created by Paul DE LANGE on 26/02/13.
//  Copyright (c) 2013 xxx. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ENABLE_BLUR_EFFECT  1

@class SpotlightView;

typedef void (^kSpotlightDismissedCallback)(SpotlightView* view, BOOL animated);

@interface SpotlightView : UIView

+ (UIWindow*) window;

+ (instancetype) spotlight: (UIView*) viewToSpotlight andDisplayText: (id) text;
+ (instancetype) spotlight: (UIView*) viewToSpotlight andDisplayText: (id) text dismissedCallback: (kSpotlightDismissedCallback) completion;

@end
