//
//  LoggerService.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "LoggerService.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>

#import "AlertViewController.h"
#import "BLEGadget.h"
#import "BLEServiceProperty.h"
#import "GadgetDataRepository.h"
#import "HumiGadgetService.h"
#import "Settings.h"

static NSString * const RHTLOGGER_SERVICE_UUID_STRING                     = @"FA20";

static NSString * const RHTLOGGER_START_STOP_UUID_CHARACTERISTIC_STRING   = @"FA21";
static NSString * const RHTLOGGER_INTERVAL_UUID_CHARACTERISTIC_STRING     = @"FA22";
static NSString * const RHTLOGGER_GETPOINTER_UUID_CHARACTERISTIC_STRING   = @"FA23";
static NSString * const RHTLOGGER_STARTPOINTER_UUID_CHARACTERISTIC_STRING = @"FA24";
static NSString * const RHTLOGGER_ENDPOINTER_UUID_CHARACTERISTIC_STRING   = @"FA25";
static NSString * const RHTLOGGER_LOGGERDATA_UUID_CHARACTERISTIC_STRING   = @"FA26";
static NSString * const RHTLOGGER_USERDATA_UUID_CHARACTERISTIC_STRING     = @"FA27";

/* num bytes of one logged datapoint downloaded from gadget */
static uint DATA_POINT_SIZE = 4;

/* Maximal number of points logged in memory of gadget */
static uint MAX_LOGGED_DATA_POINTS = 16384;

/* interval of logger in seconds */
static uint GADGET_LOGGER_INTERVAL_S = 30;

@interface LoggerService() {

    CBCharacteristic *_loggerDataCharacteristic;
    BLEServiceProperty *_loggerEnabledProperty;
    BLEServiceProperty *_loggingIntervalProperty;
    BLEServiceProperty *_currentPointerProperty;
    BLEServiceProperty *_startPointerProperty;
    BLEServiceProperty *_endPointerProperty;
    BLEServiceProperty *_loggerStartDateProperty;

    id<LogDataNotificationProtocol> _dataDownloadCallBack;

    uint32_t _progressPointer;
    double _lastProgressReportTime;

    BOOL _isSynching;
}

@end

@implementation LoggerService

+ (CBUUID *)serviceId {
    return [CBUUID UUIDWithString:RHTLOGGER_SERVICE_UUID_STRING];
}

- (void)updateCurrentPointerProperty {
    if (_isSynching) {
        NSLog(@"INFO: Can not update property while synchronizing..");
        return;
    }

    if (_currentPointerProperty) {

        if ([_currentPointerProperty hasValue]){
            NSLog(@"Current pointer property is: %u", [_currentPointerProperty getValue]);
        }

        [_currentPointerProperty updateEventualy];
    }
}

- (void)synchronizeDataFrom:(uint32_t)startPointer to:(uint32_t)endPointer {

    _lastProgressReportTime = 0;
    _progressPointer = endPointer;
    [_endPointerProperty setValue:_progressPointer];
    [_startPointerProperty setValue:startPointer];

    NSLog(@"INFO: Setting last synch point to: %u starting synch from: %u", _progressPointer, startPointer);
    [[GadgetDataRepository sharedInstance] setLastSynchPoint:startPointer forGadgetWithId:[_parent identifier]];

    [_parent readValueForCharacteristic:_loggerDataCharacteristic];
}

