//
//  NavigationPanelVC.m
//  MapTest
//
//  Created by Khoi Nguyen on 6/25/16.
//  Copyright © 2016 Khoi Nguyen. All rights reserved.
//

#import "NavigationPanelVC.h"
#import "Constants.h"
#import "NavigationItemCell.h"

@interface NavigationPanelVC ()

@end

@implementation NavigationPanelVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tblNavigation registerNib:[UINib nibWithNibName:@"NavigationItemCell" bundle:nil] forCellReuseIdentifier:NAVIGATION_CELL_ID];
    self.tblNavigation.contentInset = UIEdgeInsetsMake(0, 0, 20, 0);
    self.panelContainerVC = (ARSPContainerController*) self.parentViewController;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)updateNavigationDetailWithRoute:(DirectionRoute *)route{
    self.route = route;
    [self.lblViaRoute setText:route.viaSummary];
    [self.lblTotal setText:[NSString stringWithFormat:@"%@ / %@", [self prettyFormatDistance:route.totalDistance], [self prettyFormatDuration:route.totalDuration]]];
    
    if (self.panelContainerVC.visibleZoneHeight == 0) {
        self.panelContainerVC.visibleZoneHeight = IOS8_OR_LATER ? 80 : 90;
        [self.panelContainerVC minimizePanelControllerAnimated:NO completion:^{
            [self.tblNavigation reloadData];
        }];
    }else{
        [self.panelContainerVC minimizePanelControllerAnimated:YES completion:^{
            [self.tblNavigation reloadData];
        }];
    }
}

- (NSString*) prettyFormatDistance:(int) distanceInMeter{
    float distanceInKm = (float) distanceInMeter / 1000;
    if(distanceInMeter % 1000 > 0){
        return [NSString stringWithFormat:@"%.2f km", distanceInKm];
    }
    return [NSString stringWithFormat:@"%.0f km", distanceInKm];
}

- (NSString*) prettyFormatDuration:(int) durationInSecond{
    int minute = durationInSecond / 60;
    if (minute < 1) {
        return [NSString stringWithFormat:@"%d %@", durationInSecond, LString(@"second_value")];
    }
    
    int hour = minute / 60;
    if (hour < 1) {
        int secondRetain = durationInSecond % 60;
        if (secondRetain > 0) {
            return [NSString stringWithFormat:@"%d %@ %d %@", minute, LString(@"minute_value"), secondRetain, LString(@"second_value")];
        }else{
            return [NSString stringWithFormat:@"%d %@", minute, LString(@"minute_value")];
        }
    }
    
    int minuteRetain = minute % 60;
    int secondRetain = durationInSecond - hour * 3600 - minuteRetain * 60;
    
    NSString *min = @"";
    NSString *sec = @"";
    
    if (minuteRetain > 0) {
        min = [NSString stringWithFormat:@" %d %@", minuteRetain, LString(@"minute_value")];
    }
    
    if (secondRetain > 0) {
        sec = [NSString stringWithFormat:@" %d %@", secondRetain, LString(@"second_value")];
    }
    
    return [NSString stringWithFormat:@"%d %@%@%@", hour, LString(@"hour_value"), min, sec];
}
#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NavigationItemCell *cell = [tableView dequeueReusableCellWithIdentifier:NAVIGATION_CELL_ID forIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.panelContainerVC minimizePanelControllerAnimated:YES completion:^{

    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 60;
}


@end
