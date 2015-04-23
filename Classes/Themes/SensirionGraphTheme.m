//
//  SensirionGraphTheme.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "SensirionGraphTheme.h"

#import "Settings.h"

@implementation SensirionGraphTheme

+ (NSString *)name {
    return @"SensirionGraphTheme";
}

- (id)init {
    self = [super init];
    if (self) {
        self.graphClass = [CPTXYGraph class];
    }

    return self;
}

#pragma mark -

- (void)applyThemeToAxis:(CPTXYAxis *)axis usingMajorLineStyle:(CPTLineStyle *)majorLineStyle
          minorLineStyle:(CPTLineStyle *)minorLineStyle majorGridLineStyle:majorGridLineStyle textStyle:(CPTTextStyle *)textStyle {
    axis.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
    axis.majorIntervalLength = [NSNumber numberWithFloat: 10.0f];
    axis.orthogonalPosition = [NSNumber numberWithDouble:0.0];
    axis.tickDirection = CPTSignNone;
    axis.minorTicksPerInterval = 1;
    axis.majorTickLineStyle = majorLineStyle;
    axis.minorTickLineStyle = minorLineStyle;
    axis.axisLineStyle = majorLineStyle;
    axis.majorTickLength = 5.0f;
    axis.minorTickLength = 3.0f;
    axis.labelTextStyle = textStyle;
    axis.titleTextStyle = textStyle;
    axis.majorGridLineStyle = majorGridLineStyle;
    axis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    axis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
}

- (void)applyThemeToBackground:(CPTXYGraph *)graph {
    graph.fill = [CPTFill fillWithColor:[CPTColor colorWithCGColor:[UIColor SENSIRION_MIDDLE_GRAY].CGColor]];
    graph.cornerRadius = CONTROLS_CORNER_RADIUS;
    graph.borderWidth = CONTROLS_BORDER_WIDTH;
    graph.borderColor = [UIColor SENSIRION_DARK_GRAY].CGColor;

    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.paddingBottom = 5;
    graph.paddingLeft = 5;
    graph.paddingRight = 10;
}

- (void)applyThemeToPlotArea:(CPTPlotAreaFrame *)plotAreaFrame {
    [plotAreaFrame plotArea].fill = [CPTFill fillWithColor:[CPTColor whiteColor]];

    plotAreaFrame.paddingLeft = 30;
    plotAreaFrame.paddingTop = 20;
    plotAreaFrame.paddingRight = 0;
    plotAreaFrame.paddingBottom = 45;

    [plotAreaFrame plotArea].cornerRadius = 2;
}

- (void)applyThemeToAxisSet:(CPTXYAxisSet *)axisSet {
    CPTMutableLineStyle *majorLineStyle = [CPTMutableLineStyle lineStyle];

    majorLineStyle.lineCap = kCGLineCapSquare;
    majorLineStyle.lineColor = [CPTColor grayColor];
    majorLineStyle.lineWidth = 1.0f;

    CPTMutableLineStyle *minorLineStyle = [CPTMutableLineStyle lineStyle];
    minorLineStyle.lineCap = kCGLineCapSquare;
    minorLineStyle.lineColor = [CPTColor grayColor];
    minorLineStyle.lineWidth = 0.5f;

    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.1f;
    majorGridLineStyle.lineColor = [CPTColor lightGrayColor];

    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25f;
    minorGridLineStyle.lineColor = [CPTColor blueColor];

    CPTMutableTextStyle *textStyle = [[CPTMutableTextStyle alloc] init];
    textStyle.color = [CPTColor blackColor];
    textStyle.fontSize = 10.0f;

    [self applyThemeToAxis:axisSet.xAxis usingMajorLineStyle:majorLineStyle minorLineStyle:minorLineStyle majorGridLineStyle:majorGridLineStyle textStyle:textStyle];
    [self applyThemeToAxis:axisSet.yAxis usingMajorLineStyle:majorLineStyle minorLineStyle:minorLineStyle majorGridLineStyle:majorGridLineStyle textStyle:textStyle];
}

@end
