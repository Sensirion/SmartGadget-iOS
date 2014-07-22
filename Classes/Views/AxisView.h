//
//  AxisView.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AxisView : UIView

- (void)setIncrement:(float)majorIncrement withLowerBound:(int)lowerBound andUpperBound:(int)upperBound;
- (void)setName:(NSString *)name withUnit:(NSString *)unit;

@end
