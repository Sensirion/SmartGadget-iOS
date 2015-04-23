//
//  DeviceInfoService.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "BLEService.h"

@class CBUUID;

@interface DeviceInfoService : BLEService

+ (CBUUID *)serviceId;

@property(readonly) uint64_t systemId;

@end