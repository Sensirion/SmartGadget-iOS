//
//  Shtc1RhtService.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "Shtc1RhtService.h"

#import "BLEGadget.h"
#import "BLEUtil.h"
#import "RHTPoint.h"

static NSString *const HUMI_SERVICE_UUID_STRING = @"AA20";
static NSString *const NOTIFICATION_UUID_CHARACTERISTIC_STRING = @"AA21";

@interface Shtc1RhtService () {

    CBCharacteristic *_notificationCharacteristic;

    BOOL _hasSensorValues;
    BOOL _notifyValue;
}

@end

@implementation Shtc1RhtService

+ (CBUUID *)serviceId {
    return [CBUUID UUIDWithString:HUMI_SERVICE_UUID_STRING];
}

+ (CGFloat)rawDataPointToTemperature:(NSData *)rawPoint {
    int16_t value = 0;
    [rawPoint getBytes:&value length:sizeof(value)];

    return (CGFloat) value / 100.0f;
}

+ (CGFloat)rawDataPointToHumidity:(NSData *)rawPoint {
    int32_t value = 0;
    [rawPoint getBytes:&value length:sizeof(value)];
    value = (value >> 16) & 0xFFFF;

    return (CGFloat) value / 100.0f;
}

//----------------------------------------------------------------------------------------------------
// Properties
//----------------------------------------------------------------------------------------------------

- (BOOL)hasLiveDataValues {
    return _hasSensorValues;
}

- (RHTPoint *)currentValue {
    if ([self hasLiveDataValues]) {
        return [[RHTPoint alloc] initWithTempInCelsius:[self temperature] andRelativeHumidity:[self humidity]];
    }
    return nil;
}

- (CGFloat)temperature {
    CGFloat result = NAN;

    if (_notificationCharacteristic) {
        result = [[self class] rawDataPointToTemperature:[_notificationCharacteristic value]];
    }

    return result;
}

- (CGFloat)humidity {
    CGFloat result = NAN;

    if (_notificationCharacteristic) {
        result = [[self class] rawDataPointToHumidity:[_notificationCharacteristic value]];
    }

    return result;
}

- (void)setNotify:(BOOL)notify {
    if (_notificationCharacteristic) {
        [_parent setNotifyValue:notify forCharacteristic:_notificationCharacteristic];
    }

    _notifyValue = notify;
}

//----------------------------------------------------------------------------------------------------
// BLEService implementation
//----------------------------------------------------------------------------------------------------

/**
* If we're connected, we don't want to get notifications while we're in the background.
*/
- (void)enteredBackground {
    if (_notificationCharacteristic && _notifyValue) {
        [_parent setNotifyValue:NO forCharacteristic:_notificationCharacteristic];
        NSLog(@"Unregistered notification");
    }
}

/**
* Coming back from the background, we want to register for notifications again
*/
- (void)enteredForeground {
    if (_notificationCharacteristic && _notifyValue) {
        [_parent setNotifyValue:YES forCharacteristic:_notificationCharacteristic];
        NSLog(@"Registered notification");
    }
}

- (void)onNewCharacteristicsForService:(CBService *)service {
    if ([self checkService:service]) {
        for (CBCharacteristic *characteristic in [service characteristics]) {
            if ([[CBUUID UUIDWithString:NOTIFICATION_UUID_CHARACTERISTIC_STRING] isEqual:[characteristic UUID]]) {

                NSLog(@"Discovered Humi Notification Characteristic");
                _notificationCharacteristic = characteristic;
                [_parent readValueForCharacteristic:characteristic];

                if (_notifyValue) {
                    [_parent setNotifyValue:YES forCharacteristic:_notificationCharacteristic];
                }

            } else {
                NSLog(@"Discovered unknown characteristic: %@", [characteristic UUID]);
            }
        }
    } else {
        NSLog(@"Discovered characteristics for unknown service: %@", service);
        return;
    }
}

- (BOOL)handleCharacteristicsValues:(CBCharacteristic *)characteristic {
    if ([_notificationCharacteristic isEqual:characteristic]) {
        _hasSensorValues = YES;
        return YES;
    }

    return NO;
}

@end
