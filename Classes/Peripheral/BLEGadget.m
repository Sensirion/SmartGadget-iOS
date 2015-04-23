//
//  BLEGadget.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "BLEGadget.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "BLEUtil.h"
#import "DeviceInfoService.h"
#import "GadgetDataRepository.h"
#import "Shtc1RhtService.h"
#import "SensorTagHumiService.h"
#import "Settings.h"
#import "SmartgadgetHumidityService.h"
#import "SmartgadgetTemperatureService.h"
#import "SmartgadgetHistoryService.h"

@interface BLEGadget () <CBPeripheralDelegate> {

    CBPeripheral *_peripheral;
    id <GadgetConnectionCallbackDelegate> _manager;

    DeviceInfoService *_infoService;
    BatteryService *_batteryService;

    BLEService *_rhtService;
    BLEService *_loggerService;

    Shtc1GadgetSettingsService *_settingsService;

    SmartgadgetHumidityService *_humidityService;
    SmartgadgetTemperatureService *_temperatureService;

    NSMutableSet *_delegates;

    int32_t _disconnectedSignalStrength;
    NSDate *_disconnectedLifeTime;

    NSString *_lastKnownDescription;
}

@end

@implementation BLEGadget

+ (BOOL)isPartOf:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData {
    if (advertisementData) {
        NSArray *services = [BLEUtil getAdvertisedServices:advertisementData];
        if (services && [services containsObject:[Shtc1RhtService serviceId]]) {
            return YES;
        }
    }

    if (peripheral) {
        return [SMARTGADGET_SHTC1_NAME isEqualToString:[peripheral name]]
                || [SMART_HUMIGADGET_NAME isEqualToString:peripheral.name]
                || [SMARTGADGET_SHT31_NAME isEqualToString:peripheral.name]
                || [SENSOR_TAG_SHORT_NAME isEqualToString:peripheral.name]
                || [SENSOR_TAG_NAME isEqualToString:peripheral.name];
    }
    return NO;
}

+ (NSArray *)handledServiceIds {
    return @[[Shtc1RhtService serviceId], [SensorTagHumiService serviceId], [SmartgadgetHumidityService serviceId], [SmartgadgetTemperatureService serviceId]];
}

+ (NSString *)descriptionFromId:(uint64_t)gadgetId {
    if (gadgetId) {
        if ([[Settings userDefaults] getStoredDescriptionForGadget:gadgetId]) {
            return [[Settings userDefaults] getStoredDescriptionForGadget:gadgetId];
        }
        NSString *systemId = [NSString stringWithFormat:@"%qX", gadgetId];
        return [systemId substringFromIndex:([systemId length] - 4)];
    }

    return nil;
}

- (id)initWithPeripheral:(CBPeripheral *)peripheral andManager:(id <GadgetConnectionCallbackDelegate>)manager {
    _delegates = [[NSMutableSet alloc] init];
    _peripheral = peripheral;
    [_peripheral setDelegate:self];

    uint64_t gadgetId = [[GadgetDataRepository sharedInstance] getGadgetIdFor:[[_peripheral identifier] UUIDString]];

    if (gadgetId) {
        _lastKnownDescription = [BLEGadget descriptionFromId:gadgetId];
    }

    _manager = manager;
    return self;
}

- (void)addListener:(id <GadgetNotificationDelegate>)delegate {
    [_delegates addObject:delegate];
}

- (void)removeListener:(id <GadgetNotificationDelegate>)delegate {
    [_delegates removeObject:delegate];
}

- (BOOL)hasListener:(id <GadgetNotificationDelegate>)delegate {
    return [_delegates containsObject:delegate];
}

- (void)tryConnect {
    [_manager connect:_peripheral];
}

- (void)forceDisconnect {
    NSLog(@"Manually disconnection from gadget");
    [_manager forceDisconnect:_peripheral];

    //trigger notification of delegates
    [self handleDisconnected:[self UUID]];
}

- (NSString *)UUID {
    return [[_peripheral identifier] UUIDString];
}

- (NSNumber *)RSSI {
    if ([self isConnected]) {
        return _peripheral.RSSI;
    } else {
        NSTimeInterval age = [[NSDate date] timeIntervalSinceDate:_disconnectedLifeTime];

        if (age > 10) {
            NSLog(@"connection has decayed for %@", self.UUID);
            [_manager onGadgetConnectionDecayed:self];
        }

        //"decay" the connection strength
        int decay = (int) (age * age);
        return @(_disconnectedSignalStrength - decay);
    }
}

