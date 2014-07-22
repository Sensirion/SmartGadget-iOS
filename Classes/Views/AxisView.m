//
//  AxisView.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "AxisView.h"

static const int LINE_GAP = 2;
static const int LINE_LENGTH = 13;

@interface AxisView() {
    int _lowerBound;
    int _upperBound;
    float _stepSize;

    NSString *_axisLabel;
}

@end

@implementation AxisView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setOpaque:NO];
    }

    return self;
}

- (void)setIncrement:(float)majorIncrement withLowerBound:(int)lowerBound andUpperBound:(int)upperBound {
    _stepSize = majorIncrement;
    _lowerBound = lowerBound;
    _upperBound = upperBound;
}

- (void)setName:(NSString *)name withUnit:(NSString *)unit {
    _axisLabel = [NSString stringWithFormat:@"%@ (%@)", name, unit];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextSetLineWidth(context, 0.5f);

    //figure out if axis is dawn vertically or horizontally from hight widht ratio
    BOOL horizontal = NO;
    if (rect.size.height < rect.size.width)
        horizontal = YES;

    int steps = (_upperBound - _lowerBound) / _stepSize;

    NSDictionary *labelAttributes = @{ NSFontAttributeName:[UIFont systemFontOfSize:9.0],
                                       NSForegroundColorAttributeName:[UIColor whiteColor] };
    CGSize labelSize = [@"00" sizeWithAttributes:labelAttributes];

    NSDictionary *nameLabelAttributes = @{ NSFontAttributeName:[UIFont boldSystemFontOfSize:14.0],
                                           NSForegroundColorAttributeName:[UIColor whiteColor] };
    CGSize nameLabelSize = [_axisLabel sizeWithAttributes:nameLabelAttributes];

    if (horizontal) {
        [_axisLabel drawAtPoint:CGPointMake(rect.size.width/2 - nameLabelSize.width/2, rect.size.height / 2) withAttributes:nameLabelAttributes];
    }

    // Rotate the context 90 degrees (convert to radians)
    CGAffineTransform transform = CGAffineTransformMakeRotation(-90.0 * M_PI/180.0);
    CGContextConcatCTM(context, transform);

    // Move the context back into the view
    CGContextTranslateCTM(context, -rect.size.height, 0);
    
    if (!horizontal) {
        [_axisLabel drawAtPoint:CGPointMake(rect.size.height/2  - nameLabelSize.width/2,  rect.size.width / 2) withAttributes:nameLabelAttributes];
    }

    float labelValue = 0;
    CGPoint labelPos;

    for (int i=1; i<=steps; ++i) {
        if (horizontal) {
            CGFloat width = (rect.size.width / steps) * i;

            CGContextMoveToPoint(context, rect.size.height - LINE_GAP, width);
            CGContextAddLineToPoint(context, rect.size.height - (LINE_GAP + LINE_LENGTH), width);

            labelPos = CGPointMake(rect.size.height - (LINE_GAP + LINE_LENGTH), width - labelSize.height);

        } else {
            CGFloat heigth = rect.size.height - (rect.size.height / steps) * i;

            CGContextMoveToPoint(context, heigth, LINE_GAP);
            CGContextAddLineToPoint(context, heigth, LINE_GAP + LINE_LENGTH);

            labelPos = CGPointMake(heigth + 2, LINE_GAP + LINE_LENGTH - labelSize.height);
        }

        labelValue = _lowerBound + (_stepSize * (steps-i));
        NSString *label = [NSString stringWithFormat:@"%g", labelValue];
        [label drawAtPoint:labelPos withAttributes:labelAttributes];
    }

    CGContextStrokePath(context);

    //clean up
    CGContextRestoreGState(context);
}

@end
