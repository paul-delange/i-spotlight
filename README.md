i-spotlight
===========

iOS compatible spotlight view that uses iOS7 blur effect and accepts an NSAttributedString or NSString to display a message


Usage
===========

``` objective-c
NSString* format = NSLocalizedString(@"Welcome to %@! You can start by completing our demo here.\n\nWhen you have finished our quiz, you can register and get access to over %@", @"");
        NSString* salesPitch = NSLocalizedString(@"1000 free points", @"");
        
        NSString* fullString = [NSString stringWithFormat: format, @"MyApp", salesPitch];
        
        NSRange salesPitchRange = [fullString rangeOfString: salesPitch];
        
        NSShadow* shadow = [NSShadow new];
        shadow.shadowOffset = CGSizeMake(1., 1.);
        shadow.shadowColor = [UIColor blackColor];
        shadow.shadowBlurRadius = 2.f;
        
        NSDictionary* normalAttributes = @{ NSFontAttributeName : [UIFont systemFontOfSize: 18.f], NSShadowAttributeName : shadow };
        NSDictionary* boldAttributes = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize: 20.f], NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle), NSShadowAttributeName : shadow };
        
        NSMutableAttributedString* mutableString = [[NSMutableAttributedString alloc] initWithString: fullString attributes: normalAttributes];
        [mutableString setAttributes: boldAttributes range: salesPitchRange];
        
      	// self.demoButton = a view to have spotlighted
        [SpotlightView spotlight: self.demoButton andDisplayText: mutableString];

```

Doesn't Support
===========
Rotation
iOS below 6.0