//
//  Settings.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Configuration.h"

@interface Settings : NSObject

+ (Settings *)userDefaults;

- (UIColor *)getColorForGadget:(NSString *)gadgetUUID;
- (void)releaseColorForGadget:(NSString *)gadgetUUID;

- (NSString *)getStoredDescriptionForGadget:(uint64_t)gadgetIdentifier;
- (void)setStoredDescription:(NSString *)description forGadget:(uint64_t)gadgetIdentifier;

@property NSString *selectedGadgetUUID;
@property NSDate *lastDownloadFinished;
@property uint64_t selectedLogIdentifier;
@property uint64_t currentlyIsDownloading;
@property enum comfort_zone_type comfortZone;
@property enum display_type upperMainButonDisplayes;
@property enum display_type lowerMainButonDisplayes;
@property enum temperature_unit_type tempUnitType;

@property (readonly) BOOL isFirstTime;
@property (readonly) BOOL useMetric;

@end
