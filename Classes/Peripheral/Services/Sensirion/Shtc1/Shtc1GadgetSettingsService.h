//
//  Shtc1GadgetSettingsService.h
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "BLEProperty.h"
#import "BLEService.h"

@class CBUUID;

@interface Shtc1GadgetSettingsService : BLEService

+ (CBUUID *)serviceId;

@property(readonly) id <MutableBOOLProperty> connectionSpeedSlowDown;

@end
