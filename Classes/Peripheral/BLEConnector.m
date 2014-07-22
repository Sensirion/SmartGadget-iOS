//
//  BLEConnector.m
//  smartgadgetapp
//
//  Copyright (c) 2012 Sensirion AG. All rights reserved.
//

#import "BLEConnector.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "AlertViewController.h"
#import "BLEGadget.h"
#import "BLEUtil.h"
#import "Settings.h"

@interface BLEConnector()  <CBCentralManagerDelegate, GadgetConnectionCallbackDelegate> {
    CBCentralManager *_centralManager;
	
    NSMutableDictionary *_connectedGadgets;
    NSMutableDictionary *_foundGadgets;

    NSMutableArray *_delegates;

    NSTimer *_autoConnectScanTimer;
}
@end

@implementation BLEConnector

+ (BLEConnector *)sharedInstance {
    static BLEConnector *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BLEConnector alloc] init];
    });

    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        _connectedGadgets = [NSMutableDictionary new];
        _foundGadgets = [NSMutableDictionary new];
        _delegates = [NSMutableArray new];
    }

    return self;
}

- (void)addListener:(id<BLEConnectorDelegate>)listener {
    if ([_delegates containsObject:listener]) {
        NSLog(@"Delegate already registerd, ignoring");
    } else {
        [_delegates addObject:listener];
    }
}

- (void)removeListener:(id<BLEConnectorDelegate>)listener {
    [_delegates removeObject:listener];
}

- (void)startScanning {
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [_centralManager scanForPeripheralsWithServices:nil options:options];
}

- (void)stopScanning {

    if (_autoConnectScanTimer) {
        NSLog(@"Stopping auto connect timer");
        [_autoConnectScanTimer invalidate];
        _autoConnectScanTimer = nil;
    }

    [_centralManager stopScan];
}

- (void)onEnterBackground {
    for (BLEGadget *gadget in _connectedGadgets.allValues) {
        [gadget enteredBackground];
    }
}

- (void)onEnterForground {
    for (BLEGadget *gadget in _connectedGadgets.allValues) {
        [gadget enteredForeground];
    }
}

- (void)autoConnect {
    [self onCheckAutoConnect:nil];
}

- (void)onCheckAutoConnect:(NSTimer *)timer {
    NSLog(@"INFO: checking auto connect status");
    _autoConnectScanTimer = nil;

    BOOL finish = NO;

    if ([[Settings userDefaults] selectedGadgetUUID]) {
        //already have at least one gadget connected and selected
        finish = YES;
    } else if ([_foundGadgets count] > 0) {
        //sort list and connect to "strongest signal"
        [[[self foundHumiGadgets] objectAtIndex:0] tryConnect];
        finish = YES;
    }

    if (finish) {
        NSLog(@"Connected or connecting, will not scan");
        [_centralManager stopScan];
    } else {
        [self startScanning];
        _autoConnectScanTimer = [NSTimer timerWithTimeInterval:DEFAULT_AUTO_CONNECT_TIMER target:self selector:@selector(onCheckAutoConnect:) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:_autoConnectScanTimer forMode:NSDefaultRunLoopMode];
    }
}

//----------------------------------------------------------------------------------------------------
// GadgetConnectionCallbackDelegate implementation
//----------------------------------------------------------------------------------------------------

- (void)onGadgetConnectionDecayed:(BLEGadget *)gadget {
    if ([_foundGadgets objectForKey:gadget.UUID]) {
        [_foundGadgets removeObjectForKey:gadget.UUID];

        for (id<BLEConnectorDelegate> delegate in _delegates) {
            [delegate onGadgetListsUpdated];
        }
    }
}

- (void)connect:(CBPeripheral *)peripheral {
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey];
    [_centralManager connectPeripheral:peripheral options:options];
}

- (void)forceDisconnect:(CBPeripheral *)peripheral {
    [_centralManager cancelPeripheralConnection:peripheral];

    NSString *uuid = [[peripheral identifier] UUIDString];

    if ([_connectedGadgets objectForKey:uuid]) {
        [_connectedGadgets removeObjectForKey:uuid];

        for (id<BLEConnectorDelegate> delegate in _delegates) {
            [delegate onGadgetListsUpdated];
        }
    }
}

//----------------------------------------------------------------------------------------------------
// properties
//----------------------------------------------------------------------------------------------------

