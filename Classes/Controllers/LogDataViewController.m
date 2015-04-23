//
//  LoggDataViewController.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "LogDataViewController.h"

#import "AlertViewController.h"
#import "CorePlot-CocoaTouch.h"
#import "GadgetDataRepository.h"
#import "MeasurementDataPoint.h"
#import "RHTPoint.h"
#import "SensirionGraphTheme.h"
#import "Settings.h"

static const float TIME_AXE_MARGIN_PERCENT = 10;
static const float VALUE_AXE_MARGIN_PERCENT = 10;

static const float PLOT_DEFAULT_MIN = 0;
static const float PLOT_DEFAULT_MAX = 100;

static const int ONE_DAY_IN_SECONDS = 24 * 60 * 60;
static const int ONE_WEEK_IN_SECONDS = ONE_DAY_IN_SECONDS * 7;

@interface LogDataViewController () <CPTPlotDataSource, LogDataNotificationProtocol, CPTPlotSpaceDelegate, SelectionDelegate> {

    /**
    * If currently displayed data belongs to a connected gadget,
    * we store the handle to it here.
    * otherwise, it is nil
    */
    BLEGadget *_currentGadget;

    uint64_t _lastDisplayedIdentifier;
    enum temperature_unit_type _lastDisplayedTempUnit;
    NSDate *_lastLoadedDataDate;

    // graph related
    int _allDataXrangeInSeconds;
    float _allDataYrange;
    float _yRangeStart;

    NSArray *_plotData;
    CPTXYGraph *_graph;
    NSDate *_plotedDatesReferenceDate;
    NSDateFormatter *_dateFormatter;

    // for double tap on graph to auto adjust size
    double _lastTap;

    enum display_type _displayType;
}

@end

@implementation LogDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _lastTap = CACurrentMediaTime();

    [[self whatIsDisplayedButton] shouldShowValues:NO];
    [[self updateDataButton] setEnabled:NO];

    self.selectDataNavigationButton.tintColor = [UIColor SENSIRION_GREEN];
    [[self whatIsDisplayedButton] reload];
    [self.whatIsDisplayedButton setDelegate:self];

    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];
    [_dateFormatter setDateStyle:(NSDateFormatterStyle) kCFDateFormatterShortStyle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([[Settings userDefaults] selectedLogIdentifier]) {
        //pointer to connected gadget or nil if not found
        _currentGadget = [[BLEConnector sharedInstance] getConnectedGadgetWithSystemId:[[Settings userDefaults] selectedLogIdentifier]];
    } else {
        /* this mean no gadget connected, no data downloaded from any gadget */
        [self loadEmptyGraphPreparedFor:[self.whatIsDisplayedButton displayType]];
    }

    if (_lastDisplayedIdentifier != [[Settings userDefaults] selectedLogIdentifier] || _lastDisplayedTempUnit != [[Settings userDefaults] tempUnitType]) {
        [self reloadDataAndMarkTimes];
    } else if (_lastLoadedDataDate && [[Settings userDefaults].lastDownloadFinished compare:_lastLoadedDataDate] == NSOrderedDescending) {
        [self reloadDataAndMarkTimes];
    }

    if (_currentGadget) {
        [[self updateDataButton] setEnabled:YES];

        if ([_currentGadget LoggerService]) {
            [_currentGadget.LoggerService notifyOnSync:self];
        }

    } else {
        [[self updateDataButton] setTitle:@"Gadget not connected" forState:UIControlStateDisabled];
    }
}

- (void)reloadDataAndMarkTimes {
    [self changeDisplayTypeTo:[[self whatIsDisplayedButton] displayType]];
    _lastDisplayedIdentifier = [[Settings userDefaults] selectedLogIdentifier];
    _lastDisplayedTempUnit = [[Settings userDefaults] tempUnitType];
    _lastLoadedDataDate = [NSDate date];
}

- (void)setWhatDisplaysGraph:(enum display_type)display {
    [self.whatIsDisplayedButton setDisplayType:display];
    [self displayGraphFor:display reloadData:YES];
}