- (BOOL)trySynchronizeData {

    if (_isSynching || [[Settings userDefaults] currentlyIsDownloading]) {
        NSLog(@"Can not synchronize - already synchronizing...");
        return NO;
    }

    if (_currentPointerProperty && [_currentPointerProperty hasValue]) {
        NSLog(@"Current pointer property is: %u", [_currentPointerProperty getValue] );
    } else {
        NSLog(@"WARNING: current pointer has no value");
        return NO;
    }

    if (_startPointerProperty && [_startPointerProperty hasValue]) {
        NSLog(@"Start pointer property is: %u", [_startPointerProperty getValue] );
    } else {
        NSLog(@"WARNING: start pointer has no value");
        return NO;
    }

    if (_endPointerProperty && [_endPointerProperty hasValue]) {
        NSLog(@"End pointer property is: %u", [_endPointerProperty getValue] );
    } else {
        NSLog(@"WARNING: end pointer has no value");
        return NO;
    }

    if (_loggingIntervalProperty && [_loggingIntervalProperty hasValue]) {
        NSLog(@"Logging interval property is: %u", [_loggingIntervalProperty getShort] );
    } else {
        NSLog(@"WARNING: logging interval has no value");
        return NO;
    }

    if (_loggerStartDateProperty &&  [_loggerStartDateProperty hasValue]) {
        NSLog(@"Logging start date property is: %u", [_loggerStartDateProperty getValue] );
    } else {
        NSLog(@"WARNING: logging start date has no value");
        return NO;
    }

    uint32_t currentPointer = [_currentPointerProperty getValue];
    uint32_t firstPointer = currentPointer > MAX_LOGGED_DATA_POINTS ? currentPointer - MAX_LOGGED_DATA_POINTS : 1;
    uint32_t lastSynchPoint = (int)[[GadgetDataRepository sharedInstance] getLastSynchPointForGadgetWithId:[_parent identifier]];

    firstPointer = firstPointer < lastSynchPoint ? lastSynchPoint : firstPointer;

    /**
     * trying to download data shortly after logger service was switched on and
     * thus maybe current pointer is not yet updated...
     */
    NSDate *loggingStartDate = [NSDate dateWithTimeIntervalSince1970:[_loggerStartDateProperty getValue]];

    if ([loggingStartDate compare:[[NSDate date] dateByAddingTimeInterval:(-1.5 * GADGET_LOGGER_INTERVAL_S)]] != NSOrderedAscending) {
        [AlertViewController showToastWithText:loggerStartedRecently];
        return NO;
    }

    if (firstPointer >= currentPointer) {
        [AlertViewController showToastWithText:noDataAvailableSinceLastDownload];
        return NO;

    } else {
        [Settings userDefaults].currentlyIsDownloading = [_parent identifier];
        _isSynching = YES;

        /* inform user that this will take some time */
        int NR_POINTS_TO_REPORT = 100;
        uint32_t diffrence = (currentPointer - firstPointer);
        if (diffrence > NR_POINTS_TO_REPORT) {
            [AlertViewController showToastWithText:[NSString stringWithFormat:goingToDownloadMany, diffrence]];
        }

        [self synchronizeDataFrom:firstPointer to:currentPointer];

        return YES;
    }
}

- (void)notifyOnSynch:(id<LogDataNotificationProtocol>)callback {
    [self updateCurrentPointerProperty];
    _dataDownloadCallBack = callback;
}

//----------------------------------------------------------------------------------------------------
// Properties
//----------------------------------------------------------------------------------------------------

- (BOOL)enabledHasValue {
    return [_loggerEnabledProperty hasValue];
}

- (BOOL)enabled {
    return _loggerEnabledProperty.getExtraShort == (uint8_t)YES;
}

- (void)setEnabled:(BOOL)enabled {

    NSLog(@"Set enabled called with value: %d...", enabled);

    if ([self enabled] == enabled) {
        NSLog(@"Requested logging state is already active on gadget, value is: %d...", [self enabled]);
        return;
    }

    if (enabled) {
        NSDate *now = [NSDate date];
        // reset current pointer and _progressPointer;
        [self updateCurrentPointerProperty];
        _progressPointer = 1;
        [[GadgetDataRepository sharedInstance] setLastSynchPoint:_progressPointer forGadgetWithId:[_parent identifier]];

        // set interval to proper value...
        [_loggerStartDateProperty setValue:(uint32_t)[now timeIntervalSince1970]];
        [_loggerEnabledProperty setExtraShort:(uint8_t)YES];
    } else {
        [_loggerEnabledProperty setExtraShort:(uint8_t)NO];
    }
}

- (id<MutableUInt16Property>)interval {
    return _loggingIntervalProperty;
}

- (NSUInteger)savedDataPoints {
    return [[GadgetDataRepository sharedInstance] savedMeasurmentsCountForGadgetWithId:[_parent identifier]];
}

- (BOOL)isSynchronizing {
    return _isSynching;
}

//--------------------------------------------------------------------------------
// BLEService implementation
//--------------------------------------------------------------------------------

- (void)enteredBackground {
    //do nothing
}

- (void)enteredForeground {
    //do nothing
}

