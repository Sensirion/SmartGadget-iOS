//
//  GridView.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "GridView.h"

#import "ConfigurationDataSource.h"
#import "RHTPoint.h"

@interface GridView () {
    int _minTemp;
    int _maxTemp;
    int _minHumidity;
    int _maxHumidity;
}

@end

@implementation GridView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setOpaque:NO];
    }

    return self;
}

- (void)setupTemperatureRangeFrom:(int)min to:(int)max {
    _minTemp = min;
    _maxTemp = max;
}

- (void)setupHumidityRangeFrom:(int)min to:(int)max {
    _minHumidity = min;
    _maxHumidity = max;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    //draw background
    UIImage *image = [UIImage imageNamed:@"grid_background.png"];
    [image drawInRect:rect];

    //create grid
    CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextSetLineWidth(context, 0.1f);

    int tempSteps = _maxTemp - _minTemp;
    int humiSteps = (_maxHumidity - _minHumidity) / 10; //only draw for every 10 %

    //draw temp steps
    for (int i = 1; i < tempSteps; ++i) {
        CGFloat y = (rect.size.height / tempSteps) * i;

        CGContextMoveToPoint(context, 0, y);
        CGContextAddLineToPoint(context, rect.size.width, y);
    }

    //draw humidity steps
    for (int i = 1; i < humiSteps; ++i) {
        CGFloat x = (rect.size.width / humiSteps) * i;

        CGContextMoveToPoint(context, x, 0);
        CGContextAddLineToPoint(context, x, rect.size.height);
    }

    CGContextStrokePath(context);

    NSArray *comfortZone = [ComfortZoneConfigurationDataSource comfortZonePoints];

    CGContextSetStrokeColorWithColor(context, [[UIColor greenColor] CGColor]);
    CGContextSetLineWidth(context, 2.0);

    CGPoint lastPoint = [self makePointIn:rect forTemp:((RHTPoint *) [comfortZone lastObject]).temperature andHumidity:((RHTPoint *) [comfortZone lastObject]).relativeHumidity];

    CGContextMoveToPoint(context, lastPoint.x, lastPoint.y);

    for (RHTPoint *dataPoint in comfortZone) {
        CGPoint point = [self makePointIn:rect forTemp:dataPoint.temperature andHumidity:dataPoint.relativeHumidity];
        CGContextAddLineToPoint(context, point.x, point.y);
    }

    CGContextClosePath(context);
    CGContextStrokePath(context);

    // Rotate the context 90 degrees (convert to radians)
    CGAffineTransform rotateTransformation = CGAffineTransformMakeRotation((CGFloat) (-90.0 * M_PI / 180.0));
    CGContextConcatCTM(context, rotateTransformation);

    // Move the context back into the view
    CGContextTranslateCTM(context, -rect.size.height, 0);

    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);

    UIFont *labelFont = [UIFont systemFontOfSize:12.0f];

    /// Make a copy of the default paragraph style
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    /// Set line break mode
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    /// Set text alignment
    paragraphStyle.alignment = NSTextAlignmentRight;

    NSDictionary *labelAttributes = @{NSFontAttributeName : labelFont,
            NSParagraphStyleAttributeName : paragraphStyle,
            NSForegroundColorAttributeName : [UIColor whiteColor]};

    CGSize textSize = [respiratory sizeWithAttributes:labelAttributes];

    float leftBounds = 0.07;
    float topBounds = 0.12;
    float bottomBounds = (1 - topBounds);
    float rightBounds = (1 - leftBounds);

    [rheumatism drawAtPoint:CGPointMake(rect.size.height * leftBounds, rect.size.width * topBounds) withAttributes:labelAttributes];
    [respiratory drawAtPoint:CGPointMake(rect.size.height * leftBounds, (rect.size.width * bottomBounds) - textSize.height) withAttributes:labelAttributes];

    textSize = [heatStroke sizeWithAttributes:labelAttributes];
    [heatStroke drawAtPoint:CGPointMake((rect.size.height * rightBounds) - textSize.width, rect.size.width * topBounds) withAttributes:labelAttributes];

    textSize = [dehydration sizeWithAttributes:labelAttributes];
    [dehydration drawAtPoint:CGPointMake((rect.size.height * rightBounds) - textSize.width, (rect.size.width * bottomBounds) - textSize.height) withAttributes:labelAttributes];

    //clean up
    CGContextRestoreGState(context);
}

- (CGPoint)makePointIn:(CGRect)rect forTemp:(float)temp andHumidity:(float)humididty {
    return CGPointMake([self humidityToWidth:humididty inRect:rect], [self tempToHeight:temp inRect:rect]);
}

- (CGFloat)tempToHeight:(CGFloat)temp inRect:(CGRect)rect {
    CGFloat ret = rect.size.height - (((temp - _minTemp) / (_maxTemp - _minTemp)) * rect.size.height);

    if (ret > rect.size.height) {
        return rect.size.height;
    }

    if (ret < 0) {
        return 0.0f;
    }

    return rect.size.height - (((temp - _minTemp) / (_maxTemp - _minTemp)) * rect.size.height);
}

- (CGFloat)humidityToWidth:(CGFloat)humidity inRect:(CGRect)rect {
    CGFloat ret = rect.size.width - (((humidity - _minHumidity) / (_maxHumidity - _minHumidity)) * rect.size.width);

    if (ret > rect.size.width) {
        return rect.size.width;
    }

    if (ret < 0) {
        return 0.0f;
    }

    return rect.size.width - (((humidity - _minHumidity) / (_maxHumidity - _minHumidity)) * rect.size.width);
}

@end