- (void)displayGraphFor:(enum display_type)what reloadData:(BOOL)reloadData {

    NSLog(@"Loading graph, gadget id is: %llu", [[Settings userDefaults] selectedLogIdentifier]);

    if (reloadData) {
        // load the data, because this will calculate also many important like a range and so..
        NSLog(@"reloading persisted data...");
        [self loadPersistedData:[[self whatIsDisplayedButton] displayType]];
    }

    // Create graph from a custom theme
    NSString *description;

    _graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    if (_plotData && [[Settings userDefaults] selectedLogIdentifier]) {
        description = [showingDataFrom stringByAppendingString:[BLEGadget descriptionFromId:[[Settings userDefaults] selectedLogIdentifier]]];
        [[self graphLoadingSpinner] stopAnimating];
    } else {
        if ([[Settings userDefaults] selectedLogIdentifier]) {
            description = loadingData;
            [[self graphLoadingSpinner] setHidden:NO];
            [[self graphLoadingSpinner] startAnimating];
        } else {
            description = noDataConnectedGraphTitle;
            [[self graphLoadingSpinner] setHidden:YES];
            [[self graphLoadingSpinner] stopAnimating];
        }
    }

    // setup title
    [_graph setTitle:description];

    // setup sensirion theme
    CPTTheme *theme = [[SensirionGraphTheme alloc] init];
    [_graph applyTheme:theme];

    CPTXYAxis *y = ((CPTXYAxisSet *) _graph.axisSet).yAxis;
    CPTXYAxis *x = ((CPTXYAxisSet *) _graph.axisSet).xAxis;
    
    x.majorIntervalLength = [NSNumber numberWithInt:ONE_DAY_IN_SECONDS];
    x.minorTicksPerInterval = 0;

    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:_dateFormatter];
    timeFormatter.referenceDate = _plotedDatesReferenceDate;

    x.labelFormatter = timeFormatter;
    x.labelRotation = (CGFloat) (M_PI / 4);
    y.labelRotation = (CGFloat) (M_PI / 4);
    x.labelAlignment = CPTAlignmentCenter;

    self.graphHostView.hostedGraph = _graph;

    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    [self.graphHostView addGestureRecognizer:singleFingerTap];

    // Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) _graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;

    [plotSpace setDelegate:self];

    // Create a plot area
    CPTScatterPlot *boundLinePlot = [[CPTScatterPlot alloc] init];
    boundLinePlot.identifier = @"Temperature Plot";

    CPTMutableLineStyle *lineStyle = (CPTMutableLineStyle *) [boundLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth = 1.0f;
    lineStyle.lineColor = [CPTColor greenColor];
    boundLinePlot.dataLineStyle = lineStyle;

    boundLinePlot.dataSource = self;
    
    NSNumber *plotRangeLocation = [NSNumber numberWithFloat:0.0f];
    NSNumber *plotRangeLenght = [NSNumber numberWithFloat:(1 + (TIME_AXE_MARGIN_PERCENT / 100) * 2) * _allDataXrangeInSeconds];

    CPTPlotRange *xRange = [CPTPlotRange plotRangeWithLocation:plotRangeLocation length:plotRangeLenght];
    plotSpace.xRange = xRange;

    if ([plotSpace.xRange.length integerValue] < ONE_DAY_IN_SECONDS) {
        _dateFormatter.dateFormat = @"HH:mm:ss";
    } else {
        _dateFormatter.dateFormat = @"MMM-dd";
    }

    CPTPlotRange *yRange = [CPTPlotRange plotRangeWithLocation:[NSNumber numberWithFloat:(_yRangeStart - VALUE_AXE_MARGIN_PERCENT / 100 * _allDataYrange)]
                                                        length:[NSNumber numberWithFloat:((1 + (VALUE_AXE_MARGIN_PERCENT / 100) * 2) * _allDataYrange)]];
                            
    plotSpace.yRange = yRange;

    [_graph addPlot:boundLinePlot];
    [_graph reloadData];

    /**
    * Don't delete this, it will be needed in the next version
    *
    * UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(recognizeDirection:)];
    * pinchGesture.cancelsTouchesInView = NO;
    * [pinchGesture setDelegate:self];
    * [self.mainView addGestureRecognizer:pinchGesture];
    */
}

