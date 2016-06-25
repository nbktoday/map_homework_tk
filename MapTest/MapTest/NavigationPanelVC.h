//
//  NavigationPanelVC.h
//  MapTest
//
//  Created by Khoi Nguyen on 6/25/16.
//  Copyright © 2016 Khoi Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ARSPContainerController.h>
#import "DirectionRoute.h"

@class ViewController;

#define NAVIGATION_CELL_ID @"NavigationItemCell"

@interface NavigationPanelVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) ARSPContainerController *panelContainerVC;
@property (weak, nonatomic) IBOutlet UILabel *lblViaRoute;
@property (weak, nonatomic) IBOutlet UILabel *lblTotal;
@property (weak, nonatomic) IBOutlet UITableView *tblNavigation;
@property (weak, nonatomic) IBOutlet UIImageView *ivHandle;
@property (nonatomic) DirectionRoute *route;

- (void) updateNavigationDetailWithRoute:(DirectionRoute*)route;
@end
