//
//  SmartgadgetTemperatureService.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "BLEGadget.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "SmartgadgetHistoryService.h"
#import "SmartgadgetTemperatureService.h"
#import "RHTPoint.h"
#import "SmartgadgetHumidityService.h"

static NSString *const HUMIDITY_SERVICE_UUID_STRING = @"00002234-b38d-4985-720e-0f993a68ee41";
static NSString *const TEMPERATURE_DATA_CHARACTERISTIC_STRING = @"00002235-b38d-4985-720e-0F993a68ee41";

static uint8_t DATA_POINT_SIZE = 4;

@implementation SmartgadgetTemperatureService {
    CBCharacteristic *_liveDataCharacteristic;
    BOOL _hasLiveDataValues;
    BOOL _liveDataValue;

    CGFloat _temperatureLiveDataValue;
}

+ (CBUUID *)serviceId {
    return [CBUUID UUIDWithString:HUMIDITY_SERVICE_UUID_STRING];
}

+ (CGFloat)rawDataPointToTemperature:(NSData *)rawPoint {
    Float32 value;
    assert(sizeof(value) == [rawPoint length]);
    [rawPoint getBytes:&value length:sizeof(value)];
    return value;
}

//----------------------------------------------------------------------------------------------------
// Properties
//----------------------------------------------------------------------------------------------------

- (CGFloat)temperature {
    if (_liveDataCharacteristic) {
        if ([[_liveDataCharacteristic value] length] == DATA_POINT_SIZE) {
            _temperatureLiveDataValue = [SmartgadgetTemperatureService rawDataPointToTemperature:[_liveDataCharacteristic value]];;
            NSLog(@"Extracted temperature value %f", _temperatureLiveDataValue);
        }
    }
    return _temperatureLiveDataValue;
}


- (BOOL)hasLiveDataValues {
    return _hasLiveDataValues;
}

- (void)setNotify:(BOOL)notify {
    if (_liveDataCharacteristic && _liveDataValue) {
        [_parent setNotifyValue:notify forCharacteristic:_liveDataCharacteristic];
        NSLog(@"%@Registered temperature live data notification", (notify) ? @"" : @"Un");
    }
}

- (RHTPoint *)currentValue {
    if ([_parent HumidityService]) {
        CGFloat humidity = [[_parent HumidityService] humidity];
        if (humidity) {
            return [[RHTPoint alloc] initWithTempInCelsius:self.temperature andRelativeHumidity:humidity];
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
            if ([[CBUUID UUIDWithString:TEMPERATURE_DATA_CHARACTERISTIC_STRING] isEqual:[characteristic UUID]]) {
                _temperatureLiveDataValue = NAN;
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
    _liveDataValue = 0;
    NSLog(@"Discovered Humi Notification Characteristic");
    _liveDataCharacteristic = characteristic;

    if (_liveDataCharacteristic) {
        [_parent readValueForCharacteristic:characteristic];
        [_parent setNotifyValue:YES forCharacteristic:_liveDataCharacteristic];
        NSLog(@"Registered Humi Notification Characteristic with UUID %@", TEMPERATURE_DATA_CHARACTERISTIC_STRING);
    }
}

- (BOOL)handleCharacteristicsValues:(CBCharacteristic *)characteristic {
    if ([_liveDataCharacteristic isEqual:characteristic]) {
        if ([characteristic value].length > DATA_POINT_SIZE) {
            [self onNewHistoricalTemperature:[_liveDataCharacteristic value]];
        } else {
            _hasLiveDataValues = YES;
        }
        return YES;
    }
    return NO;
}

- (void)onNewHistoricalTemperature:(NSData *)rawPoint {
    NSData *sequenceNumberRawPoint = [NSData dataWithBytesNoCopy:(char *) [rawPoint bytes] length:4 freeWhenDone:NO];
    uint32_t sequenceNumber;
    [sequenceNumberRawPoint getBytes:&sequenceNumber length:sizeof(sequenceNumber)];

    for (int i = sizeof(sequenceNumber); i < rawPoint.length; i += DATA_POINT_SIZE) {
        NSData *chunk = [NSData dataWithBytesNoCopy:(char *) [rawPoint bytes] + i length:DATA_POINT_SIZE freeWhenDone:NO];
        CGFloat extractedTemperature = [SmartgadgetTemperatureService rawDataPointToTemperature:chunk];
        uint32_t extractedValueSequenceNumber = sequenceNumber + ((i - sizeof(sequenceNumber)) / DATA_POINT_SIZE);
        [(SmartgadgetHistoryService *) [_parent LoggerService] onNewTemperatureData:extractedTemperature andSequenceNumber:extractedValueSequenceNumber];
        NSLog(@"Extracted temperature %f for sequence number = %u.", extractedTemperature, extractedValueSequenceNumber);
    }
}

@end