- (void)recognizeDirection:(UIPinchGestureRecognizer *)pinchRecognizer {
    double theSlope;
    if ([pinchRecognizer state] == UIGestureRecognizerStateBegan || [pinchRecognizer state] == UIGestureRecognizerStateChanged) {

        if ([pinchRecognizer numberOfTouches] > 1) {

            UIView *theView = [pinchRecognizer view];

            CGPoint locationOne = [pinchRecognizer locationOfTouch:0 inView:theView];
            CGPoint locationTwo = [pinchRecognizer locationOfTouch:1 inView:theView];
            NSLog(@"touch ONE  = %f, %f", locationOne.x, locationOne.y);
            NSLog(@"touch TWO  = %f, %f", locationTwo.x, locationTwo.y);

            if (locationOne.x == locationTwo.x) {
                // perfect vertical line
                // not likely, but to avoid dividing by 0 in the slope equation
                theSlope = 1000.0;
            } else if (locationOne.y == locationTwo.y) {
                // perfect horizontal line
                // not likely, but to avoid any problems in the slope equation
                theSlope = 0.0;
            } else {
                theSlope = (locationTwo.y - locationOne.y) / (locationTwo.x - locationOne.x);
            }

            double abSlope = ABS(theSlope);

            if (abSlope < 0.5) { //  Horizontal pinch - scale in the X
                NSLog(@"HORIZONTAL TAP");
            } else if (abSlope > 1.7) { // Vertical pinch - scale in the Y
                NSLog(@"VERTICAL TAP");
            } else {
                // Diagonal pinch - scale in both directions
                NSLog(@"BOTH DIRECTIONS TAP");
            }
        }
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    double currentTime = CACurrentMediaTime();

    if (currentTime - _lastTap < DOUBLE_TAP_INTERVAL) {
        [self displayGraphFor:[self.whatIsDisplayedButton displayType] reloadData:NO];
    }

    _lastTap = currentTime;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    _plotData = nil;
}

- (void)viewDidUnload {
    [self setGraphHostView:nil];
    [super viewDidUnload];
}

- (void)loadPersistedData:(enum display_type)type {
    NSArray *data = [[GadgetDataRepository sharedInstance] getData:[[Settings userDefaults] selectedLogIdentifier]];

    NSMutableArray *newData = [NSMutableArray array];

    NSDate *minTimestamp = [[GadgetDataRepository sharedInstance] getMinOrMaxTime:YES forGadget:[[Settings userDefaults] selectedLogIdentifier]];
    NSDate *maxTimestamp = [[GadgetDataRepository sharedInstance] getMinOrMaxTime:NO forGadget:[[Settings userDefaults] selectedLogIdentifier]];
    _allDataXrangeInSeconds = (int) [maxTimestamp timeIntervalSinceDate:minTimestamp];

    NSDecimalNumber *minYValue;
    NSDecimalNumber *maxYValue;

    _plotedDatesReferenceDate = [minTimestamp dateByAddingTimeInterval:-((TIME_AXE_MARGIN_PERCENT / 100) * _allDataXrangeInSeconds)];

    for (MeasurementDataPoint *dataPoint in data) {

        NSNumber *x = @([dataPoint.timestamp timeIntervalSinceDate:_plotedDatesReferenceDate]);
        NSNumber *y;
        switch (type) {
            case DISPTYPE_TEMPERATURE:
                y = @([RHTPoint adjustCelsiusTemperature: [dataPoint temperature] forUnit:[Settings userDefaults].tempUnitType]);
                break;
            case DISPTYPE_HUMIDITY:
                y = @([dataPoint humidity]);
                break;
            case DISPTYPE_DEW_POINT:
                y = @([RHTPoint getDewPointForHumidity:[dataPoint humidity] atTemperature:[dataPoint temperature]]);
                break;
            case DISPTYPE_HEAT_INDEX:
                y = @([RHTPoint getHeatIndexInCelsiusForHumidity:[dataPoint humidity] atTemperature:[dataPoint temperature]]);
                break;
            default:
                break;
        }

        if (y && y.floatValue > 0) {
            if (!minYValue || [minYValue compare:y] == NSOrderedDescending) {
                minYValue = (NSDecimalNumber *) [y copy];
            }
            if (!maxYValue || [maxYValue compare:y] == NSOrderedAscending) {
                maxYValue = (NSDecimalNumber *) [y copy];
            }
            [newData addObject:@{@(CPTScatterPlotFieldX) : x, @(CPTScatterPlotFieldY) : y}];
        }
    }

    NSLog(@"INFO: Y Axis min and max are: %@ and %@", minYValue, maxYValue);

    if (minYValue && maxYValue) {
        _allDataYrange = [maxYValue floatValue] - [minYValue floatValue];
        _yRangeStart = [minYValue floatValue];
    } else {
        _allDataYrange = PLOT_DEFAULT_MAX;
        _yRangeStart = PLOT_DEFAULT_MIN;
    }

    _plotData = [NSArray arrayWithArray:newData];
}

#pragma mark -
#pragma mark Plot Data Delegate Methods

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return [_plotData count];
}

- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    return [_plotData[index] objectForKey:@((long) fieldEnum)];
}

#pragma mark -
#pragma mark Plot Space Delegate Methods

