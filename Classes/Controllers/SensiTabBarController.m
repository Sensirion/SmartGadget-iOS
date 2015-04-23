//
//  SensiTabBarController.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "SensiTabBarController.h"

@interface SensiTabBarController () <UITabBarControllerDelegate>

@end

@implementation SensiTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self setDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        //back to root when a tab is clicked...
        [(UINavigationController *) viewController popToRootViewControllerAnimated:NO];
    }
}

@end
