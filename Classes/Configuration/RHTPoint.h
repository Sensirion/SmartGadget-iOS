//
//  RHTPoint.h
//  smartgadgetapp
//
//  Copyright (c) 2014 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Configuration.h"

@interface RHTPoint : NSObject

+ (CGFloat)adjustTemp:(CGFloat)tempInCelcius forUnit:(enum temperature_unit_type)unit;
+ (CGFloat)getDewPointForHumidity:(CGFloat)relativeHumidity atTemperature:(CGFloat)tempInCelcius;

- (RHTPoint *)initWithTempInCelcius:(CGFloat)tempInCelcius andRelativeHumidity:(CGFloat)humidity;

@property (readonly) CGFloat temperature;
@property (readonly) CGFloat dew_point;
@property (readonly) CGFloat relativeHumidity;

@end