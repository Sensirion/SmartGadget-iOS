//
//  GadgetDataRepository.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "GadgetDataRepository.h"

#import "MeasurementDataPoint.h"

static float const LOWER_TEMPERATURE_THREESHOLD = -40.0f;
static float const UPPER_TEMPERATURE_THREESHOLD = 110.0f;
static float const CORRUPT_TEMPERATURE_VALUE = 0.0f;

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

- (GadgetData *) addGadgetWithId:(long long)gadgetId {
    GadgetData *gadget = [[GadgetData alloc] init];
    gadget.gadget_id = gadgetId;
    NSLog(@"Created gadget data with id = %lld", gadgetId);
    [self storeObjectWithTransaction:gadget];
    return gadget;
}

- (GadgetData *)getGadgetWithId:(long long)gadgetId {
    NSString *querySelection = [NSString stringWithFormat:@"gadget_id == %lld", gadgetId];
    RLMResults *result = [GadgetData objectsWhere:querySelection];
    if (result && [result count]){
        return result[0];
    }
    return [self addGadgetWithId:gadgetId];
}

- (void)addDataPoint:(NSDate *)timestamp withTemp:(float)temp andHumidity:(float)humidity toGadgetWithId:(long long)gadgetId {
    MeasurementDataPoint *dataPoint = [[MeasurementDataPoint alloc] init];
    dataPoint.temperature = temp;
    dataPoint.humidity = humidity;
    dataPoint.gadget = [self getGadgetWithId:gadgetId];
    dataPoint.timestamp = timestamp;
    [self storeObjectWithTransaction:dataPoint];
}

- (NSDate *)getMinOrMaxTime:(BOOL)getMin forGadget:(long long)gadgetId {
    NSString *querySelection = [NSString stringWithFormat:@"gadget.gadget_id == %lld", gadgetId];
    RLMResults *result = [MeasurementDataPoint objectsWhere:querySelection];
    if (result && [result count]){
        if (getMin == YES){
            return [result minOfProperty:@"timestamp"];
        }
        return [result maxOfProperty:@"timestamp"];
    }
    return nil;
}

- (NSArray *)getData:(long long) gadgetId {
    NSString *temperaturePredicate = [NSString stringWithFormat:@"!(temperature == %f OR temperature > %f OR temperature < %f)", CORRUPT_TEMPERATURE_VALUE, UPPER_TEMPERATURE_THREESHOLD, LOWER_TEMPERATURE_THREESHOLD];
    NSString *querySelection = [NSString stringWithFormat:@"gadget.gadget_id == %lld AND %@", gadgetId, temperaturePredicate];
    RLMResults *result = [MeasurementDataPoint objectsWhere:querySelection];
    if (result && [result count]) {
        RLMResults *orderedResults = [result sortedResultsUsingProperty:@"timestamp" ascending:YES];
        return [self convertRLMResultsToNSArray: orderedResults];
    }
    return nil;
}

- (BOOL)hasData:(long long)gadgetId {
    NSString *temperaturePredicate = [NSString stringWithFormat:@"!(temperature == %f OR temperature > %f OR temperature < %f)", CORRUPT_TEMPERATURE_VALUE, UPPER_TEMPERATURE_THREESHOLD, LOWER_TEMPERATURE_THREESHOLD];
    NSString *querySelection = [NSString stringWithFormat:@"gadget.gadget_id == %lld AND %@", gadgetId, temperaturePredicate];
    RLMResults *result = [MeasurementDataPoint objectsWhere:querySelection];
    return result && [result count];
}

- (NSArray *)getAllRecords {
    RLMResults *results = [GadgetData allObjects];
    if (results && [results count]){
        RLMResults *orderedResults = [results sortedResultsUsingProperty:@"gadget_id" ascending:YES];
        return [self convertRLMResultsToNSArray: orderedResults];
    }
    return nil;
}

