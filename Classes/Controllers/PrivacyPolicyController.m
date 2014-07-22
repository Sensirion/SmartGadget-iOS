//
//  PrivacyPolicyController.m
//  smartgadgetapp
//
//  Created by AZOM on 10/12/13.
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "PrivacyPolicyController.h"
#import "Settings.h"

@interface PrivacyPolicyController ()

@end

@implementation PrivacyPolicyController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.infoText setText:privacyPolicy];
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
