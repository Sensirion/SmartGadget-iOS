//
//  SensirionDefaultTheme.m
//  smartgadgetapp
//
//  Copyright (c) 2014 Sensirion AG. All rights reserved.
//

#import "SensirionDefaultTheme.h"

#import "Configuration.h"

@implementation SensirionDefaultTheme

+ (void)applyTheme:(UILabel *)label {
    [label setShadowColor:[UIColor SENSIRION_LIGHT_GRAY]];
    [label setShadowOffset:CGSizeMake(1, 1.5)];
    [label setTextColor:[UIColor SENSIRION_TEXT_GRAY]];
}

@end
