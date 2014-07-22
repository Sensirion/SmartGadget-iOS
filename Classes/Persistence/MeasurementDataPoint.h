//
//  MeasurementDataPoint.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GadgetData;

@interface MeasurementDataPoint : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber *humidity;
@property (nonatomic, retain) NSDecimalNumber *temperature;
@property (nonatomic, retain) NSDate *timestamp;
@property (nonatomic, retain) GadgetData *gadget;

@end
