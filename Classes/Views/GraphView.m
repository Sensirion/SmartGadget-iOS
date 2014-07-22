//
//  GraphView.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "GraphView.h"

#import <QuartzCore/QuartzCore.h>

#import "AxisView.h"
#import "ConfigurationDataSource.h"
#import "GridView.h"
#import "IndicatorView.h"
#import "RHTPoint.h"
#import "Settings.h"

static const int AXIS_THICKNESS = 35;
static const int MIN_HUMIDITY = 0;
static const int MAX_HUMIDITY = 100;

@interface GraphView() {

    GridView *_gridView;
    AxisView *_tempAxis;
    AxisView *_humiAxis;

    NSMutableDictionary *_indicatorMap;
    NSString *_selectedIndicatorUUID;
    CABasicAnimation *_pulsAnimation;
}

@end

@implementation GraphView

- (void)setSelectedUUID:(NSString *)selectedUUID {
    IndicatorView *indicator = [_indicatorMap objectForKey:selectedUUID];
    [self setIndicatorSelected:indicator];
}

- (NSString *)selectedUUID {
    return _selectedIndicatorUUID;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }

    return self;
}

- (void)setupSubViews {
    // clear previous views if was setup...
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }

    //setup other stuff
    _indicatorMap = [NSMutableDictionary new];

    _pulsAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    _pulsAnimation.duration=0.5;
    _pulsAnimation.repeatCount=HUGE_VALF;
    _pulsAnimation.autoreverses=YES;
    _pulsAnimation.fromValue=[NSNumber numberWithFloat:1.0];
    _pulsAnimation.toValue=[NSNumber numberWithFloat:0.0];

    //create and add subviews
    _gridView = [[GridView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width - AXIS_THICKNESS, self.bounds.size.height - AXIS_THICKNESS)];

    //round corners of grid background
    _gridView.layer.cornerRadius = 10;
    _gridView.clipsToBounds = YES;

    [_gridView.layer setBorderWidth:0.5F];
    [_gridView.layer setBorderColor:[UIColor blackColor].CGColor];

    int minTemp;
    int maxTemp;

    if ([Settings userDefaults].comfortZone == SEASON_SUMMER ) {
        minTemp = [RHTPoint adjustTemp:MIN_TEMPERATURE_SUMMER forUnit:[[Settings userDefaults] tempUnitType]];
        maxTemp = [RHTPoint adjustTemp:MAX_TEMPERATURE_SUMMER forUnit:[[Settings userDefaults] tempUnitType]];
    } else {
        minTemp = [RHTPoint adjustTemp:MIN_TEMPERATURE_WINTER forUnit:[[Settings userDefaults] tempUnitType]];
        maxTemp = [RHTPoint adjustTemp:MAX_TEMPERATURE_WINTER forUnit:[[Settings userDefaults] tempUnitType]];
    }

    float xAxeIncrement = 1.0;
    if ([[Settings userDefaults] tempUnitType] == UNIT_FARENHEIT) {
        xAxeIncrement = 2.0;
    }

    [_gridView setupHumidityRangeFrom:MIN_HUMIDITY to:MAX_HUMIDITY];
    [_gridView setupTemperatureRangeFrom:minTemp to:maxTemp];

    [self addSubview:_gridView];

    CGPoint gridOrigin = _gridView.frame.origin;
    CGSize gridSize = _gridView.bounds.size;

    _humiAxis = [[AxisView alloc] initWithFrame:CGRectMake(gridOrigin.x , (gridOrigin.y + gridSize.height), gridSize.width, AXIS_THICKNESS)];
    [_humiAxis setIncrement:10.0 withLowerBound:MIN_HUMIDITY andUpperBound:MAX_HUMIDITY];
    [_humiAxis setName:@"RELATIVE HUMIDITY" withUnit:relativeHumidityUnitString];
    [_humiAxis.layer setShadowColor:[UIColor blackColor].CGColor];
    [_humiAxis.layer setShadowOpacity:1];
    [_humiAxis.layer setShadowRadius:1.0];
    [_humiAxis.layer setShadowOffset:CGSizeMake(1.0, 1.0)];
    [self addSubview:_humiAxis];

    _tempAxis = [[AxisView alloc] initWithFrame:CGRectMake(gridOrigin.x + gridSize.width, gridOrigin.y, AXIS_THICKNESS, gridSize.height)];
    [_tempAxis setIncrement:xAxeIncrement withLowerBound:minTemp andUpperBound:maxTemp];
    [_tempAxis setName:@"TEMPERATURE" withUnit:[TemperatureConfigurationDataSource currentTemperatureUnitString]];
    [_tempAxis.layer setShadowColor:[UIColor blackColor].CGColor];
    [_tempAxis.layer setShadowOpacity:1];
    [_tempAxis.layer setShadowRadius:1.0];
    [_tempAxis.layer setShadowOffset:CGSizeMake(1.0, 1.0)];
    [self addSubview:_tempAxis];
}

