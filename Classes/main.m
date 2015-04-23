//
//  main.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "AppDelegate.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        int retVal = -1;
        @try {
            retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        }
        @catch (NSException *exception) {
            NSLog(@"Uncaught exception: %@", exception.description);
            NSLog(@"Stack trace: %@", [exception callStackSymbols]);
        }
        return retVal;
    }
}