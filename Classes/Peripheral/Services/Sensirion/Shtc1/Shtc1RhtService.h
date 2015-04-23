//
//  Shtc1RhtService.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BLEService.h"
#import "HumiService.h"

@class CBPeripheral;
@class CBUUID;

static NSString *const SMARTGADGET_SHTC1_NAME = @"SHTC1 smart gadget";
static NSString *const SMARTGADGET_SHT31_NAME = @"SHT31 smart gadget";

@interface Shtc1RhtService : BLEService <HumiServiceProtocol>

+ (CBUUID *)serviceId;

+ (CGFloat)rawDataPointToTemperature:(NSData *)rawPoint;

+ (CGFloat)rawDataPointToHumidity:(NSData *)rawPoint;

@end
