//
//  BLEServiceProperty.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "BLEServiceProperty.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "BLEGadget.h"

@interface BLEServiceProperty () {

    BLEGadget *_parent;
    CBCharacteristic *_characteristic;

    NSData *_value;
}

@end

@implementation BLEServiceProperty

- (BLEServiceProperty *)init:(CBCharacteristic *)characteristic withParent:(BLEGadget *)parent {
    _parent = parent;
    _characteristic = characteristic;

    //read initial value
    [_parent readValueForCharacteristic:_characteristic];

    return self;
}

- (BOOL)handleValueUpdated:(CBCharacteristic *)characteristic {
    if ([_characteristic isEqual:characteristic]) {
        _value = characteristic.value;
        return YES;
    }

    return NO;
}

- (void)getValue:(void *)buffer length:(NSUInteger)length {

    if (_value && length > 0) {
        [_value getBytes:buffer length:length];
    } else {
        buffer = nil;
    }
}


- (void)setValue:(void *)buffer length:(NSUInteger)length {
    if (_parent && _characteristic && length > 0) {
        _value = [NSData dataWithBytes:buffer length:length];
        NSLog(@"Writing value of: %@/%@ => %@", [[_characteristic service] UUID], [_characteristic UUID], _value);

        [_parent writeValue:_value forCharacteristic:_characteristic];
    }
}

- (void)update {
    //re-request value from peripheral
    _value = nil;
    [_parent readValueForCharacteristic:_characteristic];
}

/* re-request value from peripheral, but don't delete value before we will get new... */
- (void)updateEventually {
    [_parent readValueForCharacteristic:_characteristic];
}

- (BOOL)hasValue {
    return (_value != nil);
}

//TYPED PROPERTY ACCESS

- (BOOL)getBool {
    BOOL ret = NO;

    [self getValue:&ret length:sizeof(ret)];

    return ret;
}

- (void)setBool:(BOOL)value {
    [self setValue:&value length:sizeof(value)];
}

- (uint8_t)getExtraShort {
    uint8_t ret = 0;

    [self getValue:&ret length:sizeof(ret)];

    return ret;
}

- (void)setExtraShort:(uint8_t)value {
    [self setValue:&value length:sizeof(value)];
}

- (uint16_t)getShort {
    uint16_t ret = 0;

    [self getValue:&ret length:sizeof(ret)];

    return ret;
}

- (void)setShort:(uint16_t)value {
    [self setValue:&value length:sizeof(value)];
}

- (uint32_t)getIntValue {
    uint32_t ret = 0;

    [self getValue:&ret length:sizeof(ret)];

    return ret;
}

- (void)setIntValue:(uint32_t)value {
    [self setValue:&value length:sizeof(value)];
}

- (uint64_t)getLongValue {
    uint64_t ret = 0;

    [self getValue:&ret length:sizeof(ret)];
    return ret;
}

- (void)setLongValue:(uint64_t)value {
    [self setValue:&value length:sizeof(value)];
}

@end
