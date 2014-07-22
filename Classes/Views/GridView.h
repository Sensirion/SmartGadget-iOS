//
//  GridView.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GridView : UIView

- (void)setupTemperatureRangeFrom:(int)min to:(int)max;
- (void)setupHumidityRangeFrom:(int)min to:(int)max;

- (CGPoint)makePointIn:(CGRect)rect forTemp:(float)temp andHumidity:(float)humididty;
- (CGFloat)tempToHeight:(CGFloat) temp inRect:(CGRect)rect;
- (CGFloat)humidityToWidth:(CGFloat) humidity inRect:(CGRect)rect;

@end
