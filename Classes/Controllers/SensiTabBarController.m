//
//  SensiTabBarController.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "SensiTabBarController.h"

#import "Settings.h"

@interface SensiTabBarController() <UITabBarControllerDelegate>

@end

@implementation SensiTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[UITabBar appearance] setSelectedImageTintColor:[UIColor SENSIRION_GREEN]];
    [[UINavigationBar appearance] setTintColor:[UIColor SENSIRION_GREEN]];
    [[UIBarButtonItem appearance] setTintColor:[UIColor blackColor]];
            
    [self setDelegate:self];
    
   }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {    
    if ([viewController isKindOfClass:[UINavigationController class]])
    {
        //back to root when a tab is clicked...
        [(UINavigationController *)viewController popToRootViewControllerAnimated:NO];
    }
}

@end
