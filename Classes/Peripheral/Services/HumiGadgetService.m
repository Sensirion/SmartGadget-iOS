//
//  HumiGadgetService.m
//  smartgadgetapp
//
//  Copyright (c) 2012 Sensirion AG. All rights reserved.
//

#import "HumiGadgetService.h"

#import "BLEGadget.h"
#import "BLEServiceProperty.h"
#import "BLEUtil.h"
#import "Settings.h"
#import "RHTPoint.h"

static NSString * const HUMI_SERVICE_UUID_STRING                 = @"AA20";
static NSString * const NOTIFICATION_UUID_CHARACTERISTIC_STRING  = @"AA21";

@interface HumiGadgetService() {

    CBCharacteristic *_notificationCharacteristic;
    
    BOOL _hasSensorValues;
    BOOL _notifyValue;
}

@end

@implementation HumiGadgetService

+ (CBUUID *)serviceId {
    return [CBUUID UUIDWithString:HUMI_SERVICE_UUID_STRING];
}

+ (CGFloat)rawDataPointToTemperature:(NSData *)rawPoint {
    int16_t value = 0;
    [rawPoint getBytes:&value length:sizeof(value)];
    
    return (CGFloat) value / 100.0F;
}

+ (CGFloat)rawDataPointToHumidity:(NSData *)rawPoint {
    int32_t value = 0;
    [rawPoint getBytes:&value length:sizeof(value)];
    value = (value >> 16) & 0xFFFF;
    
    return (CGFloat) value / 100.0F;
}

//----------------------------------------------------------------------------------------------------
// Properties
//----------------------------------------------------------------------------------------------------

- (BOOL)hasSensorValues {
    return _hasSensorValues;
}

- (RHTPoint *)currentValue {
    RHTPoint *value;
    
    if ([self hasSensorValues]) {
       value = [[RHTPoint alloc] initWithTempInCelcius:[self temperature] andRelativeHumidity:[self humidity]];
    } else {
        value = nil;
    }
    
    return value;
}

- (CGFloat)temperature {
    CGFloat result = NAN;
    
    if (_notificationCharacteristic) {
        result = [[self class] rawDataPointToTemperature:[_notificationCharacteristic value]];
    }
    
    return result;
}

- (CGFloat)humidity {
    CGFloat result  = NAN;
    
    if (_notificationCharacteristic) {
        result = [[self class] rawDataPointToHumidity:[_notificationCharacteristic value]];
    }
    
    return result;
}

- (void)setNotifiy:(BOOL)notify {
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
        NSLog(@"Unregisterd notification");
    }
}

/**
 * Coming back from the background, we want to register for notifications again
 */
- (void)enteredForeground {
    if (_notificationCharacteristic && _notifyValue) {
        [_parent setNotifyValue:YES forCharacteristic:_notificationCharacteristic];
        NSLog(@"Reregisterd notification");
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
