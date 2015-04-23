//
//  GadgetData.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "GadgetData.h"

@implementation GadgetData

+ (NSString *)primaryKey {
    return @"gadget_id";
}

+ (NSArray *)indexedProperties {
    return [NSArray arrayWithObject:@"gadget_id"];
}

+ (NSDictionary *)defaultPropertyValues {
    return @{@"lastPointer" : @0, @"lastKnownUUID" : @"N/A"};
}

@end