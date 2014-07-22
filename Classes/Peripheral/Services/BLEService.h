//
//  BLEService.h
//  smartgadgetapp
//
//  Copyright (c) 2012 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BLEGadget;
@class CBCharacteristic;
@class CBService;

@interface BLEService : NSObject {
@protected
    BLEGadget *_parent;
    CBService *_service;
}

- (id)initService:(CBService *)service withParent:(BLEGadget *)parent;

- (BOOL)checkService:(CBService *)service;

/* Behave properly when heading into and out of the background */
- (void)enteredBackground;
- (void)enteredForeground;

- (void)onNewCharacteristicsForService:(CBService *)service;

- (BOOL)handleCharacteristicsValues:(CBCharacteristic *)characteristic;

@end
