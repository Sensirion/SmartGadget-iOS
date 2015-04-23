//
//  LogDataSelectViewController.m
//  smartgadgetapp
//
//  Copyright (c) 2015 Sensirion AG. All rights reserved.
//

#import "LogDataSelectViewController.h"

#import "AlertViewController.h"
#import "GadgetDataRepository.h"
#import "Settings.h"

@interface LogDataSelectViewController () {
    NSArray *_records;
}

@end

@implementation LogDataSelectViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _records = [[GadgetDataRepository sharedInstance] getGadgetsWithSomeDownloadedData];
    if ([_records count] == 0) {
        [AlertViewController showToastWithText:noDataAvailable];
    }

    [self.selectedAndInProgress stopAnimating];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1; // only one section, list of log records
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _records.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogCell"];
    // Configure the cell...
    GadgetData *data = _records[(NSUInteger) indexPath.row];
    long long currentId = [data gadget_id];
    [[cell textLabel] setText:[BLEGadget descriptionFromId:currentId]];
    if (currentId == [[Settings userDefaults] selectedLogIdentifier]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    GadgetData *data = _records[(NSUInteger) indexPath.row];
    [Settings userDefaults].selectedLogIdentifier = [data gadget_id];

    [[self navigationController] popViewControllerAnimated:YES];
}

@end
