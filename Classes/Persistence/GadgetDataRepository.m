//
//  GadgetDataRepository.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "GadgetDataRepository.h"

#import <CoreData/CoreData.h>

#import "Configuration.h"
#import "MeasurementDataPoint.h"
#import "Settings.h"

@interface GadgetDataRepository () {
    NSManagedObjectContext *_managedObjectContext;
}

@end

@implementation GadgetDataRepository

+ (GadgetDataRepository *)sharedInstance {
    static GadgetDataRepository *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GadgetDataRepository alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        //initialize members
    }

    return self;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)context {
    _managedObjectContext = context;
}

- (GadgetData *)addGadgetWithId:(uint64_t)gadgetId {
    GadgetData *gadget = (GadgetData *)[NSEntityDescription insertNewObjectForEntityForName:@"GadgetData" inManagedObjectContext:_managedObjectContext];
    gadget.gadget_id = [NSNumber numberWithUnsignedLongLong:gadgetId];

    NSLog(@"Created gadget data with id = %llu", [gadget.gadget_id unsignedLongLongValue]);

    if ([self saveContext]) {
        return gadget;
    }

    return nil;
}

- (GadgetData *)getGadgetWithId:(uint64_t)gadgetId {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GadgetData" inManagedObjectContext:_managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    // Set example predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"gadget_id == %llu", gadgetId];
    [request setPredicate:predicate];

    NSError *error = nil;
    NSArray *array = [_managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        // Deal with error...
        NSLog(@"ERROR: %@", error);
    }

    if (array && [array count]) {
        return [array objectAtIndex:0];
    }

    return [self addGadgetWithId:gadgetId];
}

- (NSManagedObject *)getLightWeightGadgetWithId:(uint64_t)gadgetId {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GadgetData" inManagedObjectContext:_managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setPropertiesToFetch:[NSArray arrayWithObject:@"gadget_id"]];

    // Set example predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"gadget_id == %llu", gadgetId];
    [request setPredicate:predicate];

    NSError *error = nil;
    NSArray *array = [_managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        // Deal with error...
        NSLog(@"ERROR: %@", error);
    }

    if (array && [array count]) {
        return [array objectAtIndex:0];
    }

    return nil;
}

- (void)addDataPoint:(NSDate *)timestamp withTemp:(float)temp andHumidity:(float)humidity toGadgetWithId:(uint64_t)gadgetId {
    NSManagedObject *gadgetData = [self getLightWeightGadgetWithId:gadgetId];

    if (gadgetData) {
        MeasurementDataPoint *point = (MeasurementDataPoint *)[NSEntityDescription insertNewObjectForEntityForName:@"MeasurementDataPoint" inManagedObjectContext:_managedObjectContext];

        [point setTimestamp:timestamp];
        [point setTemperature:[[NSDecimalNumber alloc] initWithFloat:temp]];
        [point setHumidity:[[NSDecimalNumber alloc] initWithFloat:humidity]];

        //add to parent
        [point setGadget:(GadgetData *)gadgetData];

        [self saveContext];
    } else {
        NSLog(@"Could not save data point, could not find gadget data for id: %llu", gadgetId);
    }
}

- (NSDate *)getMinOrMaxTime:(BOOL)getMin forGadget:(uint64_t)gadgetId {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MeasurementDataPoint" inManagedObjectContext:_managedObjectContext];
    [request setEntity:entity];

    // Specify that the request should return dictionaries.
    [request setResultType:NSDictionaryResultType];

    // Create an expression for the key path.
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"timestamp"];

    // Create an expression to represent the minimum or max value at the key path 'timestamp'
    NSExpression *minExpression;
    if (getMin) {
        minExpression = [NSExpression expressionForFunction:@"min:" arguments:[NSArray arrayWithObject:keyPathExpression]];
    } else {
        minExpression = [NSExpression expressionForFunction:@"max:" arguments:[NSArray arrayWithObject:keyPathExpression]];
    }

    // Create an expression description using the minExpression and returning a date.
    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];

    // The name is the key that will be used in the dictionary for the return value.
    [expressionDescription setName:@"date"];
    [expressionDescription setExpression:minExpression];
    [expressionDescription setExpressionResultType:NSDateAttributeType];

    // Set the request's properties to fetch just the property represented by the expressions.
    [request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
    NSManagedObject *gadgetData = [self getLightWeightGadgetWithId:gadgetId];
    [request setPredicate:[NSPredicate predicateWithFormat:@"gadget == %@", gadgetData.objectID]];

    // Execute the fetch.
    NSError *error = nil;
    NSArray *objects = [_managedObjectContext executeFetchRequest:request error:&error];
    if (objects == nil) {
        // Handle the error.
    } else {
        if ([objects count] > 0) {
            return [[objects objectAtIndex:0] valueForKey:@"date"];
        }
    }

    return nil;
}

