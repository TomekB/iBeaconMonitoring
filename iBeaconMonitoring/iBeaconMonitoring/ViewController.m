//
//  ViewController.m
//  iBeaconMonitoring
//
//  Created by Tomasz Baranowicz on 3/27/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
{
    CLLocationManager *_locationManager;
    UITableView *beaconsTableView;
    NSMutableDictionary *_beacons;
    NSMutableArray *regionsToScan;
}

- (void) prepareScanRegions;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"iBeacon monitoring";
    
    _beacons = [[NSMutableDictionary alloc] init];
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    
    [self prepareScanRegions];
    
    beaconsTableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    beaconsTableView.delegate = self;
    beaconsTableView.dataSource = self;
    beaconsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:beaconsTableView];
}

- (void)viewDidAppear:(BOOL)animated
{
    // Start ranging when the view appears.
    [regionsToScan enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLBeaconRegion *region = obj;
        [_locationManager startRangingBeaconsInRegion:region];
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    // Stop ranging when the view goes away.
    [regionsToScan enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLBeaconRegion *region = obj;
        [_locationManager stopRangingBeaconsInRegion:region];
    }];
}

- (void) prepareScanRegions
{
    regionsToScan = [[NSMutableArray alloc] init];
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"e2c56db5-dffb-48d2-b060-d0f5a71096e0"]; //UUID provided by Apple in their examples
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"com.beacon.Tomek"];
    region.notifyOnEntry = YES;
    region.notifyOnExit = YES;
    region.notifyEntryStateOnDisplay = YES;
    [regionsToScan addObject:region];
}

#pragma mark CLLocationManagerDelegate methods
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    [_beacons removeAllObjects];
    
    NSArray *unknownBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityUnknown]];
    if([unknownBeacons count])
        [_beacons setObject:unknownBeacons forKey:[NSNumber numberWithInt:CLProximityUnknown]];
    
    NSArray *immediateBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityImmediate]];
    if([immediateBeacons count])
        [_beacons setObject:immediateBeacons forKey:[NSNumber numberWithInt:CLProximityImmediate]];
    
    NSArray *nearBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityNear]];
    if([nearBeacons count])
        [_beacons setObject:nearBeacons forKey:[NSNumber numberWithInt:CLProximityNear]];
    
    NSArray *farBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityFar]];
    if([farBeacons count])
        [_beacons setObject:farBeacons forKey:[NSNumber numberWithInt:CLProximityFar]];
    
    [beaconsTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _beacons.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionValues = [_beacons allValues];
    return [[sectionValues objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    NSArray *sectionKeys = [_beacons allKeys];
    
    NSNumber *sectionKey = [sectionKeys objectAtIndex:section];
    switch([sectionKey integerValue])
    {
        case CLProximityImmediate:
            title = @"Immediate";
            break;
            
        case CLProximityNear:
            title = @"Near";
            break;
            
        case CLProximityFar:
            title = @"Far";
            break;
            
        default:
            title = @"Unknown";
            break;
    }
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *identifier = @"cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // Display the UUID, major, minor and accuracy for each beacon.
    NSNumber *sectionKey = [[_beacons allKeys] objectAtIndex:indexPath.section];
    CLBeacon *beacon = [[_beacons objectForKey:sectionKey] objectAtIndex:indexPath.row];
    cell.textLabel.text = [beacon.proximityUUID UUIDString];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Major: %@, Minor: %@, Acc: %.2fm", beacon.major, beacon.minor, beacon.accuracy];

    return cell;
}

@end
