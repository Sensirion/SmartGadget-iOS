//
//  GadgetSettingsService.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "BLEProperty.h"
#import "BLEService.h"

@class CBUUID;

@interface GadgetSettingsService : BLEService

+ (CBUUID *)serviceId;

@property (readonly) id<MutableBOOLProperty> connectionSpeedSlowDown;

@end
