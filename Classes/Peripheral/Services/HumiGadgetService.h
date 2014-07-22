//
//  HumiGadgetService.h
//  smartgadgetapp
//
//  Copyright (c) 2012 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BLEService.h"
#import "HumiService.h"

@class CBPeripheral;
@class CBUUID;

static NSString * const HUMI_GADGET_NAME = @"SHTC1 smart gadget";

@interface HumiGadgetService : BLEService<HumiServiceProtocol>

+ (CBUUID *)serviceId;

+ (CGFloat)rawDataPointToTemperature:(NSData *)rawPoint;
+ (CGFloat)rawDataPointToHumidity:(NSData *)rawPoint;

@end
