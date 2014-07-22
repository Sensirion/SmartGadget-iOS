//
//  SensorTagHumiService.m
//  smartgadgetapp
//
//  Copyright (c) 2012 Sensirion AG. All rights reserved.
//

#import "SensorTagHumiService.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "BLEGadget.h"
#import "BLEServiceProperty.h"
#import "BLEUtil.h"
#import "RHTPoint.h"
#import "Settings.h"

static NSString * const SENSOR_TAG_HUMI_SERVICE_UUID_STRING  = @"F000AA20-0451-4000-B000-000000000000";

static NSString * const SENSOR_TAG_NOTIFICATION_UUID_STRING  = @"F000AA21-0451-4000-B000-000000000000";
static NSString * const SENSOR_TAG_CONFIGURATION_UUID_STRING = @"F000AA22-0451-4000-B000-000000000000";

@interface SensorTagHumiService() {

    CBCharacteristic *_notificationCharacteristic;
    BLEServiceProperty *_configProperty;
    
    BOOL _hasSensorValues;
    BOOL _setNotify;
}
@end

@implementation SensorTagHumiService

+ (CBUUID *)serviceId {
    return [CBUUID UUIDWithString:SENSOR_TAG_HUMI_SERVICE_UUID_STRING];
}

//----------------------------------------------------------------------------------
// Properties
//----------------------------------------------------------------------------------

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
    int16_t value = 0;
    
    if (_notificationCharacteristic) {
        [[_notificationCharacteristic value] getBytes:&value length:sizeof (value)];
        result = ((value/(float)0x10000) * 175.72F) - 46.85F;
    }
    
    return result;
}

- (CGFloat)humidity {
    CGFloat result = NAN;
    int32_t value = 0;
    
    if (_notificationCharacteristic) {
        [[_notificationCharacteristic value] getBytes:&value length:sizeof (value)];
        value = (value >> 16) & 0xFFFF;
        result = ((value/(float)0x10000) * 125) - 6;
    }

    return result;
}

- (void)setNotifiy:(BOOL)notify {
    if (_notificationCharacteristic) {
        [_parent setNotifyValue:notify forCharacteristic:_notificationCharacteristic];
    }
    
    _setNotify = notify;
}

//--------------------------------------------------------------------------------
// BLEService implementation
//--------------------------------------------------------------------------------

/**
 * If we're connected, we don't want to get notifications while we're in the background.
 */
- (void)enteredBackground {
    if (_setNotify) {
        if (_notificationCharacteristic) {
            [_parent setNotifyValue:NO forCharacteristic:_notificationCharacteristic];
            NSLog(@"Unregisterd notification");
        }
        
        if (_configProperty) {
            [_configProperty setBool:NO];
        }
    }
}

/**
 * Coming back from the background, we want to register for notifications again
 */
- (void)enteredForeground {
    if (_setNotify) {
        if (_configProperty) {
            [_configProperty setBool:YES];
        }
        
        if (_notificationCharacteristic) {
            [_parent setNotifyValue:YES forCharacteristic:_notificationCharacteristic];
            NSLog(@"Re-registerd notification");
        }
    }
}

- (void)onNewCharacteristicsForService:(CBService *)service {
    if ([self checkService:service]) {        
        for (CBCharacteristic *characteristic in [service characteristics]) {
            if ([[CBUUID UUIDWithString:SENSOR_TAG_NOTIFICATION_UUID_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered Humi Notification Characteristic");
                _notificationCharacteristic = characteristic;
                
                NSLog(@"Will sett notify to %s", _setNotify ? "ON" : "OFF");
                //in case setNotify was called before characteristic was discovered
                if (_setNotify) {
                    [_parent setNotifyValue:YES forCharacteristic:_notificationCharacteristic];
                }
            }
            else if ([[CBUUID UUIDWithString:SENSOR_TAG_CONFIGURATION_UUID_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered Humi Configuration Characteristic");
                _configProperty = [[BLEServiceProperty alloc]init:characteristic withParent:_parent];
                [_configProperty setBool:YES];
            } else {
                NSLog(@"Discovered unknown characteristic: %@", [characteristic UUID]);
            }
        }
    }
}

- (BOOL)handleCharacteristicsValues:(CBCharacteristic *)characteristic {
    if ([characteristic isEqual:_notificationCharacteristic]) {
        _hasSensorValues = YES;
        return YES;
    } else if ([_configProperty handleValueUpdated:characteristic]) {
        return YES;
    }

    return NO;
}

@end
