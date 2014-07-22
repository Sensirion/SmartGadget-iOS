//
//  BLEGadget.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "BLEGadget.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "BLEUtil.h"
#import "DeviceInfoService.h"
#import "GadgetDataRepository.h"
#import "HumiGadgetService.h"
#import "SensorTagHumiService.h"
#import "Settings.h"

@interface BLEGadget() <CBPeripheralDelegate> {

    CBPeripheral *_peripheral;
    id<GadgetConnectionCallbackDelegate> _manager;
    
    BLEService *_humiService;
    DeviceInfoService *_infoService;
    BatteryService *_batteryService;
    LoggerService *_loggerService;
    GadgetSettingsService *_settingsService;
    
    NSMutableArray *_delegates;

    int32_t _disconnectedSingnalStrength;
    NSDate *_disconnectedLifeTime;

    NSString *_lastKnownDiscription;
}

@end

@implementation BLEGadget

+ (BOOL)isPartOf:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData {
    if (advertisementData) {
        NSArray *services = [BLEUtil getAdvertisedServices:advertisementData];
        if (services && [services containsObject:[HumiGadgetService serviceId]]) {
            return YES;
        }
    }

    if (peripheral) {
        return [HUMI_GADGET_NAME isEqualToString:[peripheral name]]
        || [SENSOR_TAG_SHORT_NAME isEqualToString:peripheral.name]
        || [SENSOR_TAG_NAME isEqualToString:peripheral.name];
    }

    return NO;
}

+ (NSArray *)handledServiceIds {
    return [NSArray arrayWithObjects:(CBUUID *)[HumiGadgetService serviceId], [SensorTagHumiService serviceId], nil];
}

+ (NSString *)discriptionFromId:(uint64_t)gadgetId {
    if (gadgetId) {
        NSString *gadgetDescription;
        if ([[Settings userDefaults] getStoredDescriptionForGadget:gadgetId]) {
            gadgetDescription = [[Settings userDefaults] getStoredDescriptionForGadget:gadgetId];
        } else {
            NSString *systemId = [NSString stringWithFormat:@"%qX", gadgetId];
            gadgetDescription = [systemId substringFromIndex:([systemId length] - 4)];
        }

        return gadgetDescription;
    }

    return nil;
}

- (id)initWithPeripheral:(CBPeripheral *)peripheral andManager:(id<GadgetConnectionCallbackDelegate>)manager {
    _delegates = [NSMutableArray new];
    _peripheral = peripheral;
    [_peripheral setDelegate:self];

    uint64_t gadgetId = [[GadgetDataRepository sharedInstance] getGadgetIdFor:[[_peripheral identifier] UUIDString]];

    if (gadgetId) {
        _lastKnownDiscription = [BLEGadget discriptionFromId:gadgetId];
    }

    _manager = manager;
    return self;
}

- (void)addListener:(id<GadgetNotificationDelegate>)delegate {
    [_delegates addObject:delegate];
}

- (void)removeListener:(id<GadgetNotificationDelegate>)delegate {
    [_delegates removeObject:delegate];
}

- (BOOL)hasListener:(id<GadgetNotificationDelegate>)delegate {
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
        
        //"decay" the connection strengt
        int decay = (int)(age * age);
        return [NSNumber numberWithInt:(_disconnectedSingnalStrength - decay)];
    }
}

- (void)setDisconnectedSignalStrength:(NSNumber *)RSSI {
    if ([RSSI intValue] < 0)
        _disconnectedSingnalStrength = [RSSI intValue];
    else
        _disconnectedSingnalStrength = - [RSSI intValue];

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
    if (_humiService && [_humiService isKindOfClass:[SensorTagHumiService class]]) {
        return [self peripheralName];
    }

    if (_infoService && [_infoService systemId]) {

        return [BLEGadget discriptionFromId:[_infoService systemId]];
    }

    if (_lastKnownDiscription) {
        return _lastKnownDiscription;
    }

    // else we do not yet know the description to show
    return @"";
}

- (void)setDescription:(NSString *)descriptionText {   
    if ([_infoService systemId]){
        [[Settings userDefaults] setStoredDescription:descriptionText forGadget:[_infoService systemId]];
    } else {
        NSLog(@"ERROR: Could not store description, do not yet know the unique system id of the peripheral");
        return;
    }
}

- (id<HumiServiceProtocol>)HumiService {
    return (id<HumiServiceProtocol>)_humiService;
}

- (BatteryService *)BatteryService {
    return _batteryService;
}

- (LoggerService *)LoggerService {
    return _loggerService;
}

- (GadgetSettingsService *)SettingsService {
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
        
        for (id<GadgetNotificationDelegate> delegate in _delegates) {
            [delegate gadgetDidDisconnect:self];
        }
        
        _infoService = nil;
        _batteryService = nil;
        _humiService = nil;
        _loggerService = nil;
        
        [[Settings userDefaults] releaseColorForGadget:self.UUID];

        _peripheral = nil;
        _manager = nil;
        
        return YES;
    }
    
    return NO;
}

- (void)enteredBackground {
    if (_humiService) {
        [_humiService enteredBackground];
    }
}

- (void)enteredForeground {
    if (_humiService) {
        [_humiService enteredForeground];
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
            
        } else if ([[HumiGadgetService serviceId] isEqual:serviceId]) {
            NSLog(@"HumiService initializing");
            _humiService = [[HumiGadgetService alloc] initService:service withParent:self];
            
        } else if ([[SensorTagHumiService serviceId] isEqual:serviceId]) {
            NSLog(@"SensorTagHumiService initializing");
            _humiService = [[SensorTagHumiService alloc] initService:service withParent:self];
            
        } else if ([[LoggerService serviceId] isEqual:serviceId]) {
            NSLog(@"LoggerService initializing");
            _loggerService = [[LoggerService alloc] initService:service withParent:self];

        } else if ([[GadgetSettingsService serviceId] isEqual:serviceId]) {
            NSLog(@"GadgetConfiguraionService initializing");
            _settingsService = [[GadgetSettingsService alloc] initService:service withParent:self];
            
        } else {
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
    } else if (_humiService && [_humiService checkService:service]) {
        handler = _humiService;
    } else if (_loggerService && [_loggerService checkService:service]) {
        handler = _loggerService;
    } else if (_settingsService && [_settingsService checkService:service]) {
        handler = _settingsService;
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
        return ;
    }
    
    BLEService *handler = nil;
    
    if (_infoService && [_infoService handleCharacteristicsValues:characteristic]) {
        handler = _infoService;
    } else if (_batteryService && [_batteryService handleCharacteristicsValues:characteristic]) {
        handler = _batteryService;
    } else if (_humiService && [_humiService handleCharacteristicsValues:characteristic]) {
        handler = _humiService;
    } else if (_loggerService && [_loggerService handleCharacteristicsValues:characteristic]) {
//        handler = _loggerService;
        return; //no need to inform UI
    } else if (_settingsService && [_settingsService handleCharacteristicsValues:characteristic]) {
//        handler = _settingsService;
        return; //no need to inform UI
    } else {
        NSLog(@"ERROR: No service handler found for new value on characteristic: %@", characteristic);
        return;
    }

    if (handler == _infoService) {
        [[GadgetDataRepository sharedInstance] updateLastKnownUUID:[[_peripheral identifier] UUIDString] forGadget:[_infoService systemId]];
    }


    for (id<GadgetNotificationDelegate> delegate in _delegates) {
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
}

- (void)onLogDataSynchronized {
    if (_settingsService) {
        [_settingsService.connectionSpeedSlowDown setBool:YES];
    }
}

@end
