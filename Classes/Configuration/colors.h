//
//  colors.h
//  smartgadgetapp
//
//  Copyright (c) 2014 Sensirion AG. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIColor (SensirionColors)

+ (UIColor *)SENSIRION_GREEN;
+ (UIColor *)SENSIRION_LIGHT_GRAY;
+ (UIColor *)SENSIRION_MIDDLE_GRAY;
+ (UIColor *)SENSIRION_DARK_GRAY;
+ (UIColor *)SENSIRION_TEXT_GRAY;

@end

@implementation UIColor (SensirionColors)

+ (UIColor *)SENSIRION_GREEN {
    return [UIColor colorWithRed:102/255.0 green:204/255.0 blue:51/255.0 alpha:1.0];
}

+ (UIColor *)SENSIRION_LIGHT_GRAY {
    return [UIColor colorWithRed:233/255.0 green:228/255.0 blue:224/255.0 alpha:1.0];
}

+ (UIColor *)SENSIRION_MIDDLE_GRAY {
    return [UIColor colorWithRed:210/255.0 green:202/255.0 blue:195/255.0 alpha:1.0];
}

+ (UIColor *)SENSIRION_DARK_GRAY {
    return [UIColor colorWithRed:188/255.0 green:176/255.0 blue:167/255.0 alpha:1.0];
}

+ (UIColor *)SENSIRION_TEXT_GRAY {
    return [UIColor colorWithRed:61/255.0 green:59/255.0 blue:56/255.0 alpha:1.0];
}

@end

@interface UIColor (DefaultColors)

+ (UIColor *)VIOLETT;
+ (UIColor *)PURPLE;
+ (UIColor *)YELLOW;
+ (UIColor *)ORANGE;
+ (UIColor *)RED;
+ (UIColor *)GREEN;
+ (UIColor *)BLUE;
+ (UIColor *)LIGHT_BLUE;

+ (UIColor *)Random;

@end

@implementation UIColor (DefaultColors)

+ (UIColor *)VIOLETT {
    return [UIColor colorWithRed:118/255.0 green:56/255.0  blue:128/255.0 alpha:1];
}

+ (UIColor *)PURPLE {
    return [UIColor colorWithRed:166/255.0 green:133/255.0 blue:172/255.0 alpha:1];
}

+ (UIColor *)YELLOW {
    return [UIColor colorWithRed:231/255.0 green:206/255.0 blue:30/255.0  alpha:1];
}

+ (UIColor *)ORANGE {
    return [UIColor colorWithRed:213/255.0 green:137/255.0 blue:37/255.0  alpha:1];
}

+ (UIColor *)RED {
    return [UIColor colorWithRed:163/255.0 green:51/255.0  blue:21/255.0  alpha:1];
}

+ (UIColor *)GREEN {
    return [UIColor colorWithRed:71/255.0  green:120/255.0 blue:42/255.0  alpha:1];
}

+ (UIColor *)BLUE {
    return [UIColor colorWithRed:77/255.0  green:93/255.0  blue:146/255.0 alpha:1];
}

+ (UIColor *)LIGHT_BLUE {
    return [UIColor colorWithRed:18/255.0  green:161/255.0 blue:191/255.0 alpha:1];
}

+ (UIColor *)Random {
    CGFloat hue = (arc4random() % 256 / 255.0);  //  0.0 to 1.0
    CGFloat saturation = 1; // full saturation
    CGFloat brightness = 1; // full brightness
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

@end