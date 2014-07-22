//
//  Settings.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "Settings.h"

#import "BLEConnector.h"
#import "BLEGadget.h"
#import "colors.h"
#import "GadgetDataRepository.h"

static NSString * const SETTING_TEMP_UNIT = @"setting_temp_unit";
static NSString * const SETTING_SEASON = @"setting_season";
static NSString * const HAS_LAUNCHED_ONCE = @"hasLaunchedOnce";

@interface Settings() {
    NSArray *_colorArray;
    NSMutableDictionary *_assignedColors;
    NSMutableDictionary *_colorForGadget;
    NSString *_selectedGadgetUUID;
    uint64_t _selectedLogIdentifier;

    NSDate *_lastDownloadFinished;

    enum comfort_zone_type _comfortZone;
    enum display_type _upperButtonDisplayes;
    enum display_type _lowerButtonDisplayes;
    enum temperature_unit_type _temperatureUnit;

    BOOL _hasLaunchedOnce;
}

@end

@implementation Settings

+ (Settings *)userDefaults {
    static Settings *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Settings alloc] init];
    });

    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {

        //initialize members
        _colorArray = [[NSArray alloc] initWithObjects:(UIColor *)
                      [UIColor RED],
                      [UIColor GREEN],
                      [UIColor BLUE],
                      [UIColor YELLOW],
                      [UIColor VIOLETT],
                      [UIColor LIGHT_BLUE],
                      [UIColor ORANGE],
                      [UIColor PURPLE], nil];
        
        _assignedColors = [NSMutableDictionary new];
        _colorForGadget = [NSMutableDictionary new];

        if ([[NSUserDefaults standardUserDefaults] integerForKey:SETTING_SEASON]) {
            _comfortZone = (enum comfort_zone_type)[[NSUserDefaults standardUserDefaults] integerForKey:SETTING_SEASON];
        } else {
            _comfortZone = SEASON_SUMMER;
        }

        if ([[NSUserDefaults standardUserDefaults] integerForKey:SETTING_TEMP_UNIT]) {
            _temperatureUnit = (enum temperature_unit_type)[[NSUserDefaults standardUserDefaults] integerForKey:SETTING_TEMP_UNIT];
        } else {
            _temperatureUnit = [self useMetric] ? UNIT_CELCIUS : UNIT_FARENHEIT;
        }

        _selectedGadgetUUID = nil;
        _selectedLogIdentifier = 0;
        _upperButtonDisplayes = DISPTYPE_TEMPERATURE;
        _lowerButtonDisplayes = DISPTYPE_HUMIDITY;

        _hasLaunchedOnce = [[NSUserDefaults standardUserDefaults] boolForKey:HAS_LAUNCHED_ONCE];
    }

    return self;
}

- (void)releaseColorForGadget:(NSString *)gadgetUUID {
    if ([_colorForGadget objectForKey:gadgetUUID]) {

        UIColor *color = [_colorForGadget objectForKey:gadgetUUID];

        for (NSNumber *key in [_assignedColors allKeys]) {
            if ([[_assignedColors objectForKey:key] isEqual:color]) {
                [_assignedColors removeObjectForKey:key];
                break;
            }
        }

        [_colorForGadget removeObjectForKey:gadgetUUID];
    }
}

- (UIColor *)getColorForGadget:(NSString *)gadgetUUID {
    if ([_colorForGadget objectForKey:gadgetUUID]) {
        return [_colorForGadget objectForKey:gadgetUUID];
    }

    UIColor *color = [self getNextColor];
    [_colorForGadget setObject:color forKey:gadgetUUID];

    return color;
}

- (UIColor *)getNextColor {
    for (int i=0; i < [_colorArray count]; ++i){

        if ([[_assignedColors allKeys] containsObject:[NSNumber numberWithInt:i]]) {
            continue;
        }

        [_assignedColors setObject:[_colorArray objectAtIndex:i] forKey:[NSNumber numberWithInt:i]];
        return [_colorArray objectAtIndex:i];
    }

    NSLog(@"WARNING: To many devices, will add random color");
    return [UIColor Random];
}

- (NSString *)getStoredDescriptionForGadget:(uint64_t)gadgetIdentifier {
    return [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"%llu", gadgetIdentifier]];
}

- (void)setStoredDescription:(NSString *)description forGadget:(uint64_t)gadgetIdentifier {
    NSString *trimmedString = description ? [description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] : nil;

    if (trimmedString && [trimmedString length] > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:trimmedString forKey:[NSString stringWithFormat:@"%llu", gadgetIdentifier]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%llu", gadgetIdentifier]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (NSString *)selectedGadgetUUID {
    if (_selectedGadgetUUID == nil && [[BLEConnector sharedInstance] connectedGadgets].count > 0) {
        _selectedGadgetUUID = [[[[BLEConnector sharedInstance] connectedGadgets] lastObject] UUID];
    }

    return _selectedGadgetUUID;
}

- (void)setSelectedGadgetUUID:(NSString *)selectedGadgetUUID {
    _selectedGadgetUUID = selectedGadgetUUID;
}

- (uint64_t)selectedLogIdentifier {
    if (_selectedLogIdentifier == 0) {

        if ([[[BLEConnector sharedInstance] connectedGadgets] count] > 0) {

            /* get selected gadget */
            BLEGadget *gadget = [[BLEConnector sharedInstance] getConnectedGadget:[Settings userDefaults].selectedGadgetUUID];

            /* if none is seleceted (this can happen only very shortly after connection), get first connected */
            if (!gadget) {
                gadget = (BLEGadget *)[[[BLEConnector sharedInstance] connectedGadgets] objectAtIndex:0];
            }

            if ([gadget identifier]) {
                _selectedLogIdentifier = [gadget identifier];
                return _selectedLogIdentifier;
            }
        }

        /* otherwise select some gadget where we have data */
        NSArray *records = [[GadgetDataRepository sharedInstance] getAllRecords];

        if ([records count]) {
            GadgetData *data = [records objectAtIndex:0];
            _selectedLogIdentifier = [data gadget_id].unsignedLongLongValue;
        }
    }

    return _selectedLogIdentifier;
}

- (void)setSelectedLogIdentifier:(uint64_t)logIdentifier {
    _selectedLogIdentifier = logIdentifier;
}

- (enum comfort_zone_type)comfortZone {
    return _comfortZone;
}

- (void)setComfortZone:(enum comfort_zone_type)comfortZone {
    _comfortZone = comfortZone;

    [[NSUserDefaults standardUserDefaults] setInteger:comfortZone forKey:SETTING_SEASON];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (enum display_type)upperMainButonDisplayes {
    return _upperButtonDisplayes;
}

- (void)setUpperMainButonDisplayes:(enum display_type)diplays {
    _upperButtonDisplayes = diplays;
}

- (enum display_type)lowerMainButonDisplayes {
    return _lowerButtonDisplayes;
}

- (void)setLowerMainButonDisplayes:(enum display_type)diplays {
    _lowerButtonDisplayes = diplays;
}

- (enum temperature_unit_type)tempUnitType {
    return _temperatureUnit;
}

- (void)setTempUnitType:(enum temperature_unit_type)unitType {
    _temperatureUnit = unitType;

    [[NSUserDefaults standardUserDefaults] setInteger:unitType forKey:SETTING_TEMP_UNIT];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isFirstTime {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HAS_LAUNCHED_ONCE];
    [[NSUserDefaults standardUserDefaults] synchronize];

    return _hasLaunchedOnce == NO;
}

- (BOOL)useMetric {
    NSLocale *locale = [NSLocale currentLocale];
    return [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
}

@end
