//
//  SettingsViewController.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController

@property(weak, nonatomic) IBOutlet UILabel *GadgetDetailsLabel;
@property(weak, nonatomic) IBOutlet UILabel *TempertaureDetailsLabel;
@property(weak, nonatomic) IBOutlet UILabel *SeasonDetailsLabel;

@end
