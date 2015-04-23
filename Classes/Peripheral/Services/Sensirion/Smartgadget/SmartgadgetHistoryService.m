//
//  SmartgadgetHistoryService.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "SmartgadgetHistoryService.h"
#import "BLEServiceProperty.h"
#import "Settings.h"
#import "BLEGadget.h"
#import "GadgetDataRepository.h"
#import "SmartgadgetHumidityService.h"
#import "SmartgadgetTemperatureService.h"
#import "AlertViewController.h"

static NSString *const HISTORY_SERVICE_UUID_STRING = @"0000f234-b38d-4985-720e-0f993a68ee41";

static NSString *const HISTORY_SERVICE_SYNC_TIME_UUID_STRING = @"0000f235-b38d-4985-720e-0f993a68ee41";
static NSString *const HISTORY_SERVICE_OLDEST_SAMPLE_MS_UUID_STRING = @"0000f236-b38d-4985-720e-0f993a68ee41";
static NSString *const HISTORY_SERVICE_NEWEST_SAMPLE_TIME_MS_UUID_STRING = @"0000f237-b38d-4985-720e-0f993a68ee41";
static NSString *const HISTORY_SERVICE_START_DOWNLOAD_UUID_STRING = @"0000f238-b38d-4985-720e-0f993a68ee41";
static NSString *const HISTORY_SERVICE_LOGGER_INTERVAL_MS_UUID_STRING = @"0000f239-b38d-4985-720e-0f993a68ee41";

@interface SmartgadgetHistoryService () {
    BOOL _timeIsSynchronized;

    CBCharacteristic *_syncDataCharacteristic;
    BLEServiceProperty *_oldestSampleMsProperty;
    BLEServiceProperty *_newestSampleMsProperty;
    BLEServiceProperty *_startLoggerCharacteristic;
    BLEServiceProperty *_loggerIntervalMsProperty;

    id <LogDataNotificationProtocol> _logDataNotificationCallback;

    uint32_t _progressPointer;
    uint32_t _numberElementsToDownload;

    double _lastProgressReportTime;

    BOOL _isSynchronizing;

    NSMutableDictionary *_storedData;
}

@end

@implementation SmartgadgetHistoryService

+ (CBUUID *)serviceId {
    return [CBUUID UUIDWithString:HISTORY_SERVICE_UUID_STRING];
}

- (uint64_t)getOldestTimestampToDownload {
    return [_oldestSampleMsProperty getLongValue];
}

- (uint64_t)getNewestTimestampToDownload {
    return [_newestSampleMsProperty getLongValue];
}

- (BOOL)trySynchronizeData {
    if (_isSynchronizing) {
        [_startLoggerCharacteristic updateEventually];
    }

    if (_oldestSampleMsProperty && [_oldestSampleMsProperty hasValue] && [_oldestSampleMsProperty getLongValue] > 0) {
        if ([_oldestSampleMsProperty getLongValue] > 0) {
            NSLog(@"Oldest timestamp is: %qu", [self getOldestTimestampToDownload]);
        } else {
            NSLog(@"Device is not synced yet.");
            [self syncTime];
            return NO;
        }
    } else {
        NSLog(@"WARNING: Oldest timestamp has no value.");
        [_oldestSampleMsProperty updateEventually];
        return NO;
    }

    if (_newestSampleMsProperty && [_newestSampleMsProperty hasValue] && [_newestSampleMsProperty getLongValue] > 0) {
        if ([_newestSampleMsProperty getLongValue] > 0) {
            NSLog(@"Newest timestamp is: %qu", [self getNewestTimestampToDownload]);
        } else {
            NSLog(@"Device is not synced yet.");
            [self syncTime];
            return NO;
        }
    } else {
        NSLog(@"WARNING: Newest timestamp has no value.");
        [_newestSampleMsProperty updateEventually];
        return NO;
    }

    if (_loggerIntervalMsProperty && [_loggerIntervalMsProperty hasValue] && [_loggerIntervalMsProperty getIntValue] > 0) {
        NSLog(@"Logger interval is: %d ms", [_loggerIntervalMsProperty getIntValue]);
    } else {
        [_loggerIntervalMsProperty updateEventually];
        NSLog(@"WARNING: Device has no interval.");
        return NO;
    }
    _numberElementsToDownload = (uint32_t) (((_newestSampleMsProperty.getLongValue - _oldestSampleMsProperty.getLongValue) / _loggerIntervalMsProperty.getIntValue));
    _storedData = [[NSMutableDictionary alloc] init];
    [self enableDataDownload];

    return YES;
}

