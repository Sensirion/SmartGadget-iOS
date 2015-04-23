//
//  BLEUtil.m
//  smartgadgetapp
//
//  Copyright (c) 2012 Sensirion AG. All rights reserved.
//

#import "BLEUtil.h"

@implementation BLEUtil

/**
*  @method swap:
*
*  @param s Uint16 value to byteswap
*
*  @discussion swap byteswaps a UInt16
*
*  @return Byteswapped UInt16
*/
+ (UInt16)swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

/**
*  @method findServiceFromUUID:
*
*  @param UUID CBUUID to find in service list
*  @param p Peripheral to find service on
*
*  @return pointer to CBService if found, nil if not
*
*  @discussion findServiceFromUUID searches through the services list of a peripheral to find a
*  service with a specific UUID
*/
+ (CBService *)findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p {
    for (CBService *s in [p services]) {
        NSLog(@"Checking service: %s\n", [self CBUUIDToString:s.UUID]);
        if ([self compareCBUUID:s.UUID UUID2:UUID])
            return s;
    }

    return nil; //Service not found on this peripheral
}

/**
*  @method findCharacteristicFromUUID:
*
*  @param UUID CBUUID to find in Characteristic list of service
*  @param service Pointer to CBService to search for charateristics on
*
*  @return pointer to CBCharacteristic if found, nil if not
*
*  @discussion findCharacteristicFromUUID searches through the characteristic list of a given service
*  to find a characteristic with a specific UUID
*/
+ (CBCharacteristic *)findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService *)service {
    for (CBCharacteristic *c in [service characteristics]) {
        if ([self compareCBUUID:c.UUID UUID2:UUID])
            return c;
    }

    return nil; //Characteristic not found on this service
}

/**
*  @method UUIDToString
*
*  @param UUID UUID to convert to string
*
*  @returns Pointer to a character buffer containing UUID in string representation
*
*  @discussion UUIDToString converts the data of a CFUUIDRef class to a character pointer
*/
+ (NSString *)UUIDToString:(CFUUIDRef)UUID {
    if (UUID) {
        CFStringRef s = CFUUIDCreateString(NULL, UUID);
        NSString *ret = [(__bridge NSString *) s copy];

        CFRelease(s);

        return ret;
    }

    return nil;
}

/**
*  @method CBUUIDToString
*
*  @param UUID UUID to convert to string
*
*  @returns Pointer to a character buffer containing UUID in string representation
*
*  @discussion CBUUIDToString converts the data of a CBUUID class to a character pointer for easy printout using printf()
*/
+ (const char *)CBUUIDToString:(CBUUID *)UUID {
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}

/**
*  @method compareCBUUID
*
*  @param UUID1 UUID 1 to compare
*  @param UUID2 UUID 2 to compare
*
*  @returns YES (equal) NO (not equal)
*
*  @discussion compareCBUUID compares two CBUUID's to each other and returns 1 if they are equal and 0 if they are not
*/
+ (BOOL)compareCBUUID:(CBUUID *)UUID1 UUID2:(CBUUID *)UUID2 {
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1 length:16];
    [UUID2.data getBytes:b2 length:16];

    return (memcmp(b1, b2, UUID1.data.length) == 0);
}

/**
*  @method compareCBUUIDToInt
*
*  @param UUID1 UUID 1 to compare
*  @param UUID2 UInt16 UUID 2 to compare
*
*  @returns true (equal) false (not equal)
*
*  @discussion compareCBUUIDToInt compares a CBUUID to a UInt16 representation of a UUID and returns 1
*  if they are equal and 0 if they are not
*/
+ (BOOL)compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2 {
    char b1[16];
    [UUID1.data getBytes:b1 length:16];
    UInt16 b2 = [self swap:UUID2];

    return (memcmp(b1, (char *) &b2, 2) == 0);
}

/**
*  @method CBUUIDToInt
*
*  @param UUID1 UUID 1 to convert
*
*  @returns UInt16 representation of the CBUUID
*
*  @discussion CBUUIDToInt converts a CBUUID to a Uint16 representation of the UUID
*/
+ (UInt16)CBUUIDToInt:(CBUUID *)UUID {
    char b1[16];
    [UUID.data getBytes:b1 length:16];
    return (UInt16) ((b1[0] << 8) | b1[1]);
}

/**
*  @method UUIDSAreEqual:
*
*  @param u1 CFUUIDRef 1 to compare
*  @param u2 CFUUIDRef 2 to compare
*
*  @returns true (equal) false (not equal)
*
*  @discussion compares two CFUUIDRef's
*/
+ (BOOL)UUIDSAreEqual:(CFUUIDRef)u1 u2:(CFUUIDRef)u2 {
    CFUUIDBytes b1 = CFUUIDGetUUIDBytes(u1);
    CFUUIDBytes b2 = CFUUIDGetUUIDBytes(u2);

    return (memcmp(&b1, &b2, 16) == 0);
}

/**
*  @method printPeripheralInfo:
*
*  @param peripheral Peripheral to print info of
*
*  @discussion printPeripheralInfo prints detailed info about peripheral
*/
+ (void)printPeripheralInfo:(CBPeripheral *)peripheral {
    NSLog(@"------------------------------------");
    NSLog(@"Peripheral Info :");
    NSLog(@"UUID : %@", [peripheral.identifier UUIDString]);
    NSLog(@"RSSI : %d", [[peripheral RSSI] intValue]);
    NSLog(@"Name : %@", [peripheral name]);
    NSLog(@"isConnected : %s", peripheral.state == CBPeripheralStateConnected ? "YES" : "NO");
    NSLog(@"-------------------------------------");
}

+ (NSArray *)getAdvertisedServices:(NSDictionary *)advertisementData {
    return advertisementData[@"kCBAdvDataServiceUUIDs"];
}

@end