- (NSArray *)getData:(uint64_t)gadgetId {
    NSManagedObject *gadgetData = [self getLightWeightGadgetWithId:gadgetId];
    if (!gadgetData) {
        return nil;
    }

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"MeasurementDataPoint" inManagedObjectContext:_managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];

    // filtering of data, filter aout strange values...

    if (FILTER_DATA_FOR_STRANGE_VALUES) {
        [request setPredicate:[NSPredicate predicateWithFormat:@"gadget == %@ AND (temperature > 0.01 OR temperature < -0.01) AND temperature > -40 AND temperature < 110", gadgetData.objectID]];
    } else {
        [request setPredicate:[NSPredicate predicateWithFormat:@"gadget == %@", gadgetData.objectID]];
    }

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    NSError *error = nil;
    NSArray *array = [_managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        // Deal with error...
        NSLog(@"ERROR: %@", error);
    }

    if (array && [array count]) {
        return array;
    }

    return nil;
}

- (BOOL)hasData:(uint64_t)gadgetId {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GadgetData" inManagedObjectContext:_managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setPredicate:nil];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"gadget_id" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];

    NSError *error = nil;
    NSArray *array = [_managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        // Deal with error...
        NSLog(@"ERROR: %@", error);
    }

    if (array && [array count]) {
        return YES;
    }

    return NO;
}

- (NSArray *)getAllRecords {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GadgetData" inManagedObjectContext:_managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setPredicate:nil];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"gadget_id" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    NSError *error = nil;
    NSArray *array = [_managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        // Deal with error...
        NSLog(@"ERROR: %@", error);
    }

    if (array && [array count]) {
        return array;
    }

    return nil;
}

- (NSArray *)getGadgetsWithSomeDownloadedData {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GadgetData" inManagedObjectContext:_managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setPredicate:nil];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"gadget_id" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    NSError *error = nil;
    NSArray *array = [_managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        // Deal with error...
        NSLog(@"ERROR: %@", error);
    }

    NSMutableArray *returnArray = [NSMutableArray new];

    // filter array to show only members with some data.
    if (array && [array count]) {

        for (GadgetData *data in array) {
            if (0 == [data.gadget_id unsignedLongLongValue]) {
                NSLog(@"Skipping gadget without id");
                continue;
            }
            if ([self hasData:[data.gadget_id unsignedLongLongValue]]) {
                NSLog(@"Gadget with id %llu has data..", [data.gadget_id unsignedLongLongValue]);
                [returnArray addObject:data];
            } else {
                NSLog(@"Gadget with id %llu has no data..", [data.gadget_id unsignedLongLongValue]);
            }
        }
        return returnArray;
    }

    return nil;
}

- (void)cleanAllDataOfGadgetWithId:(uint64_t)gadgetId {
    NSLog(@"Cleaning a data for id %llu", gadgetId);

    NSArray *dataPoints = [self getData:gadgetId];
    if (dataPoints) {
        for (id object in dataPoints) {
            [_managedObjectContext deleteObject:object];
        }
    }

    NSError *error;
    if ([_managedObjectContext save:&error]) {
        NSManagedObject *gadgetData = [self getLightWeightGadgetWithId:gadgetId];
        if (gadgetData) {
            NSLog(@"Goint to delete data for gadget...");
            [_managedObjectContext deleteObject:gadgetData];
        } else {
            NSLog(@"WARNING: Deleted Object does not exists...");
        }

        if ([_managedObjectContext save:&error]) {
            NSLog(@"INFO: All data deleted");
        } else {
            NSLog(@"WARNING: Object not deleted for some reason... %@", error);
        }
    } else {
        NSLog(@"WARNING: Object data not deleted for some reason... %@", error);
    }
}

