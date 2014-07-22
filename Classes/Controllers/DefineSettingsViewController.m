//
//  DefineSettingsViewController.m
//  smartgadgetapp
//
//  Copyright (c) 2013 Sensirion AG. All rights reserved.
//

#import "DefineSettingsViewController.h"

#import "Settings.h"

@interface DefineSettingsViewController() {
 
    id<TableViewDataSource> _dataSource;
}

@end

@implementation DefineSettingsViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setDataSource:(id<TableViewDataSource>)dataSource {
    _dataSource = dataSource;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setDataSource:_dataSource];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_dataSource selectConfigurationAtRow:indexPath.row];
    [self.tableView reloadData];
}

@end