- (void)enableDataDownload {
    uint8_t value = 1;
    [_startLoggerCharacteristic setExtraShort:value];
}

- (void)notifyOnSync:(id <LogDataNotificationProtocol>)callback {
    _logDataNotificationCallback = callback;
}

- (void)onCharacteristicWrite:(CBCharacteristic *)characteristic {
    if ([_startLoggerCharacteristic handleValueUpdated:characteristic]) {
        NSLog(@"Download start.");
        _isSynchronizing = YES;
        [Settings userDefaults].currentlyIsDownloading = [_parent identifier];
        /* inform user that this will take some time */
        uint32_t difference = (_numberElementsToDownload);
        if (difference > NR_POINTS_TO_REPORT) {
            [AlertViewController showToastWithText:[NSString stringWithFormat:goingToDownloadMany, difference]];
        }
    } else if ([_loggerIntervalMsProperty handleValueUpdated:characteristic]) {
        [_loggerIntervalMsProperty update];
    }
}

- (void)syncTime {
    uint64_t timestamp = (uint64_t) ([[NSDate date] timeIntervalSince1970] * 1000);
    NSData *rawTimestamp = [[NSData alloc] initWithBytes:&timestamp length:8];
    [_parent writeValue:rawTimestamp forCharacteristic:_syncDataCharacteristic];
    [_oldestSampleMsProperty update];
    [_newestSampleMsProperty update];
}

- (void)setInterval:(uint32_t)intervalInMilliseconds {
    [_loggerIntervalMsProperty setIntValue:intervalInMilliseconds];
}

- (BOOL)loggingStateCanBeModified {
    return NO; //In this service logging is always enabled.
}

- (BOOL)loggingIsEnabledHasValue {
    return YES;
}

- (BOOL)loggingIsEnabled {
    return YES; //Logging is always enabled
}

- (void)setLoggingIsEnabled:(BOOL)loggingIsEnabled {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"In the service history with the UUID %@ logging cannot be enabled.", [[self class] serviceId]]
                                 userInfo:nil];
}

- (NSUInteger)getIntervalMs {
    return [_loggerIntervalMsProperty getIntValue];
}

- (NSUInteger)savedDataPoints {
    return [[GadgetDataRepository sharedInstance] savedMeasurementsCountForGadgetWithId:[_parent identifier]];
}

- (BOOL)isSynchronizing {
    return _isSynchronizing;
}

//--------------------------------------------------------------------------------
// BLEService implementation
//--------------------------------------------------------------------------------

- (void)enteredBackground {
}

- (void)enteredForeground {
}

