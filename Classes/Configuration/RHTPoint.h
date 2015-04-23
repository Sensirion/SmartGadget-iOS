//
//  RHTPoint.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Configuration.h"

@interface RHTPoint : NSObject

+ (CGFloat)adjustCelsiusTemperature:(CGFloat)tempInCelsius forUnit:(enum temperature_unit_type)unit;

+ (CGFloat)getDewPointForHumidity:(CGFloat)relativeHumidity atTemperature:(CGFloat)tempInCelsius;

+ (CGFloat)getHeatIndexInCelsiusForHumidity:(CGFloat)humidity atTemperature:(CGFloat)tempInCelsius;

- (RHTPoint *)initWithTempInCelsius:(CGFloat)tempInCelsius andRelativeHumidity:(CGFloat)humidity;

@property(readonly) CGFloat temperature;
@property(readonly) CGFloat dewPoint;
@property(readonly) CGFloat relativeHumidity;
@property(readonly) CGFloat heatIndex;

@end