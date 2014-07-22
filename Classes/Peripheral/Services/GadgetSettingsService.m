//
//  GadgetSettingsService.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "GadgetSettingsService.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "BLEServiceProperty.h"

static NSString * const SETTINGS_SERVICE_UUID_STRING                       = @"FA10";
static NSString * const CONNECTION_SLOW_DOWN_CHARACTERISTIC_UUID_STRING    = @"FA11";

@interface GadgetSettingsService() {
    BLEServiceProperty *_connectionSpeedProperty;
}

@end

@implementation GadgetSettingsService

+ (CBUUID *)serviceId {
    return [CBUUID UUIDWithString:SETTINGS_SERVICE_UUID_STRING];
}

//----------------------------------------------------------------------------------------------------
// Properties
//----------------------------------------------------------------------------------------------------

- (id<MutableBOOLProperty>)connectionSpeedSlowDown {
    return _connectionSpeedProperty;
}

//----------------------------------------------------------------------------------------------------
// BLEService implementation
//----------------------------------------------------------------------------------------------------

- (void)enteredBackground {
    //do nothing? slow down?
}

- (void)enteredForeground {
    //do nothing? speed up?
}

- (void)onNewCharacteristicsForService:(CBService *)service {
    if ([self checkService:service]) {
        for (CBCharacteristic *characteristic in [service characteristics]) {
            if ([[CBUUID UUIDWithString:CONNECTION_SLOW_DOWN_CHARACTERISTIC_UUID_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered Connection speed characteristic");
                _connectionSpeedProperty = [[BLEServiceProperty alloc] init:characteristic withParent:_parent];
            } else {
                NSLog(@"Discovered unknown characteristic: %@", [characteristic UUID]);
            }
        }
    }
}

- (BOOL)handleCharacteristicsValues:(CBCharacteristic *)characteristic {
    if ([_connectionSpeedProperty handleValueUpdated:characteristic]) {
        return YES;
    }
    
    return NO;
}

@end
