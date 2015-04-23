//
//  Shtc1LoggerService.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "BLEService.h"
#import "BLEProperty.h"
#import "LogServiceDelegate.h"
#import "LogService.h"

@class CBUUID;
@class GadgetData;

@interface Shtc1LoggerService : BLEService <LogServiceProtocol>

+ (CBUUID *)serviceId;

@end