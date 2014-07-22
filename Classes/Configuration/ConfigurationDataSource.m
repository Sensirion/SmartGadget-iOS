//
//  ConfigurationDataSource.m
//  smartgadgetapp
//
//  Copyright (c) 2014 Sensirion AG. All rights reserved.
//

#import "ConfigurationDataSource.h"

#import "RHTPoint.h"
#import "Settings.h"
#import "strings.h"

@implementation ComfortZoneConfigurationDataSource

static NSArray *SUMMER_DEFINITION;
static NSArray *WINTER_DEFINITION;

+ (void)initialize {
    if (self == [ComfortZoneConfigurationDataSource self]) {
        SUMMER_DEFINITION = [NSArray arrayWithObjects:(RHTPoint*)
                             [[RHTPoint alloc] initWithTempInCelcius:22.5 andRelativeHumidity:79.5],
                             [[RHTPoint alloc] initWithTempInCelcius:26.0 andRelativeHumidity:57.3],
                             [[RHTPoint alloc] initWithTempInCelcius:27.0 andRelativeHumidity:19.8],
                             [[RHTPoint alloc] initWithTempInCelcius:23.5 andRelativeHumidity:24.4], nil];
        
        WINTER_DEFINITION = [NSArray arrayWithObjects:(RHTPoint*)
                             [[RHTPoint alloc] initWithTempInCelcius:19.5 andRelativeHumidity:86.5],
                             [[RHTPoint alloc] initWithTempInCelcius:23.5 andRelativeHumidity:58.3],
                             [[RHTPoint alloc] initWithTempInCelcius:24.5 andRelativeHumidity:23.0],
                             [[RHTPoint alloc] initWithTempInCelcius:20.5 andRelativeHumidity:29.3], nil];
    }
}

+ (ComfortZoneConfigurationDataSource *)sharedInstance {
    static ComfortZoneConfigurationDataSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [ComfortZoneConfigurationDataSource alloc];
    });
    return sharedInstance;
}

+ (NSString *)currentComfortZoneTitle {
    return [ComfortZoneConfigurationDataSource comfortZoneTypeToString:[Settings userDefaults].comfortZone];
}

+ (NSString *)comfortZoneTypeToString:(enum comfort_zone_type) comfort_zone {
    switch (comfort_zone) {
        case SEASON_SUMMER:
            return seasonSummer;
        case SEASON_WINTER:
            return seasonWinter;
        default:
            [NSException raise:@"Unknown comfort zone" format:@"zone: %u", comfort_zone];
    }

    return @"";
}

+ (NSArray *)comfortZonePoints {
    switch([Settings userDefaults].comfortZone) {
        case SEASON_SUMMER:
            return SUMMER_DEFINITION;
        case SEASON_WINTER:
            return WINTER_DEFINITION;
        default:
            [NSException raise:@"Unknown comfort zone" format:@"zone: %u", [Settings userDefaults].comfortZone];
    }
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return seasonTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return comfortZoneTitle;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return comfort_zone_type_count; //summer and winter
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    // Configure the cell...
    enum comfort_zone_type comfortZone = (enum comfort_zone_type)indexPath.row;
    
    NSString *season = [ComfortZoneConfigurationDataSource comfortZoneTypeToString:comfortZone];
    BOOL selected = (comfortZone == [Settings userDefaults].comfortZone);
    
    [[cell textLabel] setText:season];
    [cell setAccessoryType:(selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone)];
    
    return cell;
}

- (void)selectConfigurationAtRow:(NSUInteger)row {
    enum comfort_zone_type comfortZoneSelected = (enum comfort_zone_type) row;
    [Settings userDefaults].comfortZone = comfortZoneSelected;
}

@end

@implementation TemperatureConfigurationDataSource

+ (TemperatureConfigurationDataSource *)sharedInstance {
    static TemperatureConfigurationDataSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [TemperatureConfigurationDataSource alloc];
    });
    
    return sharedInstance;
}

+ (NSString *)currentTemperatureUnitString {
    return [self unitTypeToString:[Settings userDefaults].tempUnitType];
}

+ (NSString *)unitTypeToString:(enum temperature_unit_type)unit {
    return unit == UNIT_CELCIUS ? @"°C" : @"°F";
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return temperatureTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return temperatureUnitTitle;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return temperature_unit_type_count; //celcius and farenheit
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    // Configure the cell...
    enum temperature_unit_type unitType = (enum temperature_unit_type)indexPath.row;
    
    BOOL selected = (unitType == [Settings userDefaults].tempUnitType);
    
    [[cell textLabel] setText:[TemperatureConfigurationDataSource unitTypeToString:unitType]];
    [cell setAccessoryType:(selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone)];
    
    return cell;
}

