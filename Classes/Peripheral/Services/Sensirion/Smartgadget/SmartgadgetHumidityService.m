//
//  SmartgadgetHumidityService.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "BLEGadget.h"
#import "SmartgadgetHistoryService.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "SmartgadgetHumidityService.h"
#import "SmartgadgetTemperatureService.h"
#import "RHTPoint.h"

static NSString *const HUMIDITY_SERVICE_UUID_STRING = @"00001234-b38d-4985-720e-0f993a68ee41";
static NSString *const HUMIDITY_DATA_CHARACTERISTIC_STRING = @"00001235-b38d-4985-720e-0F993a68ee41";

static uint8_t DATA_POINT_SIZE = 4;

@interface SmartgadgetHumidityService () {
    CBCharacteristic *_liveDataCharacteristic;
    BOOL _hasLiveDataValues;
    BOOL _liveDataValue;

    CGFloat _lastLiveHumidityValue;
}

@end

@implementation SmartgadgetHumidityService

+ (CBUUID *)serviceId {
    return [CBUUID UUIDWithString:HUMIDITY_SERVICE_UUID_STRING];
}

+ (CGFloat)rawDataPointToHumidity:(NSData *)rawPoint {
    CGFloat value = 0.0f;
    [rawPoint getBytes:&value length:sizeof(value)];
    return value;
}

//----------------------------------------------------------------------------------------------------
// Properties
//----------------------------------------------------------------------------------------------------


- (CGFloat)humidity {
    if (_liveDataCharacteristic) {
        if ([[_liveDataCharacteristic value] length] == DATA_POINT_SIZE) {
            _lastLiveHumidityValue = [SmartgadgetHumidityService rawDataPointToHumidity:[_liveDataCharacteristic value]];
            NSLog(@"Extracted humidity value %f", _lastLiveHumidityValue);
        }
    }
    return _lastLiveHumidityValue;
}


- (BOOL)hasLiveDataValues {
    return _hasLiveDataValues;
}

- (void)setNotify:(BOOL)notify {
    if (_liveDataCharacteristic != nil) {
        [_parent setNotifyValue:notify forCharacteristic:_liveDataCharacteristic];
        NSLog(@"%@Registered humidity data notification", (notify) ? @"" : @"Un");
    }
    _liveDataValue = notify;
}

- (RHTPoint *)currentValue {
    if ([_parent TemperatureService]) {
        CGFloat temperature = [[_parent HumidityService] humidity];
        if (temperature) {
            return [[RHTPoint alloc] initWithTempInCelsius:temperature andRelativeHumidity:_lastLiveHumidityValue];
        }
    }
    return nil;
}


//----------------------------------------------------------------------------------------------------
// BLEService implementation
//----------------------------------------------------------------------------------------------------

- (void)enteredBackground {
}

- (void)enteredForeground {
    [self setNotify:YES];
}

- (void)onNewCharacteristicsForService:(CBService *)service {
    if ([self checkService:service]) {
        for (CBCharacteristic *characteristic in [service characteristics]) {
            if ([[CBUUID UUIDWithString:HUMIDITY_DATA_CHARACTERISTIC_STRING] isEqual:[characteristic UUID]]) {
                _lastLiveHumidityValue = NAN;
                [self registerTemperatureDataCharacteristic:characteristic];
            } else {
                NSLog(@"Discovered unknown characteristic: %@", [characteristic UUID]);
            }
        }
    } else {
        NSLog(@"Discovered characteristics for unknown service: %@", service);
        return;
    }
}

- (void)registerTemperatureDataCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"Discovered Humi Notification Characteristic");
    _liveDataCharacteristic = characteristic;

    if (_liveDataCharacteristic) {
        [_parent readValueForCharacteristic:characteristic];
        [_parent setNotifyValue:YES forCharacteristic:_liveDataCharacteristic];
        NSLog(@"Registered Humi Notification Characteristic with UUID %@", HUMIDITY_DATA_CHARACTERISTIC_STRING);
    }
}

- (BOOL)handleCharacteristicsValues:(CBCharacteristic *)characteristic {
    if ([_liveDataCharacteristic isEqual:characteristic]) {
        if ([[characteristic value] length] > DATA_POINT_SIZE) {
            [self onNewHistoricalHumidity:[characteristic value]];
        } else {
            _hasLiveDataValues = YES;
        }
        return YES;
    }
    return NO;
}

- (void)onNewHistoricalHumidity:(NSData *)rawPoint {
    NSData *sequenceNumberRawPoint = [NSData dataWithBytesNoCopy:(char *) [rawPoint bytes] length:4 freeWhenDone:NO];
    uint32_t sequenceNumber;
    [sequenceNumberRawPoint getBytes:&sequenceNumber length:sizeof(sequenceNumber)];

    for (int i = sizeof(sequenceNumber); i < rawPoint.length; i += DATA_POINT_SIZE) {
        NSData *chunk = [NSData dataWithBytesNoCopy:(char *) [rawPoint bytes] + i length:DATA_POINT_SIZE freeWhenDone:NO];
        CGFloat extractedHumidity = [SmartgadgetHumidityService rawDataPointToHumidity:chunk];
        uint32_t extractedValueSequenceNumber = sequenceNumber + ((i - sizeof(sequenceNumber)) / DATA_POINT_SIZE);
        [(SmartgadgetHistoryService *) [_parent LoggerService] onNewHumidityData:extractedHumidity andSequenceNumber:extractedValueSequenceNumber];
        NSLog(@"Extracted humidity %f for sequence number = %u.", extractedHumidity, extractedValueSequenceNumber);
    }
}

@end