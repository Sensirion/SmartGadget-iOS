//
//  DeviceInfoService.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "DeviceInfoService.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "BLEGadget.h"
#import "BLEUtil.h"

static NSString * const DEVINFO_SERV_UUID_STRING              = @"180A";

static NSString * const DEVINFO_SYSTEM_ID_UUID_STRING         = @"2A23";
static NSString * const DEVINFO_MODEL_NUMBER_UUID_STRING      = @"2A24";
static NSString * const DEVINFO_SERIAL_NUMBER_UUID_STRING     = @"2A25";
static NSString * const DEVINFO_FIRMWARE_REV_UUID_STRING      = @"2A26";
static NSString * const DEVINFO_HARDWARE_REV_UUID_STRING      = @"2A27";
static NSString * const DEVINFO_SOFTWARE_REV_UUID_STRING      = @"2A28";
static NSString * const DEVINFO_MANUFACTURER_NAME_UUID_STRING = @"2A29";
static NSString * const DEVINFO_11073_CERT_DATA_UUID_STRING   = @"2A2A";
static NSString * const PNPID_DATA_UUID_STRING                = @"2A50";

@interface DeviceInfoService() {
    CBCharacteristic *_systemIDCharacteristic;
}

@end

@implementation DeviceInfoService

+ (CBUUID *)serviceId {
    return [CBUUID UUIDWithString:DEVINFO_SERV_UUID_STRING];
}

//--------------------------------------------------------------------------------
// Properties
//--------------------------------------------------------------------------------

- (uint64_t)systemId {
    uint64_t value = 0;
    
    if (_systemIDCharacteristic)
        [[_systemIDCharacteristic value] getBytes:&value length:sizeof(value)];
    
    
    return value;
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
            if ([[CBUUID UUIDWithString:DEVINFO_SYSTEM_ID_UUID_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered System ID Characteristic");
                _systemIDCharacteristic = characteristic;
                [_parent readValueForCharacteristic:characteristic];
            } else {
//                NSLog(@"Not yet interested in charactetistic: %@", [characteristic UUID]);
            }
        }
    }
}

- (BOOL)handleCharacteristicsValues:(CBCharacteristic *)characteristic {
    if ([_systemIDCharacteristic isEqual:characteristic]) {
        return YES;
    }
    
    return NO;
}

@end
