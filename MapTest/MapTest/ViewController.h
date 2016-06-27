//
//  ViewController.h
//  MapTest
//
//  Created by Khoi Nguyen on 6/24/16.
//  Copyright © 2016 Khoi Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import <ARSPContainerController.h>
#import "NavigationPanelVC.h"

@import AssetsLibrary;
@import GoogleMaps;
@interface ViewController : UIViewController <UINavigationControllerDelegate, GMSMapViewDelegate, CLLocationManagerDelegate, GMSAutocompleteViewControllerDelegate,ARSPVisibilityStateDelegate>

@property (weak, nonatomic) IBOutlet UITextField *tfEnd;
@property (weak, nonatomic) IBOutlet UITextField *tfStart;
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tfStartTopPaddingConstraint;

@property (weak, nonatomic) ARSPContainerController *panelContainerVC;

- (IBAction)onBtnMyLocationClick:(id)sender;
- (IBAction)onBtnCalculateClick:(id)sender;
- (IBAction)onBtnClearClick:(id)sender;
- (IBAction)onBtnSwapClick:(id)sender;

- (IBAction)onTextFieldStartClick:(id)sender;
- (IBAction)onTextFieldEndClick:(id)sender;

- (void) animateCameraToBound:(CLLocationCoordinate2D)startLocation endLocation:(CLLocationCoordinate2D)endLocation;
- (void) highlightStep:(DirectionStep*)step;

@end