- (NSUInteger)savedMeasurmentsCountForGadgetWithId:(uint64_t)gadgetId {
    NSManagedObject *gadgetData = [self getLightWeightGadgetWithId:gadgetId];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"MeasurementDataPoint"];
    [request setResultType:NSDictionaryResultType];

    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"timestamp"];
    NSExpression *countExpression = [NSExpression expressionForFunction:@"count:" arguments:[NSArray arrayWithObject:keyPathExpression]];

    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
    [expressionDescription setName:@"gadgetDataTypeCount"];
    [expressionDescription setExpression:countExpression];
    [expressionDescription setExpressionResultType:NSInteger32AttributeType];
    [request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];

    [request setPredicate:[NSPredicate predicateWithFormat:@"gadget == %@", gadgetData.objectID]];

    NSError *error = nil;
    NSArray *results = [_managedObjectContext executeFetchRequest:request error:&error];

    if (error) {
        NSLog(@"ERROR: %@", error);
    } else if (results && results.count) {
        NSNumber* count = [[results objectAtIndex:0] objectForKey:@"gadgetDataTypeCount"];
        return [count unsignedIntegerValue];
    }

    return 0;
}

- (NSUInteger)getLastSynchPointForGadgetWithId:(uint64_t)gadgetId {
    GadgetData *gadgetData = [self getGadgetWithId:gadgetId];

    if (gadgetData) {
        return [gadgetData.lastPointer unsignedIntegerValue];
    }

    [NSException raise:@"ERROR: Gadget data not found" format:@"Could not find gadget data for id: %llu", gadgetId];

    //just to get rid of the silly warning...
    return 0;
}

- (void)setLastSynchPoint:(NSUInteger)lastPoint forGadgetWithId:(uint64_t)gadgetId {
    GadgetData *gadgetData = [self getGadgetWithId:gadgetId];

    if (gadgetData) {
        NSLog(@"Setting last point to: %lu", (unsigned long)lastPoint);
        gadgetData.lastPointer = [NSNumber numberWithUnsignedInteger:lastPoint];
        [self saveContext];

        //TODO: throw away "newer" data?, it will be read again...

    } else {
        [NSException raise:@"ERROR: Gadget data not found" format:@"Could not find gadget data for id: %llu", gadgetId];
    }
}

- (uint64_t)getGadgetIdFor:(NSString *)UUID {

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GadgetData" inManagedObjectContext:_managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
//    [request setPropertiesToFetch:[NSArray arrayWithObject:@"gadget_id"]];

    // Set example predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastKnownUUID == %@", UUID];
    [request setPredicate:predicate];

    NSError *error = nil;
    NSArray *array = [_managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        // Deal with error...
        NSLog(@"ERROR: %@", error);
    }

    if (array && [array count]) {
        return [[[array objectAtIndex:0] gadget_id] unsignedLongLongValue];
    }

    //not found
    return 0;
}

- (void)updateLastKnownUUID:(NSString *)UUID forGadget:(uint64_t)gadgetId {

    dispatch_async(dispatch_get_main_queue(), ^{

        GadgetData *gadgetData = [self getGadgetWithId:gadgetId];

        if (gadgetData) {
            NSLog(@"Setting last known UUID to: %@", UUID);
            gadgetData.lastKnownUUID = UUID;
            [self saveContext];
        } else {
            [NSException raise:@"ERROR: Gadget data not found" format:@"Could not find gadget data for id: %llu", gadgetId];
        }
    });
}

- (BOOL)save:(GadgetData *)gadgetData {
    return [self saveContext];
}

- (BOOL)saveContext {
    NSError *error = nil;
    if ([_managedObjectContext save:&error]) {
        //NSLog(@"Context saved.");
        return YES;
    } else {
        NSLog(@"ERROR: Context not saved.");
        // Handle the error.
        [NSException raise:@"Failed to save context" format:@"Returned error: %@", error];
    }

    return NO;
}

@end
