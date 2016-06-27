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
#import "ViewController.h"

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
    return self.route ? self.route.allSteps.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    DirectionStep *step = [self.route.allSteps objectAtIndex:indexPath.row];
    
    NavigationItemCell *cell = [tableView dequeueReusableCellWithIdentifier:NAVIGATION_CELL_ID forIndexPath:indexPath];
    
    NSMutableAttributedString * attrStr = [[NSMutableAttributedString alloc] initWithData:[step.htmlInstructions dataUsingEncoding:NSUnicodeStringEncoding] options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
    [attrStr addAttribute:NSFontAttributeName
                    value:[UIFont systemFontOfSize:14]
                    range:NSMakeRange(0, attrStr.length)];
    [cell.lblNavigationDes setAttributedText:attrStr];
    
    [cell.lblNavigationMeter setText:[NSString stringWithFormat:@"%@ / %@", step.distance, step.duration]];
    
    [cell.ivNavigationIcon setImage:[self getNavigationIconFromManeuver:step.maneuver]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return;
    }
    
    [self.panelContainerVC minimizePanelControllerAnimated:YES completion:^{
        DirectionStep *step = [self.route.allSteps objectAtIndex:indexPath.row];
        [((ViewController*)self.panelContainerVC.mainViewController) highlightStep:step];
        [((ViewController*)self.panelContainerVC.mainViewController) animateCameraToBound:step.startLocation endLocation:step.endLocation];
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return 101;
    }
    
    int rowHeight = 0;
    DirectionStep *step = [self.route.allSteps objectAtIndex:indexPath.row - 1];
    NSString *yourText = step.htmlInstructions;
    
    UIFont *font = [UIFont systemFontOfSize:14];
    CGRect  rect = [yourText boundingRectWithSize:CGSizeMake(300, 1000) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil];
    rowHeight += rect.size.height;
    
    yourText = [NSString stringWithFormat:@"%@", step.distance];
    font = [UIFont systemFontOfSize:12];
    rect = [yourText boundingRectWithSize:CGSizeMake(300, 1000) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil];
    rowHeight += rect.size.height;
    
    rowHeight += 12;
    
    return rowHeight;
}

- (IBAction)onPanelHandleTouched:(id)sender {
    if (self.panelContainerVC.visibilityState == ARSPVisibilityStateMaximized) {
        [self.panelContainerVC minimizePanelControllerAnimated:YES completion:nil];
    }else{
        [self.panelContainerVC maximizePanelControllerAnimated:YES completion:nil];
    }
}

- (UIImage*) getNavigationIconFromManeuver:(MANEUVER)maneuver{
    UIImage *img;
    if (maneuver > 0) {
        img = [UIImage imageNamed:[NSString stringWithFormat:@"%lu", (unsigned long)maneuver]];
    }
    return img;
}

@end
