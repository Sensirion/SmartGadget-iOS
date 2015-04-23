//
//  BatteryService.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "BLEService.h"

@class CBUUID;

@interface BatteryService : BLEService

+ (CBUUID *)serviceId;

@property(readonly) CGFloat batteryLevel;

@end