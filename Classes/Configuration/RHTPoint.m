//
//  RHTPoint.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "RHTPoint.h"

#import "Settings.h"

@interface RHTPoint () {
    CGFloat _temperatureInCelsius;
}

@end

@implementation RHTPoint

- (RHTPoint *)initWithTempInCelsius:(CGFloat)tempInCelsius andRelativeHumidity:(CGFloat)humidity; {
    self = [super init];
    _temperatureInCelsius = tempInCelsius;
    _relativeHumidity = humidity;

    return self;
}

- (CGFloat)temperature {
    return [RHTPoint adjustCelsiusTemperature:_temperatureInCelsius forUnit:[[Settings userDefaults] tempUnitType]];
}

- (CGFloat)dewPoint {
    return [RHTPoint getDewPointForHumidity:_relativeHumidity atTemperature:_temperatureInCelsius];
}

- (CGFloat)heatIndex {
    CGFloat heatIndexInCelsius = [RHTPoint getHeatIndexInCelsiusForHumidity:_relativeHumidity atTemperature:_temperatureInCelsius];
    return [RHTPoint adjustCelsiusTemperature:heatIndexInCelsius forUnit:[[Settings userDefaults] tempUnitType]];
}

+ (CGFloat)adjustCelsiusTemperature:(CGFloat)tempInCelsius forUnit:(enum temperature_unit_type)unit {
    switch (unit) {
        case UNIT_CELCIUS:
            return tempInCelsius;
        case UNIT_FAHRENHEIT:
            return (tempInCelsius * 9 / 5) + 32;
        default:
            [NSException raise:@"Unknown temperature unit" format:@"unit: %u", unit];
            break;
    }
    return NAN;
}

+ (CGFloat)adjustFahrenheitTemperature:(CGFloat)tempInFahrenheit forUnit:(enum temperature_unit_type)unit {
    switch (unit) {
        case UNIT_CELCIUS:
            return (tempInFahrenheit - 32.0f) * 5 / 9;
        case UNIT_FAHRENHEIT:
            return tempInFahrenheit;
        default:
            [NSException raise:@"Unknown temperature unit" format:@"unit: %u", unit];
            break;
    }

    return NAN;
}

+ (CGFloat)getDewPointForHumidity:(CGFloat)relativeHumidity atTemperature:(CGFloat)tempInCelsius {
    CGFloat H = (CGFloat) (log(relativeHumidity / 100.0f) + (17.62f * tempInCelsius) / (243.12f + tempInCelsius));
    CGFloat Dp = 243.12f * H / (17.62f - H); // this is the dew point in Celsius

    return [RHTPoint adjustCelsiusTemperature:Dp forUnit:[[Settings userDefaults] tempUnitType]];
}

/**
* This method obtains the heat index of a temperature and humidity
* using the formula from: http://en.wikipedia.org/wiki/Heat_index that
* comes from Stull, Richard (2000). Meteorology for Scientists and
* Engineers, Second Edition. Brooks/Cole. p. 60. ISBN 9780534372149.
*/
+ (CGFloat)getHeatIndexInCelsiusForHumidity:(CGFloat)humidity atTemperature:(CGFloat)tempInCelsius {
    CGFloat temperatureInFahrenheit = [self adjustCelsiusTemperature:tempInCelsius forUnit:UNIT_FAHRENHEIT];

    //Checks if the temperature and the humidity are inside the threshold in order to obtain the heat index.
    if (temperatureInFahrenheit < 70.0f || temperatureInFahrenheit > 115.0 || humidity < 0 || humidity > 100) {
        return NAN;
    }

    //Prepares values for improving the readability of the method.
    CGFloat t2 = temperatureInFahrenheit * temperatureInFahrenheit;
    CGFloat t3 = t2 * temperatureInFahrenheit;
    CGFloat h2 = humidity * humidity;
    CGFloat h3 = h2 * humidity;

    CGFloat heatIndexInFahrenheit = 16.923f
            + 0.185212f * temperatureInFahrenheit
            + 5.37941f * humidity
            + -0.100254f * temperatureInFahrenheit * humidity
            + 9.41695E-3f * t2
            + 7.28898E-3f * h2
            + 3.45372E-4f * t2 * humidity
            + -8.14971E-4f * temperatureInFahrenheit * h2
            + 1.02102E-5f * t2 * h2
            + -3.8646E-5f * t3
            + 2.91583E-5f * h3
            + 1.42721E-6f * t3 * humidity
            + 1.97483E-7f * temperatureInFahrenheit * h3
            + -2.18429E-8f * t3 * h2
            + 8.43296E-10f * t2 * h3
            + -4.81975E-11f * t3 * h3;

    return [self adjustFahrenheitTemperature:heatIndexInFahrenheit forUnit:UNIT_CELCIUS]; //Returns the heat index in Celsius.
}

@end