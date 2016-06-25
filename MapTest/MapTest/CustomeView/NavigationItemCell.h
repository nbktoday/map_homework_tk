//
//  AppDelegate.h
//  MapTest
//
//  Created by Khoi Nguyen on 6/24/16.
//  Copyright © 2016 Khoi Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NAVIGATION_CELL_ID @"NavigationItemCell"

@interface NavigationItemCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *ivNavigationIcon;
@property (weak, nonatomic) IBOutlet UILabel *lblNavigationDes;
@property (weak, nonatomic) IBOutlet UILabel *lblNavigationMeter;

@end
