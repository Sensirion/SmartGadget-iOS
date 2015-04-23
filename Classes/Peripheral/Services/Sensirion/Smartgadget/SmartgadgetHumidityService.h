//
//  SmartgadgetHumidityService.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "BLEService.h"
#import "HumiService.h"
#import "SmartgadgetHumiService.h"

@interface SmartgadgetHumidityService : BLEService <SmartgadgetHumiServiceProtocol>

+ (CBUUID *)serviceId;

+ (CGFloat)rawDataPointToHumidity:(NSData *)rawPoint;

- (CGFloat)humidity;

@end