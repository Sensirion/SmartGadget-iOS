//
//  BLEService.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "BLEService.h"

#import <CoreBluetooth/CoreBluetooth.h>

@implementation BLEService

- (id)initService:(CBService *)service withParent:(BLEGadget *)parent {
    _service = service;
    _parent = parent;

    return self;
}

- (BOOL)checkService:(CBService *)service {
    return [_service isEqual:service];
}

/* Behave properly when heading into the background */
- (void)enteredBackground {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

/* Behave properly when heading back from the background */
- (void)enteredForeground {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

/* To be handled in child classes */
- (void)onNewCharacteristicsForService:(CBService *)service {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

/* To be handled in child classes */
- (BOOL)handleCharacteristicsValues:(CBCharacteristic *)characteristic {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end