- (NSArray *)foundHumiGadgets {
    return [[_foundGadgets allValues] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)connectedGadgets {
    return [[_connectedGadgets allValues] sortedArrayUsingSelector:@selector(compare:)];
}

- (BLEGadget *)getConnectedGadget:(NSString *)gadgetUUID {
    return [_connectedGadgets objectForKey:gadgetUUID];
}

- (BLEGadget *)getConnectedGadgetWithSystemId:(uint64_t)identifier {

    for (BLEGadget *gadget in [_connectedGadgets allValues]) {
        if ([gadget identifier] == identifier) {
            return gadget;
        }
    }

    return nil;
}

//----------------------------------------------------------------------------------------------------
//
// CBCentralManagerDelegate protocol methods beneeth here
// Documented in CoreBluetooth documentation
//
//----------------------------------------------------------------------------------------------------

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSString *state;

    switch(central.state) {
        case CBCentralManagerStateUnknown:
            //nothing to do but wait for the next state.
            state = @"State unknown (CBCentralManagerStateUnknown)";
            break;
        case CBCentralManagerStateResetting:
            state = @"State resetting (CBCentralManagerStateResetting)";
            [self clearDevices];
            break;
        case CBCentralManagerStateUnsupported:
            state = @"State BLE unsupported (CBCentralManagerStateUnsupported)";
            [AlertViewController onBleConnectionStateChanged:UNSUPPORTED];
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"State unauthorized (CBCentralManagerStateUnauthorized)";
            [AlertViewController onBleConnectionStateChanged:UNAUTHORIZED];
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"State BLE powered off (CBCentralManagerStatePoweredOff)";
            [self clearDevices];
            [AlertViewController onBleConnectionStateChanged:POWER_OFF];
            break;
        case CBCentralManagerStatePoweredOn:
            state = @"State powered up and ready (CBCentralManagerStatePoweredOn)";
            [AlertViewController onBleConnectionStateChanged:POWER_ON];
            [_centralManager retrieveConnectedPeripheralsWithServices:[BLEGadget handledServiceIds]];
            break;
        default:
            //should never happen
            state = @"State unhandled!";
            NSLog(@"ERROR: unhandled CBCentralManager state: %d", central.state);
            break;
    }

    NSLog(@"Status of CoreBluetooth Central Manager changed %d (%@)", central.state, state);
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    NSLog(@"didRetrieveConnectedPeripherals");

    for (CBPeripheral *peripheral in peripherals) {
        [central connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"didDiscoverPeripheral");

    BLEGadget *gadget = [_foundGadgets objectForKey:[[peripheral identifier] UUIDString]];

    if (gadget) {
        //already found
        NSLog(@"Peripheral %@ has a new RSSI: %@", peripheral, RSSI);
        
    } else if ([BLEGadget isPartOf:peripheral advertisementData:advertisementData]) {
        gadget = [[BLEGadget alloc] initWithPeripheral:peripheral andManager:self];
        [_foundGadgets setValue:gadget forKey:gadget.UUID];
    } else {
        NSLog(@"Unknown peripheral: %@, is not compatible", peripheral.name);
        return;
    }

    [gadget setDisconnectedSignalStrength:RSSI];

    for (id<BLEConnectorDelegate> delegate in _delegates) {
        [delegate onGadgetListsUpdated];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    BLEGadget *gadget = [_foundGadgets objectForKey:[[peripheral identifier] UUIDString]];

    if (gadget && [gadget handleConnected:peripheral]) {
        [_foundGadgets removeObjectForKey:gadget.UUID];
        [_connectedGadgets setValue:gadget forKey:gadget.UUID];

        for (id<BLEConnectorDelegate> delegate in _delegates) {
            [delegate onGadgetListsUpdated];
        }
    } else {
        NSLog(@"Connected to an unknown gadget... ignoring");
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self stopScanning];

    NSLog(@"ERROR: Attempted connection to peripheral %@ failed: %@", [peripheral name], [error localizedDescription]);

    [_foundGadgets removeObjectForKey:[[peripheral identifier] UUIDString]];

    for (id<BLEConnectorDelegate> delegate in _delegates) {
        [delegate onGadgetListsUpdated];
    }

    [self startScanning];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnected from Peripheral with identifier: %@", [peripheral identifier]);

    [self stopScanning];

    NSString *peripheralUUID = [[peripheral identifier] UUIDString];

    BLEGadget *gadget = [_connectedGadgets objectForKey:peripheralUUID];
    [_connectedGadgets removeObjectForKey:peripheralUUID];

    if (gadget && [gadget handleDisconnected:peripheralUUID]) {

        for (id<BLEConnectorDelegate> delegate in _delegates) {
            [delegate onGadgetListsUpdated];
        }
    } else {
        NSLog(@"Disconnected from an unknown gadget... ignoring");
    }

    [self startScanning];
}

//----------------------------------------------------------------------------------------
// Util
//----------------------------------------------------------------------------------------

- (void)clearDevices {
    [_foundGadgets removeAllObjects];

    for (BLEGadget *gadget in [_connectedGadgets allValues]) {
        [gadget forceDisconnect];
    }

    [_connectedGadgets removeAllObjects];

    for (id<BLEConnectorDelegate> delegate in _delegates) {
        [delegate onGadgetListsUpdated];
    }
}

@end
