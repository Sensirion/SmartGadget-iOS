//
//  BatteryService.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "BatteryService.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "BLEGadget.h"
#import "BLEUtil.h"

static NSString * const BATTERY_SERV_UUID_STRING = @"180F";
static NSString * const BATTERY_LEVEL_UUID_STRING = @"2A19";

@interface BatteryService() {
    
    CBCharacteristic *_batteryLevelCharacteristic;
}

@end

@implementation BatteryService

+ (CBUUID *)serviceId {
    return [CBUUID UUIDWithString:BATTERY_SERV_UUID_STRING];
}

//--------------------------------------------------------------------------------
// Properties
//--------------------------------------------------------------------------------

- (CGFloat)batteryLevel {
    int16_t value = 0;
    
    if (_batteryLevelCharacteristic) {
        [[_batteryLevelCharacteristic value] getBytes:&value length:sizeof (value)];
    }
    
    return value / 100.0F;
}

//--------------------------------------------------------------------------------
// BLEService implementation
//--------------------------------------------------------------------------------

- (void)enteredBackground {
    //do nothing
}

- (void)enteredForeground {
    //do nothing
}

- (void)onNewCharacteristicsForService:(CBService *)service {
    if ([self checkService:service]) {
        for (CBCharacteristic *characteristic in [service characteristics]) {
            if ([[CBUUID UUIDWithString:BATTERY_LEVEL_UUID_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered Battery Level Characteristic");
                _batteryLevelCharacteristic = characteristic;
                [_parent readValueForCharacteristic:characteristic];
            } else {
                NSLog(@"Unknown charactetistic for battery service: %@", [characteristic UUID]);
            }
        }
    }
}

- (BOOL)handleCharacteristicsValues:(CBCharacteristic *)characteristic {
    if ([_batteryLevelCharacteristic isEqual:characteristic]) {
        return YES;
    }
    
    return NO;
}

@end
