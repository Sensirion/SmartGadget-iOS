//
//  GraphView.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GridView;
@class AxisView;

@interface GraphView : UIView

- (void)setupSubViews;
- (void)addIndicator:(NSString *)gadgetUUID withColor:(UIColor *)indicatorColor;
- (void)removeIndicator:(NSString *)gadgetUUID;
- (void)updateIndicator:(NSString *)gadgetUUID withTemp:(CGFloat)temp andHumidity:(CGFloat)humidity withAnimation:(BOOL)animate;
- (void)cycleSelectedIndicator;

@property NSString *selectedUUID;

@end
