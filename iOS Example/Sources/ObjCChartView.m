//
//  ObjCChartView.m
//  iOS Example
//
//  Created by Andreas Neusüß on 12.06.20.
//  Copyright © 2020 Anerma. All rights reserved.
//

#import "ObjCChartView.h"

@interface ObjCChartView()
@property (nonatomic) ANNAudiograph *audiograph;

- (void)configureAccessibility;
@end

@implementation ObjCChartView

- (ANNAudiograph *)audiograph {
    if (!_audiograph) {
        _audiograph = [[ANNAudiograph alloc] initWithLocalizations:AudiographLocalizations.defaultEnglish];
        
        // Perform different configurations like this:
        [_audiograph setExactSmoothing:0.3];
        [_audiograph setSmoothing:ANNSmoothingOptionDefault];
        
        [_audiograph setExactPlayingDuration:2.0];
        [_audiograph setPlayingDuration:ANNPlayingDurationRecommended];
        
        
    }
    
    return _audiograph;
}

- (NSArray* ) graphContent {
    
    // Use your chart content here:
    return @[[NSValue valueWithCGPoint:CGPointMake(0, 0)], [NSValue valueWithCGPoint:CGPointMake(10, 20)], [NSValue valueWithCGPoint:CGPointMake(30, 10)]];
}

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configureAccessibility];
    }
    return self;
}

- (void)configureAccessibility {
    self.isAccessibilityElement = true;
    self.shouldGroupAccessibilityChildren = true;
    self.accessibilityLabel = @"Chart, price over time";
    self.accessibilityHint = @"Actions for playing Audiograph available.";
    
    // This view should be the accessible chart view:
    self.accessibilityCustomActions = @[[self.audiograph createCustomAccessibilityActionForView:self]];
}

@end