- (void)onNewCharacteristicsForService:(CBService *)service {
    if ([self checkService:service]) {
        for (CBCharacteristic *characteristic in [service characteristics]) {
            if ([[CBUUID UUIDWithString:HISTORY_SERVICE_SYNC_TIME_UUID_STRING] isEqual:[characteristic UUID]]) {
                _syncDataCharacteristic = characteristic;
                [self syncTime];
                NSLog(@"Discovered synching characteristic.");
            } else if ([[CBUUID UUIDWithString:HISTORY_SERVICE_OLDEST_SAMPLE_MS_UUID_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered oldest sample characteristic");
                _oldestSampleMsProperty = [[BLEServiceProperty alloc] init:characteristic withParent:_parent];
                [_oldestSampleMsProperty updateEventually];
            } else if ([[CBUUID UUIDWithString:HISTORY_SERVICE_NEWEST_SAMPLE_TIME_MS_UUID_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered newest sample characteristic");
                _newestSampleMsProperty = [[BLEServiceProperty alloc] init:characteristic withParent:_parent];
                [_newestSampleMsProperty updateEventually];
            } else if ([[CBUUID UUIDWithString:HISTORY_SERVICE_START_DOWNLOAD_UUID_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered logger enabler characteristic");
                _startLoggerCharacteristic = [[BLEServiceProperty alloc] init:characteristic withParent:_parent];
            } else if ([[CBUUID UUIDWithString:HISTORY_SERVICE_LOGGER_INTERVAL_MS_UUID_STRING] isEqual:[characteristic UUID]]) {
                NSLog(@"Discovered logger interval characteristic");
                _loggerIntervalMsProperty = [[BLEServiceProperty alloc] init:characteristic withParent:_parent];
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
    if ([_syncDataCharacteristic isEqual:characteristic]) {
        _timeIsSynchronized = YES;
        return YES;
    } else if ([_oldestSampleMsProperty handleValueUpdated:characteristic]) {
        if ([_oldestSampleMsProperty getLongValue]) {
            [_logDataNotificationCallback onLogDataInfoSyncFinished];
        }
        return YES;
    } else if ([_newestSampleMsProperty handleValueUpdated:characteristic]) {
        if ([_newestSampleMsProperty getLongValue]) {
            [_logDataNotificationCallback onLogDataInfoSyncFinished];
        }
        return YES;
    } else if ([_loggerIntervalMsProperty handleValueUpdated:characteristic]) {
        [self syncTime];
        return YES;
    } else if ([_startLoggerCharacteristic handleValueUpdated:characteristic]) {
        uint8_t isLoggingEnabled = NO;
        [[characteristic value] getBytes:&isLoggingEnabled length:sizeof(isLoggingEnabled)];
        if (isLoggingEnabled == 0){
            [Settings userDefaults].currentlyIsDownloading = 0;
            if (_isSynchronizing) {
                [self onAllDataReceived];
            }
        }
        NSLog(@"Data download %@.", (isLoggingEnabled == 0) ? @"STARTED" : @"FINISHED.");
        return YES;
    }
    return NO;
}

- (void)onAllDataReceived {
    _isSynchronizing = NO;
    NSLog(@"INFO: All data received!");
    //updating last sync point...
    [Settings userDefaults].currentlyIsDownloading = 0;

    if (_logDataNotificationCallback) {
        [_logDataNotificationCallback onLogDataSyncFinished];
    } else {
        NSLog(@"No callback to report to...");
    }
}

//--------------------------------------------------------------------------------
// RHT Services implementation
//--------------------------------------------------------------------------------

- (void)onNewHumidityData:(CGFloat)humidity andSequenceNumber:(uint32_t)sequenceNumber {
    if (_storedData[@(sequenceNumber)]) {
        CGFloat temperature = [_storedData[@(sequenceNumber)] floatValue];
        [_storedData removeObjectForKey:@(sequenceNumber)];
        [self notifyHistoryRHTData:humidity andTemperature:temperature andSequenceNumber:sequenceNumber];
    } else {
        _storedData[@(sequenceNumber)] = @(humidity);
    }
}

- (void)onNewTemperatureData:(CGFloat)temperature andSequenceNumber:(uint32_t)sequenceNumber {
    if (_storedData[@(sequenceNumber)]) {
        CGFloat humidity = [_storedData[@(sequenceNumber)] floatValue];
        [_storedData removeObjectForKey:@(sequenceNumber)];
        [self notifyHistoryRHTData:humidity andTemperature:temperature andSequenceNumber:sequenceNumber];
    } else {
        _storedData[@(sequenceNumber)] = @(temperature);
    }
}

- (void)notifyHistoryRHTData:(CGFloat)humidity andTemperature:(CGFloat)temperature andSequenceNumber:(uint32_t)sequenceNumber {
    uint64_t timestamp = _newestSampleMsProperty.getLongValue - sequenceNumber * _loggerIntervalMsProperty.getIntValue;
    uint32_t epochTime = (uint32_t) (timestamp / 1000);
    NSDate *epochDate = [NSDate dateWithTimeIntervalSince1970:epochTime];
    [[GadgetDataRepository sharedInstance] addDataPoint:epochDate withTemp:temperature andHumidity:humidity toGadgetWithId:[_parent identifier]];
    if (_logDataNotificationCallback) {
        double currentTime = CACurrentMediaTime();
        CGFloat progress = ((CGFloat) sequenceNumber) / (CGFloat) _numberElementsToDownload;
        if (currentTime - _lastProgressReportTime > SHOW_PROGRESS_MIN_TIME_SECONDS) {
            _lastProgressReportTime = currentTime;
            NSLog(@"Download callback %@ and progress %f.", _logDataNotificationCallback, progress);
            [_logDataNotificationCallback onLogDataSyncProgress:progress];
        }
        if (progress == 1) {
            [self onAllDataReceived];
        }
    }
}
@end