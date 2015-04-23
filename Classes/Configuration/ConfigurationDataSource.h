//
//  ConfigurationDataSource.h
//  smartgadgetapp
//
//  Copyright (c) 2014 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TableViewDataSource <UITableViewDataSource>

@required
- (void)selectConfigurationAtRow:(NSUInteger)row;

@end

@interface ComfortZoneConfigurationDataSource : NSObject <TableViewDataSource>

+ (ComfortZoneConfigurationDataSource *)sharedInstance;

+ (NSString *)currentComfortZoneTitle;

+ (NSArray *)comfortZonePoints;

@end

@interface TemperatureConfigurationDataSource : NSObject <TableViewDataSource>

+ (TemperatureConfigurationDataSource *)sharedInstance;

+ (NSString *)currentTemperatureUnitString;

@end

@protocol PickerViewDataSource

@required

- (NSInteger)numberOfValues;

- (NSInteger)getDefaultValueRow;

- (NSInteger)getValueForRow:(NSInteger)row;

- (NSString *)getTitleForRow:(NSInteger)row;

- (NSString *)getTitleForValue:(uint16_t)value;

@end

@interface DisplayTypePickerDataSource : NSObject <PickerViewDataSource>

+ (DisplayTypePickerDataSource *)sharedInstance;

@end

@interface DisplayTypeWithUnitPickerDataSource : NSObject <PickerViewDataSource>

+ (DisplayTypeWithUnitPickerDataSource *)sharedInstance;

@end

@interface LoggingIntervalPickerDataSource : NSObject <PickerViewDataSource>

+ (LoggingIntervalPickerDataSource *)sharedInstance;

@end
