//
//  RHTPoint.m
//  smartgadgetapp
//
//  Copyright (c) 2014 Sensirion AG. All rights reserved.
//

#import "RHTPoint.h"

#import "Settings.h"

@interface RHTPoint () {
    
    CGFloat _temperatureInCelcius;
}

@end

@implementation RHTPoint

- (RHTPoint *)initWithTempInCelcius:(CGFloat)tempInCelcius andRelativeHumidity:(CGFloat)humidity; {
    self = [super init];
    _temperatureInCelcius = tempInCelcius;
    _relativeHumidity = humidity;
    
    return self;
}

- (CGFloat)temperature {
    return [RHTPoint adjustTemp:_temperatureInCelcius forUnit:[[Settings userDefaults] tempUnitType]];
}

- (CGFloat)dew_point {
    return [RHTPoint getDewPointForHumidity:_relativeHumidity atTemperature:_temperatureInCelcius];
}

+ (CGFloat) adjustTemp:(CGFloat)tempInCelcius forUnit:(enum temperature_unit_type)unit {
    switch (unit) {
        case UNIT_CELCIUS:
            return tempInCelcius;
        case UNIT_FARENHEIT:
            return (tempInCelcius * 9 / 5) + 32;
        default:
            [NSException raise:@"Unknown temperature unit" format:@"unit: %u", unit];
            break;
    }
    
    return NAN;
}

+ (CGFloat) getDewPointForHumidity:(CGFloat)relativeHumidity atTemperature:(CGFloat)tempInCelcius {
    CGFloat H = log(relativeHumidity/100.0) + (17.62*tempInCelcius)/(243.12+tempInCelcius);
    CGFloat Dp = 243.12*H/(17.62-H); // this is the dew point in Celsius
        
    return [RHTPoint adjustTemp:Dp forUnit:[[Settings userDefaults] tempUnitType]];
}

@end
