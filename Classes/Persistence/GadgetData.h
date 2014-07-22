//
//  GadgetData.h
//  smartgadgetapp
//
//  Copyright (c) 2014 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MeasurementDataPoint;

@interface GadgetData : NSManagedObject

@property (nonatomic, retain) NSNumber * gadget_id;
@property (nonatomic, retain) NSNumber * lastPointer;
@property (nonatomic, retain) NSString * lastKnownUUID;
@property (nonatomic, retain) NSSet *measurements;
@end

@interface GadgetData (CoreDataGeneratedAccessors)

- (void)addMeasurementsObject:(MeasurementDataPoint *)value;
- (void)removeMeasurementsObject:(MeasurementDataPoint *)value;
- (void)addMeasurements:(NSSet *)values;
- (void)removeMeasurements:(NSSet *)values;

@end