- (void)addIndicator:(NSString *)gadgetUUID withColor:(UIColor *)indicatorColor {
    if ([[_indicatorMap allKeys] containsObject:gadgetUUID] ) {
        NSLog(@"ERROR: already have indicator for gadget: %@", gadgetUUID);
        return;
    }

    IndicatorView *indicator = [IndicatorView buttonWithType:UIButtonTypeCustom];
    indicator.gadgetUUID = gadgetUUID;
    [indicator setFrame:CGRectMake(0, 0, 12, 12)];
    [indicator.layer setCornerRadius:6];
    [indicator.layer setBorderWidth:1.5F];
    [indicator.layer setBorderColor:[UIColor whiteColor].CGColor];
    [indicator.layer setShadowColor:[UIColor blackColor].CGColor];
    [indicator.layer setShadowOpacity:1];
    [indicator.layer setShadowRadius:1.0];
    [indicator.layer setShadowOffset:CGSizeMake(1.0, 1.0)];

    [indicator setBackgroundColor:indicatorColor];
    [indicator setAutoresizingMask:UIViewAutoresizingFlexibleWidth];

    [indicator addTarget:self action:@selector(setIndicatorSelected:) forControlEvents:UIControlEventTouchDown];

    [_gridView addSubview:indicator];
    [indicator setCenter:CGPointMake(_gridView.bounds.size.width/2, _gridView.bounds.size.height/2)];
    [indicator.layer addAnimation:_pulsAnimation forKey:@"animateOpacity"];

    [_indicatorMap setObject:indicator forKey:gadgetUUID];
    [self setIndicatorSelected:indicator];
}

- (void)removeIndicator:(NSString *)gadgetUUID {
    if ([[_indicatorMap allKeys] containsObject:gadgetUUID]) {
        
        UIView *indicator = [_indicatorMap objectForKey:gadgetUUID];

        [indicator removeFromSuperview];
        [_indicatorMap removeObjectForKey:gadgetUUID];

        if ([[_indicatorMap allKeys] count] == 0) {
            // may be update gui and tell user that we are in progress?
        }

        //if the selected indicator was removed...
        if ([gadgetUUID isEqualToString:_selectedIndicatorUUID]){
            [self setIndicatorSelected:nil];
        }
    } else {
        NSLog(@"ERROR: Can not remove indicator for gadget: %@, can not find view", gadgetUUID);
    }
}

- (void)updateIndicator:(NSString *)gadgetUUID withTemp:(CGFloat)temp andHumidity:(CGFloat)humidity withAnimation:(BOOL)animate {
    UIView *indicator = [_indicatorMap objectForKey:gadgetUUID];

    if (indicator) {        
        [indicator.layer removeAllAnimations];

        CGPoint newCenter = [_gridView makePointIn:_gridView.frame forTemp:temp andHumidity:humidity];

        if (animate) {
            [UIView animateWithDuration:0.7f animations:^{

                [indicator setCenter:newCenter];

            } completion:^(BOOL finished) {
            }];
        } else {
            [indicator setCenter:newCenter];
            [self setNeedsDisplay];
        }
    } else {
        NSLog(@"ERROR: No indicator for gadget: %@", gadgetUUID);
    }
}

- (IBAction)setIndicatorSelected:(id)sender {
    IndicatorView *indicator = (IndicatorView *)sender;

    if (!indicator) {
        if ([_indicatorMap count] > 0) {
            indicator = [[_indicatorMap allValues] objectAtIndex:0];
        }
    }

    if (indicator) {
        _selectedIndicatorUUID = indicator.gadgetUUID;        
        [self findIndicator:indicator];
    } else {
        _selectedIndicatorUUID = nil;
    }
}

- (void)cycleSelectedIndicator {
    if ([_indicatorMap count] > 0) {
        NSUInteger currentIndex = [[_indicatorMap allKeys] indexOfObject:_selectedIndicatorUUID];

        if (currentIndex == NSNotFound) {
            currentIndex = 0;
        }

        IndicatorView *next = [[_indicatorMap allValues] objectAtIndex:(++currentIndex % [_indicatorMap count])];

        if (next) {
            [self setIndicatorSelected:next];
        }
    }
}

- (void)findIndicator:(IndicatorView *)indicator {
    [_gridView bringSubviewToFront:indicator];

    [UIView animateWithDuration:0.1f delay:0.0 options:(UIViewAnimationOptionCurveEaseOut)

                     animations:^{
                         [self updateIndicator:indicator withSize:16];

                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.1f delay:0.0 options:(UIViewAnimationOptionCurveEaseOut)

                                          animations:^{
                                              [self updateIndicator:indicator withSize:10];
                                          } completion:nil];
                     }];
}

- (void)updateIndicator:(IndicatorView *)indicator withSize:(CGFloat)size {
    // save the current possiton, we do not want to move the indicator
    CGPoint center = indicator.center;
    CGPoint origin = CGPointMake(center.x - (size/2), center.y - (size/2));

    CGRect frame = CGRectMake(0, 0, size, size);
    frame.origin = origin;

    [indicator.layer setCornerRadius:size/2];
    [indicator setFrame:frame];
}

@end
