//
//  SmartgadgetTemperatureService.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEService.h"
#import "HumiService.h"
#import "SmartgadgetHumiService.h"

@interface SmartgadgetTemperatureService : BLEService <SmartgadgetHumiServiceProtocol>

+ (CBUUID *)serviceId;

+ (CGFloat)rawDataPointToTemperature:(NSData *)rawPoint;

- (CGFloat)temperature;
@end