- (void)selectConfigurationAtRow:(NSUInteger)row {
    enum temperature_unit_type unitSelected = (enum temperature_unit_type)row;
    [Settings userDefaults].tempUnitType = unitSelected;
}

@end

@implementation DisplayTypePickerDataSource

+ (DisplayTypePickerDataSource *)sharedInstance {
    static DisplayTypePickerDataSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [DisplayTypePickerDataSource alloc];
    });

    return sharedInstance;
}

- (NSInteger)numberOfValues {
    return display_type_count;
}

- (NSInteger)getDefaultValueRow {
    return DISPTYPE_HUMIDITY;
}

- (NSInteger)getValueForRow:(NSInteger)row {
    return row;
}

- (NSString *)getTitleForRow:(NSInteger)row {
    return [self getTitleForValue:row];
}

- (NSString *)getTitleForValue:(uint16_t)value {
    switch (value) {
        case 0:
            return temperatureTitle;
        case 1:
            return relativeHumidityTitle;
        case 2:
            return dewPointTitle;
    }

    return titleMissing;
}

@end

@implementation DisplayTypeWithUnitPickerDataSource

+ (DisplayTypeWithUnitPickerDataSource *)sharedInstance {
    static DisplayTypeWithUnitPickerDataSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [DisplayTypeWithUnitPickerDataSource alloc];
    });

    return sharedInstance;
}

- (NSInteger)numberOfValues {
    return display_type_count;
}

- (NSInteger)getDefaultValueRow {
    return DISPTYPE_HUMIDITY;
}

- (NSInteger)getValueForRow:(NSInteger)row {
    return row;
}

- (NSString *)getTitleForRow:(NSInteger)row {
    return [self getTitleForValue:row];
}

- (NSString *)getTitleForValue:(uint16_t)value {
    switch (value) {
        case 0:
            return [NSString stringWithFormat:@"%@ %@", temperatureTitle, [TemperatureConfigurationDataSource currentTemperatureUnitString]];
        case 1:
            return [NSString stringWithFormat:@"%@ %@", relativeHumidityTitle, relativeHumidityUnitString];
        case 2:
            return [NSString stringWithFormat:@"%@ %@", dewPointTitle, [TemperatureConfigurationDataSource currentTemperatureUnitString]];
    }

    return titleMissing;
}

@end

@implementation LoggingIntervalPickerDataSource

static const uint DEFAULT_ROW = 2; // corresponds to value "60 seconds"

+ (LoggingIntervalPickerDataSource *)sharedInstance {
    static LoggingIntervalPickerDataSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [LoggingIntervalPickerDataSource alloc];
    });

    return sharedInstance;
}

- (NSInteger)numberOfValues {
    NSInteger numRows = (sizeof LOGG_INTERVAL_VALUES) / (sizeof LOGG_INTERVAL_VALUES[0]);
    return numRows;
}

- (NSInteger)getDefaultValueRow {
    return DEFAULT_ROW;
}

- (NSInteger)getValueForRow:(NSInteger)row {
    return LOGG_INTERVAL_VALUES[row];
}

- (NSString *)getTitleForRow:(NSInteger)row {
    return [self getTitleForValue:LOGG_INTERVAL_VALUES[row]];
}

- (NSString *)getTitleForValue:(uint16_t)value {
    if (value == 1) {
        return [NSString stringWithFormat:@"1 %@", unitSecond];
    } else if (value < 60) {
        return [NSString stringWithFormat:@"%d %@", value, unitSeconds];
    }

    if (value == 60) {
        return [NSString stringWithFormat:@"1 %@", unitMinute];
    } else if (value < 60*60) {
        if (value % 60 == 0) {
            return [NSString stringWithFormat:@"%d %@", value/60, unitMinutes];
        }

        [NSException raise:@"Invalid value" format:@"Seconds: %d not even number of minutes", value];
    }

    if (value == 60*60) {
        return [NSString stringWithFormat:@"1 %@", unitHour];
    } else {
        if (value % (60*60) == 0) {
            return [NSString stringWithFormat:@"%d %@", value/(60*60), unitHours];
        }

        [NSException raise:@"Invalid value" format:@"Seconds: %d not even number of hours", value];
    }

    //to keep compiler happy
    return titleMissing;
}

@end