- (NSArray *)getGadgetsWithSomeDownloadedData {
    NSArray *gadgets = [self getAllRecords];
    if (!gadgets || [gadgets count] == 0){
        return nil;
    }
    NSMutableArray *returnArray = [NSMutableArray new];
    for (GadgetData *gadget in gadgets) {
        if ([self hasData:[gadget gadget_id]]){
            NSLog(@"Device %lld has data", gadget.gadget_id);
            [returnArray addObject:gadget];
        } else {
            NSLog(@"Device %lld do not have data", gadget.gadget_id);
        }
    }
    return ([returnArray count] > 0) ? returnArray : nil;
}

- (void)cleanAllDataOfGadgetWithId:(long long)gadgetId {
    NSLog(@"Cleaning a data for id %lld", gadgetId);
    NSArray *dataPoints = [self getData:gadgetId];
    if (!dataPoints ||[dataPoints count] == 0){
        NSLog(@"Gadget with id %lld does not have data", gadgetId);
        return;
    }
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    for (MeasurementDataPoint *dataPoint in dataPoints){
        [realm deleteObject : dataPoint];
    }
    [realm commitWriteTransaction];
    NSLog(@"INFO: All data deleted");
}

- (long)savedMeasurementsCountForGadgetWithId:(long long)gadgetId {
    NSString *querySelection = [NSString stringWithFormat:@"gadget.gadget_id == %lld", gadgetId];
    RLMResults *result = [MeasurementDataPoint objectsWhere:querySelection];
    return (result) ? [result count] : 0;
}

- (long)getLastSyncPointForGadgetWithId:(long long)gadgetId {
    GadgetData *gadgetData = [self getGadgetWithId:gadgetId];
    if (gadgetData) {
        return gadgetData.lastPointer;
    }
    [NSException raise:@"ERROR: Gadget data not found" format:@"Could not find gadget data for id: %lld", gadgetId];
    //just to get rid of the silly warning...
    return 0;
}

- (void)setLastSyncPoint:(long)lastPoint forGadgetWithId:(long long)gadgetId {
    GadgetData *gadgetData = [self getGadgetWithId:gadgetId];
    if (gadgetData) {
        NSLog(@"Setting last point to: %ld",lastPoint);
        RLMRealm *realm = [self getRealm];
        [realm beginWriteTransaction];
        gadgetData.lastPointer = lastPoint;
        [realm commitWriteTransaction];
    } else {
        [NSException raise:@"ERROR: Gadget data not found" format:@"Could not find gadget data for id: %lld", gadgetId];
    }
}

- (long long)getGadgetIdFor:(NSString *)UUID {
    NSString *querySelection = [NSString stringWithFormat:@"lastKnownUUID = '%@'", UUID];
    RLMResults *result = [GadgetData objectsWhere:querySelection];
    if (result && [result count]){
        GadgetData *gadget = result[0];
        return [gadget gadget_id];
    }
    //not found
    return 0;
}

- (void)updateLastKnownUUID:(NSString *)UUID forGadget:(long long)gadgetId {
    GadgetData *gadgetData = [self getGadgetWithId:gadgetId];
    if (gadgetData) {
        NSLog(@"Setting last known UUID to: %@", UUID);
        RLMRealm *realm = [self getRealm];
        [realm beginWriteTransaction];
        gadgetData.lastKnownUUID = UUID;
        [realm commitWriteTransaction];
    } else {
        [NSException raise:@"ERROR: Gadget data not found" format:@"Could not find gadget data for id: %lld", gadgetId];
    }
}


- (void)storeObjectWithTransaction: (RLMObject*) object {
    RLMRealm *realm = [self getRealm];
    [realm beginWriteTransaction];
    [realm addObject:object];
    [realm commitWriteTransaction];
}

- (NSArray *)convertRLMResultsToNSArray : (RLMResults *) results {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:results.count];
    for (RLMObject *object in results) {
        [array addObject:object];
    }
    return array;
}

- (RLMRealm *)getRealm {
    return [RLMRealm defaultRealm];
}

@end
