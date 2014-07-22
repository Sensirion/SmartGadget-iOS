//
//  SensorTagHumiService.h
//  smartgadgetapp
//
//  Copyright (c) 2012 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEService.h"
#import "HumiService.h"

@class CBPeripheral;
@class CBUUID;

static NSString * const SENSOR_TAG_NAME = @"TI BLE Sensor Tag";
static NSString * const SENSOR_TAG_SHORT_NAME = @"SensorTag";

@interface SensorTagHumiService : BLEService<HumiServiceProtocol>

+ (CBUUID *)serviceId;

@end
