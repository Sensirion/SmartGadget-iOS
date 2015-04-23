//
//  SettingsViewController.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "SettingsViewController.h"

#import "BLEConnector.h"
#import "ConfigurationDataSource.h"
#import "DefineSettingsViewController.h"

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self refreshFromSettings];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setGadgetDetailsLabel:nil];
    [self setTempertaureDetailsLabel:nil];
    [self setSeasonDetailsLabel:nil];
    [super viewDidUnload];
}

- (void)refreshFromSettings {
    long connectedGadgets = (long) [[BLEConnector sharedInstance] connectedGadgets].count;
    [self.GadgetDetailsLabel setText:[NSString stringWithFormat:@"%ld connected", connectedGadgets]];

    NSString *tempUnit = [TemperatureConfigurationDataSource currentTemperatureUnitString];
    [self.TempertaureDetailsLabel setText:tempUnit];

    NSString *season = [ComfortZoneConfigurationDataSource currentComfortZoneTitle];
    [self.SeasonDetailsLabel setText:season];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"tempSelect"]) {
        [((DefineSettingsViewController *) segue.destinationViewController) setDataSource:[TemperatureConfigurationDataSource sharedInstance]];
    } else if ([segue.identifier isEqualToString:@"comfortZoneSelect"]) {
        [((DefineSettingsViewController *) segue.destinationViewController) setDataSource:[ComfortZoneConfigurationDataSource sharedInstance]];
    }
}

@end
