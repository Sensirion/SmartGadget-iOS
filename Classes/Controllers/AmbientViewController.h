//
//  AmbientViewController.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SensiButton.h"

@class BLEGadget;

@interface AmbientViewController : UIViewController

@property(weak, nonatomic) BLEGadget *selectedGadget;

@property(weak, nonatomic) IBOutlet UILabel *logoLabel;
@property(weak, nonatomic) IBOutlet SensiButton *temperatureButton;
@property(weak, nonatomic) IBOutlet SensiButton *humidityButton;
@property(weak, nonatomic) IBOutlet SensiButton *dewPointButton;
@property(weak, nonatomic) IBOutlet SensiButton *heatIndexButton;
@property(weak, nonatomic) IBOutlet UITableView *connectedGadgetTable;

@end