- (void)setDisconnectedSignalStrength:(NSNumber *)RSSI {
    if ([RSSI intValue] < 0) {
        _disconnectedSignalStrength = [RSSI intValue];
    } else {
        _disconnectedSignalStrength = -[RSSI intValue];
    }
    _disconnectedLifeTime = [NSDate date];
}

- (NSComparisonResult)compare:(BLEGadget *)otherObject {
    //reversed compare "least negative" has best connection
    return [otherObject.RSSI compare:self.RSSI];
}

- (NSString *)peripheralName {
    if ([[_peripheral name] length]) {
        return [_peripheral name];
    }

    return @"Gadget";
}

- (BOOL)isConnected {
    return (_peripheral && _peripheral.state == CBPeripheralStateConnected);
}

- (uint64_t)identifier {
    if (_infoService) {
        return [_infoService systemId];
    }

    return 0;
}

- (NSString *)description {
    if (_lastKnownDescription) {
        return _lastKnownDescription;
    }

    if (_rhtService && [_rhtService isKindOfClass:[SensorTagHumiService class]]) {
        return [self peripheralName];
    }

    if (_infoService && [_infoService systemId]) {
        return [BLEGadget descriptionFromId:[_infoService systemId]];
    }

    // else we do not yet know the description to show
    return @"";
}

- (void)setDescription:(NSString *)descriptionText {
    if ([_infoService systemId]) {
        [[Settings userDefaults] setStoredDescription:descriptionText forGadget:[_infoService systemId]];
    } else {
        NSLog(@"ERROR: Could not store description, do not yet know the unique system id of the peripheral");
        return;
    }
}

- (id <HumiServiceProtocol>)HumiService {
    return (id <HumiServiceProtocol>) _rhtService;
}

- (id <LogServiceProtocol>)LoggerService {
    return (id <LogServiceProtocol>) _loggerService;
}

- (BatteryService *)BatteryService {
    return _batteryService;
}

- (Shtc1GadgetSettingsService *)SettingsService {
    return _settingsService;
}

- (BOOL)handleConnected:(CBPeripheral *)peripheral {
    if ([_peripheral isEqual:peripheral]) {

        NSLog(@"Starting discovering services");
        [_peripheral discoverServices:nil];

        return YES;
    }
    return NO;
}

- (BOOL)handleDisconnected:(NSString *)peripheralUUID {
    if ([[self UUID] isEqualToString:peripheralUUID]) {

        for (id <GadgetNotificationDelegate> delegate in _delegates) {
            [delegate gadgetDidDisconnect:self];
        }

        _infoService = nil;
        _batteryService = nil;
        _rhtService = nil;
        _loggerService = nil;

        [[Settings userDefaults] releaseColorForGadget:self.UUID];

        _peripheral = nil;
        _manager = nil;

        return YES;
    }

    return NO;
}

- (void)enteredBackground {
    if (_rhtService) {
        [_rhtService enteredBackground];
    }
}

- (void)enteredForeground {
    if (_rhtService) {
        [_rhtService enteredForeground];
    }
}

- (void)initializeServicesForPeripheral:(CBPeripheral *)peripheral {
    for (CBService *service in [peripheral services]) {

        CBUUID *serviceId = [service UUID];

        if ([[DeviceInfoService serviceId] isEqual:serviceId]) {
            NSLog(@"DeviceInfoService initializing");
            _infoService = [[DeviceInfoService alloc] initService:service withParent:self];

        } else if ([[BatteryService serviceId] isEqual:serviceId]) {
            NSLog(@"BatteryService initializing");
            _batteryService = [[BatteryService alloc] initService:service withParent:self];

        } else if ([[SensorTagHumiService serviceId] isEqual:serviceId]) {
            NSLog(@"SensorTagHumiService initializing");
            _rhtService = [[SensorTagHumiService alloc] initService:service withParent:self];

        } else if ([[Shtc1RhtService serviceId] isEqual:serviceId]) {
            NSLog(@"HumiService initializing");
            _rhtService = [[Shtc1RhtService alloc] initService:service withParent:self];

        } else if ([[Shtc1LoggerService serviceId] isEqual:serviceId]) {
            NSLog(@"Shtc1LoggerService initializing");
            _loggerService = [[Shtc1LoggerService alloc] initService:service withParent:self];

        } else if ([[Shtc1GadgetSettingsService serviceId] isEqual:serviceId]) {
            NSLog(@"GadgetConfiguraionService initializing");
            _settingsService = [[Shtc1GadgetSettingsService alloc] initService:service withParent:self];

        } else if ([[SmartgadgetHumidityService serviceId] isEqual:serviceId]) {
            NSLog(@"SmartgadgetHumidityService initializing");
            _humidityService = [[SmartgadgetHumidityService alloc] initService:service withParent:self];

        } else if ([[SmartgadgetTemperatureService serviceId] isEqual:serviceId]) {
            NSLog(@"SmartgadgetTemperatureService initializing");
            _temperatureService = [[SmartgadgetTemperatureService alloc] initService:service withParent:self];

        } else if ([[SmartgadgetHistoryService serviceId] isEqual:serviceId]) {
            NSLog(@"SmartgadgetHistoryService initializing");
            _loggerService = [[SmartgadgetHistoryService alloc] initService:service withParent:self];
        }

        else {
            NSLog(@"WARNING: No service handler found for service: %@, ignoring", service);
            continue;
        }

        [peripheral discoverCharacteristics:nil forService:service];
    }
}