- (CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate {
    // return newRange;
    if (CPTCoordinateX == coordinate) {
        if ([[newRange minLimit] integerValue] < 0 || [[newRange length] integerValue] > ONE_WEEK_IN_SECONDS) {
            _dateFormatter.dateFormat = @"MMM-dd";
        }
        if ([[newRange length] integerValue] < ONE_DAY_IN_SECONDS) {
            _dateFormatter.dateFormat = @"HH:mm:ss";
        }
        //_lastSelectedXRange = newRange;
        return newRange;
    }
    // allow y scrolling
    if (CPTCoordinateY == coordinate) {
        //_lastSelectedYRange = newRange;
        return newRange;
    }

    return [space plotRangeForCoordinate:coordinate];
}

- (IBAction)onDataClearButtonPushed:(id)sender {
    NSLog(@"Data Clear Pushed...");
    [AlertViewController onDeleteDataFromPhoneMemoryConfirmRequiredWithDelegate:self];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        NSLog(@"Delete data Canceled...");
    } else {
        if ([[Settings userDefaults] selectedLogIdentifier]) {
            NSLog(@"Going to delete all data for gadget: %llu", [[Settings userDefaults] selectedLogIdentifier]);
            [[GadgetDataRepository sharedInstance] cleanAllDataOfGadgetWithId:[[Settings userDefaults] selectedLogIdentifier]];
            [[Settings userDefaults] setSelectedLogIdentifier:0];
            _plotData = nil;
        }

        [self.graphLoadingSpinner startAnimating];
        [self loadEmptyGraphPreparedFor:[self.whatIsDisplayedButton displayType]];

        NSTimer *timer = [NSTimer timerWithTimeInterval:0.2 target:self
                                               selector:@selector(loadGraphAfterDelete) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
}

- (void)loadGraphAfterDelete {
    NSLog(@"Going to reload graph!");
    _lastDisplayedIdentifier = 0;
    [self displayGraphFor:[self.whatIsDisplayedButton displayType] reloadData:YES];
}

- (void)onSelection:(uint16_t)value sender:(SensiButton *)sender {
    if (sender == self.whatIsDisplayedButton) {
        [self changeDisplayTypeTo:(enum display_type) value];
    }
}

- (void)changeDisplayTypeTo:(enum display_type)displayType {
    [self.whatIsDisplayedButton reload];
    if (_displayType == displayType && _lastDisplayedIdentifier == [[Settings userDefaults] selectedLogIdentifier]) {
        NSLog(@"INFO: This type for this gadget was alredy displayed - checking if new data were downloaded...");
        if (_lastLoadedDataDate) {
            NSLog(@"INFO: Having last login date and last download date...");
            if ([Settings userDefaults].lastDownloadFinished) {
                NSLog(@"INFO: last download finished");
            } else {
                NSLog(@"INFO: No data downloaded on this app run, data are fresh...");
                if (_lastDisplayedTempUnit == [[Settings userDefaults] tempUnitType]) {
                    NSLog(@"INFO: Unit was not changed - return...");
                    return;
                }
            }

            if ([[Settings userDefaults].lastDownloadFinished compare:_lastLoadedDataDate] == NSOrderedAscending) {
                NSLog(@"INFO: Data are actual (updated: %@ dispalyed: %@)...", [Settings userDefaults].lastDownloadFinished, _lastLoadedDataDate);
                if (_lastDisplayedTempUnit == [[Settings userDefaults] tempUnitType]) {
                    return;
                }
            }
        }
    }
    _displayType = displayType;
    [self loadEmptyGraphPreparedFor:_displayType];

    NSTimer *timer = [NSTimer timerWithTimeInterval:0.2 target:self
                                           selector:@selector(changeGraphDisplayedContentDelayed) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)loadEmptyGraphPreparedFor:(enum display_type)displayType {
    NSLog(@"Loading Empty graph...");
    _plotData = nil;
    [self displayGraphFor:displayType reloadData:NO];
}

- (void)changeGraphDisplayedContentDelayed {
    [self setWhatDisplaysGraph:_displayType];
}

// DataNotification protocol implementation...

- (void)onLogDataSyncProgress:(CGFloat)progress {
    [self.updateDataButton setEnabled:NO];
    NSString *downloadTitle = [NSString stringWithFormat:@"Downloading... %d%%", (int) roundf(100 * progress)];
    [self.updateDataButton setTitle:downloadTitle forState:UIControlStateDisabled];
}

- (void)onLogDataSyncFinished {
    NSLog(@"Progress finished...");
    [self.updateDataButton setEnabled:YES];
    [self reloadDataAndMarkTimes];
}

- (IBAction)onDataUpdateButtonPressed:(id)sender {
    NSLog(@"Sync required pushed...");
    if (_currentGadget) {
        NSLog(@"Current gadget is..%@:", [_currentGadget peripheralName]);

        if ([_currentGadget LoggerService]) {
            if ([[_currentGadget LoggerService] trySynchronizeData]) {
                [self.updateDataButton setEnabled:NO];
            } else {
                NSLog(@"INFO: synch data could not be started");
            }
        }
    }
}

@end
