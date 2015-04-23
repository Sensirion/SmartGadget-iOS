//
//  SmartgadgetHistoryService.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BleService.h"
#import "LogService.h"

@interface SmartgadgetHistoryService : BLEService <LogServiceProtocol>
+ (CBUUID *)serviceId;

- (uint64_t)getOldestTimestampToDownload;

- (uint64_t)getNewestTimestampToDownload;

- (void)onNewHumidityData:(CGFloat)humidity andSequenceNumber:(uint32_t)sequenceNumber;

- (void)onNewTemperatureData:(CGFloat)temperature andSequenceNumber:(uint32_t)sequenceNumber;
@end