//----------------------------------------------------------------------------------------------------
// CBPeripheralDelegate protocol methods
//----------------------------------------------------------------------------------------------------

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error != nil) {
        NSLog(@"Error %@", error);
        return;
    }

    [self initializeServicesForPeripheral:peripheral];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error; {
    if (error != nil) {
        NSLog(@"Error %@", error);
        return;
    }

    BLEService *handler = nil;

    if (_infoService && [_infoService checkService:service]) {
        handler = _infoService;
    } else if (_batteryService && [_batteryService checkService:service]) {
        handler = _batteryService;
    } else if (_rhtService && [_rhtService checkService:service]) {
        handler = _rhtService;
    } else if (_loggerService && [_loggerService checkService:service]) {
        handler = _loggerService;
    } else if (_settingsService && [_settingsService checkService:service]) {
        handler = _settingsService;
    } else if (_humidityService && [_humidityService checkService:service]) {
        handler = _humidityService;
    } else if (_temperatureService && [_temperatureService checkService:service]) {
        handler = _temperatureService;
    }

    if (handler) {
        [handler onNewCharacteristicsForService:service];
    } else {
        NSLog(@"ERROR: No service handler found for new characteristics on service: %@", service);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([error code] != 0) {
        NSLog(@"Error %@", error);
        return;
    }

    BLEService *handler = nil;

    if (_infoService && [_infoService handleCharacteristicsValues:characteristic]) {
        handler = _infoService;
    } else if (_batteryService && [_batteryService handleCharacteristicsValues:characteristic]) {
        handler = _batteryService;
    } else if (_rhtService && [_rhtService handleCharacteristicsValues:characteristic]) {
        handler = _rhtService;
    } else if (_loggerService && [_loggerService handleCharacteristicsValues:characteristic]) {
        return; //no need to inform UI
    } else if (_settingsService && [_settingsService handleCharacteristicsValues:characteristic]) {
        return; //no need to inform UI
    } else if (_humidityService && [_humidityService handleCharacteristicsValues:characteristic]) {
        handler = _humidityService;
    } else if (_temperatureService && [_temperatureService handleCharacteristicsValues:characteristic]) {
        handler = _temperatureService;
    } else {
        NSLog(@"ERROR: No service handler found for new value on characteristic: %@", characteristic);
        return;
    }

    if (handler == _infoService) {
        [[GadgetDataRepository sharedInstance] updateLastKnownUUID:[[_peripheral identifier] UUIDString] forGadget:[_infoService systemId]];
    }

    for (id <GadgetNotificationDelegate> delegate in _delegates) {
        if (handler == _infoService) {
            [delegate descriptionUpdated:self];
        } else {
            [delegate gadgetHasNewValues:self forService:handler];
        }
    }
}

//----------------------------------------------------------------------------------------------------
// Child services convenience methods
//----------------------------------------------------------------------------------------------------

- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"BLE: reading value of: %s/%s", [BLEUtil CBUUIDToString:[[characteristic service] UUID]], [BLEUtil CBUUIDToString:[characteristic UUID]]);

    [_peripheral readValueForCharacteristic:characteristic];
}

- (void)setNotifyValue:(BOOL)notify forCharacteristic:(CBCharacteristic *)characteristic {
    [_peripheral setNotifyValue:notify forCharacteristic:characteristic];
}

- (void)writeValue:(NSData *)value forCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"BLE: Writing peripheral value...");
    [_peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"ERROR: Result of writing to characteristic: %@ of service: %@ with error: %@", characteristic.UUID, characteristic.service.UUID, error);
    }

    if ([self LoggerService]) {
        [[self LoggerService] onCharacteristicWrite:characteristic];
    }
}

- (void)onLogDataSynchronized {
    if (_settingsService) {
        [_settingsService.connectionSpeedSlowDown setBool:YES];
    }
}

- (SmartgadgetHumidityService *)HumidityService {
    return _humidityService;
}

- (SmartgadgetTemperatureService *)TemperatureService {
    return _temperatureService;
}

@end
