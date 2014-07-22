//
//  DefineSettingsViewController.h
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"

#import "ConfigurationDataSource.h"

@interface DefineSettingsViewController : UITableViewController

- (void)setDataSource:(id<TableViewDataSource>)dataSource;

@end
