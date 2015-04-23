//
//  MeasurementDataPoint.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "MeasurementDataPoint.h"

@implementation MeasurementDataPoint

+ (NSArray *)indexedProperties {
    return [NSArray arrayWithObject:@"gadget_id"];
}

@end