- (void)onNewCharacteristicsForService:(CBService *)service {
    if ([self checkService:service]) {
        for (CBCharacteristic *characteristic in [service characteristics]) {
            if ([[CBUUID UUIDWithString:RHTLOGGER_START_STOP_UUID_CHARACTERISTIC_STRING] isEqual:[characteristic UUID]]) {
                _loggerEnabledProperty = [[BLEServiceProperty alloc] init:characteristic withParent:_parent];
                NSLog(@"Discovered Logger enabling" );
            } else if ([[CBUUID UUIDWithString:RHTLOGGER_INTERVAL_UUID_CHARACTERISTIC_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered Logger interval characteristic");
                _loggingIntervalProperty = [[BLEServiceProperty alloc] init:characteristic withParent:_parent];
            } else if ([[CBUUID UUIDWithString:RHTLOGGER_GETPOINTER_UUID_CHARACTERISTIC_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered Logged Data Current Pointer characteristic");
                _currentPointerProperty = [[BLEServiceProperty alloc] init:characteristic withParent:_parent];
            } else if ([[CBUUID UUIDWithString:RHTLOGGER_STARTPOINTER_UUID_CHARACTERISTIC_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered Logged Data Start Pointer characteristic");
                _startPointerProperty = [[BLEServiceProperty alloc] init:characteristic withParent:_parent];
            } else if ([[CBUUID UUIDWithString:RHTLOGGER_ENDPOINTER_UUID_CHARACTERISTIC_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered Logged Data End Pointer characteristic");
                _endPointerProperty = [[BLEServiceProperty alloc] init:characteristic withParent:_parent];
            } else if ([[CBUUID UUIDWithString:RHTLOGGER_LOGGERDATA_UUID_CHARACTERISTIC_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered Logger Data characteristic");
                _loggerDataCharacteristic = characteristic;
            } else if ([[CBUUID UUIDWithString:RHTLOGGER_USERDATA_UUID_CHARACTERISTIC_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered Logger user data characteristic");
                _loggerStartDateProperty = [[BLEServiceProperty alloc] init:characteristic withParent:_parent];
            } else {
                NSLog(@"Discovered unknown characteristic: %@ for logger service", [characteristic UUID]);
                continue;
            }
        }
    } else {
        NSLog(@"Discovered characteristics for unhandled service: %@", service);
    }
}

- (BOOL)handleCharacteristicsValues:(CBCharacteristic *)characteristic {
    BOOL handled = NO;

    if ([_loggerEnabledProperty handleValueUpdated:characteristic]) {
        handled = YES;
    } else if ([_loggingIntervalProperty handleValueUpdated:characteristic]) {
        handled = YES;
    } else if ([_currentPointerProperty handleValueUpdated:characteristic]) {
        handled = YES;
    } else if ([_startPointerProperty handleValueUpdated:characteristic]) {
        handled = YES;
    } else if ([_endPointerProperty handleValueUpdated:characteristic]) {
        handled = YES;
    } else if ([_loggerDataCharacteristic isEqual:characteristic]) {

        if ([characteristic.value length] > 0) {
            //start to read next "block"
            [_parent readValueForCharacteristic:_loggerDataCharacteristic];

            //take care of the data
            [self onLoggerDataRetreived:[characteristic value]];
        } else {
            [Settings userDefaults].lastDownloadFinished = [NSDate date];
            [Settings userDefaults].currentlyIsDownloading = 0;

            [self onAllDataReceived];
        }

        handled = YES;
    } else if ([_loggerStartDateProperty handleValueUpdated:characteristic]) {
        handled = YES;
    }

    return handled;
}

- (void)onLoggerDataRetreived:(NSData *)loggerData {

    //convert to measurmentDataPionts
    for (int i=0; i<loggerData.length; i+=DATA_POINT_SIZE) {

        NSData *chunk = [NSData dataWithBytesNoCopy:(char *)[loggerData bytes] + i length:DATA_POINT_SIZE freeWhenDone:NO];

        CGFloat temp = [HumiGadgetService rawDataPointToTemperature:chunk];
        CGFloat humidity = [HumiGadgetService rawDataPointToHumidity:chunk];

        uint32_t pointer = (_progressPointer - i/DATA_POINT_SIZE);

        NSDate *date = [self getDateOfPointer:pointer];
        if ([date compare:[NSDate date]] != NSOrderedAscending) {
            NSLog(@"WARNING: Throwing away a future timestamp for logged datapoint...");
        }

        [[GadgetDataRepository sharedInstance] addDataPoint:date withTemp:temp andHumidity:humidity toGadgetWithId:[_parent identifier]];
    }

    _progressPointer -= [loggerData length] / DATA_POINT_SIZE;

    if (_dataDownloadCallBack) {

        double currentTime = CACurrentMediaTime();

        if (currentTime - _lastProgressReportTime > SHOW_PROGRESS_MIN_TIME) {
            _lastProgressReportTime = currentTime;
            uint32_t downloaded = [_currentPointerProperty getValue] - _progressPointer;
            CGFloat progress = ((CGFloat) downloaded) / ([_endPointerProperty getValue] - [_startPointerProperty getValue]);

            [_dataDownloadCallBack onLogDataSynchProgress:progress];
        }
    }
}

- (void)onAllDataReceived {
    _isSynching = NO;
    [self updateCurrentPointerProperty];
    NSLog(@"INFO: All data received!");
    //updating last sync point...
    [[GadgetDataRepository sharedInstance] setLastSynchPoint:[_currentPointerProperty getValue] forGadgetWithId:[_parent identifier]];
    [Settings userDefaults].currentlyIsDownloading = 0;

    if (_dataDownloadCallBack) {
        [_dataDownloadCallBack onLogDataSynchFinished];
    } else {
        NSLog(@"No callback to report to...");
    }
}

- (NSDate *)getDateOfPointer:(uint32_t)pointer {   
    uint32_t intervalInSeconds = [_loggingIntervalProperty getValue];
    NSTimeInterval seconds = intervalInSeconds * pointer;
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:[_loggerStartDateProperty getValue]];

    return [NSDate dateWithTimeInterval:seconds sinceDate:startDate];
}

@end
