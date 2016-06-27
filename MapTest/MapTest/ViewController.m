//
//  ViewController.m
//  MapTest
//
//  Created by Khoi Nguyen on 6/24/16.
//  Copyright © 2016 Khoi Nguyen. All rights reserved.
//

#import "ViewController.h"
#import "SnackBar.h"
#import <UIActionSheet+Blocks/UIActionSheet+Blocks.h>
#import <UIAlertView+Blocks.h>
#import <MBProgressHUD.h>
#import "DirectionStep.h"
#import "DirectionRoute.h"
#import <AFNetworking.h>

typedef enum TextFieldType : NSUInteger {
    START = 0,
    END,
    WAY_POINT
} TextFieldType;

typedef enum MarkerType : NSUInteger {
    START_MARKER = 0,
    END_MARKER,
    WAY_POINT_MARKER
} MarkerType;

@interface ViewController () {
    CLLocationManager *locationManager;
    BOOL isFirstTimeUpdateMyLocation;
    TextFieldType currentSearchTextFieldType;
    GMSMarker *currentSearchWaypointMarker;
    BOOL isDraggingMarker;
    
    GMSMarker *startMarker;
    GMSMarker *endMarker;
    NSMutableArray *waypointMarkers;
    NSMutableArray *navigationLines;
    DirectionRoute *route;
    GMSPolyline *highlightPolyline;
    UIAlertView *locationAuthorizationDialog;
    SnackBar *snackBar;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    isFirstTimeUpdateMyLocation = YES;
    waypointMarkers = [[NSMutableArray alloc] init];
    navigationLines = [[NSMutableArray alloc] init];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 30, 30)];
    [imageView setContentMode:UIViewContentModeCenter];
    [imageView setImage:[UIImage imageNamed:@"ic_start_marker_small"]];
    
    self.tfStart.leftViewMode = UITextFieldViewModeAlways;
    self.tfStart.leftView = imageView;
    self.tfStart.placeholder = @"Start";
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 30, 30)];
    [imageView setContentMode:UIViewContentModeCenter];
    [imageView setImage:[UIImage imageNamed:@"ic_end_marker_small"]];
    
    self.tfEnd.leftViewMode = UITextFieldViewModeAlways;
    self.tfEnd.leftView = imageView;
    self.tfEnd.placeholder = @"End";
    
    self.mapView.delegate = self;
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = 10;
    locationManager.delegate = self;
    
    [self enableMyLocation];
    
    self.panelContainerVC = (ARSPContainerController*) self.parentViewController;
    self.panelContainerVC.visibilityStateDelegate = self;
    [self.panelContainerVC closePanelControllerAnimated:NO completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewDidAppear:(BOOL)animated{
    if (isFirstTimeUpdateMyLocation && locationManager) {
        [locationManager startUpdatingLocation];
    }
    [self updateSnackBarMessage];
}

- (void)viewDidDisappear:(BOOL)animated{
    if (locationManager) {
        [locationManager stopUpdatingLocation];
    }
}
- (void) enableMyLocation{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        [self requestLocationAuthorization];
    }else if(status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted){
        if (!locationAuthorizationDialog) {
            locationAuthorizationDialog = [[UIAlertView alloc] initWithTitle:@"Notice" message:@"Location service require to use this app. Please go to Settings and enable it!" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        }
        if (!locationAuthorizationDialog.visible) {
            [locationAuthorizationDialog show];
        }
        return;
    }else{
        self.mapView.myLocationEnabled = YES;
    }
}
- (void) requestLocationAuthorization{
    if (IOS8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if (status != kCLAuthorizationStatusNotDetermined) {
        [self performSelector:@selector(enableMyLocation) withObject:nil afterDelay:[NSThread isMainThread]];
    }
}

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate{
    if (isDraggingMarker) {
        return;
    }
    
    if (!startMarker) {
        [self addStartMarkerWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        NSString *address = [self getGoogleAdrressFromLatitude:coordinate.latitude longitude:coordinate.longitude];
        [self.tfStart setText:address];
        [self updateSnackBarMessage];
        return;
    }
    
    if (!endMarker) {
        [self addEndMarkerWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        NSString *address = [self getGoogleAdrressFromLatitude:coordinate.latitude longitude:coordinate.longitude];
        [self.tfEnd setText:address];
        [self updateSnackBarMessage];
        return;
    }
    
    if ([waypointMarkers count] > 21) {
        [[SnackBar snackbarWithMessage:LString(@"waypoint_exceed_limit") actionText:nil duration:2 actionBlock:nil dismissalBlock:nil] show];
        return;
    }
    
    GMSMarker *waypointMarker = [self addWaypointMarkerWithLatitude:coordinate.latitude longitude:coordinate.longitude orderNumber:(int)[waypointMarkers count] + 1];
    [waypointMarkers addObject:waypointMarker];
    
    if ([waypointMarkers count] == 1) {
        [self updateSnackBarMessage];
    }
}

- (void)mapView:(GMSMapView *)mapView didBeginDraggingMarker:(GMSMarker *)marker
{
    isDraggingMarker = YES;
}

- (void)mapView:(GMSMapView *)mapView didEndDraggingMarker:(GMSMarker *)marker{
    isDraggingMarker = NO;
    
    int markerType = [marker.userData intValue];
    switch (markerType) {
        case START_MARKER:
        {
            NSString *address = [self getGoogleAdrressFromLatitude:marker.position.latitude longitude:marker.position.longitude];
            [self.tfStart setText:address];
        }
            break;
        case END_MARKER:
        {
            NSString *address = [self getGoogleAdrressFromLatitude:marker.position.latitude longitude:marker.position.longitude];
            [self.tfEnd setText:address];
        }
            break;
    }
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker{
    int markerType = [marker.userData intValue];
    switch (markerType) {
        case START_MARKER:
        {
            [UIActionSheet showFromRect:marker.accessibilityFrame inView:self.view animated:YES withTitle:nil cancelButtonTitle:LString(@"cancel") destructiveButtonTitle:LString(@"remove") otherButtonTitles:nil tapBlock:^(UIActionSheet * _Nonnull actionSheet, NSInteger buttonIndex) {
                if (buttonIndex == actionSheet.destructiveButtonIndex) {
                    startMarker.map = nil;
                    startMarker = nil;
                    self.tfStart.text = @"";
                    
                    [actionSheet setDidDismissBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex){
                        [self updateSnackBarMessage];
                    }];
                }
            }];
        }
            break;
        case END_MARKER:
        {
            [UIActionSheet showFromRect:marker.accessibilityFrame inView:self.view animated:YES withTitle:nil cancelButtonTitle:LString(@"cancel") destructiveButtonTitle:LString(@"remove") otherButtonTitles:nil tapBlock:^(UIActionSheet * _Nonnull actionSheet, NSInteger buttonIndex) {
                if (buttonIndex == actionSheet.destructiveButtonIndex) {
                    endMarker.map = nil;
                    endMarker = nil;
                    self.tfEnd.text = @"";
                    
                    [actionSheet setDidDismissBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex){
                        [self updateSnackBarMessage];
                    }];
                }
            }];
        }
            break;
        case WAY_POINT_MARKER:
        {
            NSUInteger ordinal = [waypointMarkers indexOfObject:marker];
            
            [UIActionSheet showFromRect:marker.accessibilityFrame inView:self.view animated:YES withTitle:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove" otherButtonTitles:@[@"Search via address"] tapBlock:^(UIActionSheet * _Nonnull actionSheet, NSInteger buttonIndex) {
                if (buttonIndex == actionSheet.destructiveButtonIndex) {
                    marker.map = nil;
                    
                    [waypointMarkers removeObjectAtIndex:ordinal];
                    
                    [self reorderWaypointMarkers];
                    
                    [actionSheet setDidDismissBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex){
                        [self updateSnackBarMessage];
                    }];
                }else if(buttonIndex == actionSheet.firstOtherButtonIndex){
                    [actionSheet setDidDismissBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex){
                        currentSearchTextFieldType = WAY_POINT;
                        currentSearchWaypointMarker = marker;
                        [self showAutoCompleteViewController];
                    }];
                }
            }];
        }
            break;
    }
    return YES;
}

- (void)mapView:(GMSMapView *)mapView didTapOverlay:(GMSOverlay *)overlay{
    
}

- (void) reorderWaypointMarkers{
    for (int i = 0;i < [waypointMarkers count]; i++) {
        GMSMarker *marker = [waypointMarkers objectAtIndex:i];
        marker.map = nil;
        
        [waypointMarkers replaceObjectAtIndex:i withObject:[self addWaypointMarkerWithLatitude:marker.position.latitude longitude:marker.position.longitude orderNumber:i + 1]];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        
        return;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [self updateSnackBarMessage];
}

- (void) addStartMarkerWithLatitude:(CLLocationDegrees) latitude longitude:(CLLocationDegrees)longitude{
    if (startMarker) {
        startMarker.map = nil;
        startMarker = nil;
    }
    
    startMarker = [self addMarkerWithLatitude:latitude longitude:longitude markerType:START_MARKER];
}

- (void) addEndMarkerWithLatitude:(CLLocationDegrees) latitude longitude:(CLLocationDegrees)longitude{
    if (endMarker) {
        endMarker.map = nil;
        endMarker = nil;
    }
    
    endMarker = [self addMarkerWithLatitude:latitude longitude:longitude markerType:END_MARKER];
}

- (GMSMarker*) addMarkerWithLatitude:(CLLocationDegrees) latitude longitude:(CLLocationDegrees)longitude markerType:(MarkerType)markerType{
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(latitude, longitude);
    marker.draggable = YES;
    [marker setUserData:[NSNumber numberWithInt:markerType]];
    
    switch (markerType) {
        case START_MARKER:
            marker.icon = [UIImage imageNamed:@"ic_start_marker"];
            break;
        case END_MARKER:
            marker.icon = [UIImage imageNamed:@"ic_end_marker"];
            break;
        default:
            break;
    }
    
    marker.map = self.mapView;
    return marker;
}

- (GMSMarker*) addWaypointMarkerWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude orderNumber:(int)orderNumber{
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(latitude, longitude);
    marker.draggable = YES;
    [marker setUserData:[NSNumber numberWithInt:WAY_POINT_MARKER]];
    marker.icon = [self createWaypointMarkerIcon:orderNumber];
    marker.map = self.mapView;

    return marker;
}

- (UIImage *) createWaypointMarkerIcon:(int)orderNumber{
    UIView *view = [[[NSBundle mainBundle] loadNibNamed:@"WaypointMarker" owner:nil options:nil] lastObject];
    
    UILabel *label = (UILabel*)[view viewWithTag:1000];
    label.text = [NSString stringWithFormat:@"%d", orderNumber];
    
    return [self imageFromView:view];
}

- (UIImage *)imageFromView:(UIView *) view{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(view.frame.size);
    }
    [view.layer renderInContext: UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    isFirstTimeUpdateMyLocation = NO;
    locationManager.delegate = nil;
    locationManager = nil;
    
    CLLocation *myLocation = [locations lastObject];
    [self addStartMarkerWithLatitude:myLocation.coordinate.latitude longitude:myLocation.coordinate.longitude];
    [self animateCameraToLatitude:myLocation.coordinate.latitude longitude:myLocation.coordinate.longitude zoom:DEFAULT_ZOOM_LEVEL];
    
    NSString *address = [self getGoogleAdrressFromLatitude:myLocation.coordinate.latitude longitude:myLocation.coordinate.longitude];
    [self.tfStart setText:address];
    
    [self updateSnackBarMessage];
}

-(NSString*) getGoogleAdrressFromLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude{
    NSString *address = @"";
    
    NSString *lookUpString  = [NSString stringWithFormat:GEOCODE_API_URL, latitude,longitude];
    lookUpString = [lookUpString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSData *jsonResponse = [NSData dataWithContentsOfURL:[NSURL URLWithString:lookUpString]];
    if (jsonResponse) {
        NSError *error = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonResponse options:kNilOptions error:&error];
        NSArray* jsonResults = [jsonDict objectForKey:@"results"];
        address = [[jsonResults firstObject] objectForKey:@"formatted_address"];
    }else{
        address = [NSString stringWithFormat:@"%f, %f", latitude, longitude];
    }
    
    return address;
}

- (void) drawDirectionFromStartPoint:(GMSMarker*)startPoint throughtWaypoints:(NSArray*)wayPointMarkers toDestinationPoint:(GMSMarker*)destinationPoint{
    
    NSString *waypoints = @"";
    if ([waypointMarkers count] > 0) {
        for (GMSMarker *marker in waypointMarkers) {
            waypoints = [waypoints stringByAppendingFormat:@"%f,%f|", marker.position.latitude, marker.position.longitude];
        }
        waypoints = [waypoints substringToIndex:[waypoints length]-1];
    }
    
    NSString *urlString = [NSString stringWithFormat: DIRECTION_API_URL,
                           startPoint.position.latitude,
                           startPoint.position.longitude,
                           waypoints,
                           destinationPoint.position.latitude,
                           destinationPoint.position.longitude,
                           [[NSLocale preferredLanguages] objectAtIndex:0],
                           DIRECTION_API_KEY];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"UrlString: %@", urlString);
    
    [[AFHTTPSessionManager manager] GET:urlString parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"Response data: %@", responseObject);
        
        if ([responseObject[@"status"] isEqualToString:@"ZERO_RESULTS"]){
            [[SnackBar snackbarWithMessage:@"Can not navigate!" actionText:nil duration:2 actionBlock:nil dismissalBlock:nil] show];
            return;
        }
        
        NSDictionary *routeDict = responseObject[@"routes"][0];
        
        route = [[DirectionRoute alloc] init];
        route.northeast = [[CLLocation alloc] initWithLatitude:[routeDict[@"bounds"][@"northeast"][@"lat"] doubleValue] longitude:[routeDict[@"bounds"][@"northeast"][@"lng"] doubleValue]];
        route.southwest = [[CLLocation alloc] initWithLatitude:[routeDict[@"bounds"][@"southwest"][@"lat"] doubleValue] longitude:[routeDict[@"bounds"][@"southwest"][@"lng"] doubleValue]];
        route.overviewPolyline = routeDict[@"overview_polyline"][@"points"];
        route.viaSummary = routeDict[@"summary"];
        if (route.viaSummary.length == 0) {
            route.viaSummary = LString(@"no_data");
        }
        
        NSArray *legs = routeDict[@"legs"];
        NSUInteger legSize = [legs count];
        
        route.legs = [[NSMutableArray alloc] initWithCapacity:legSize];
        route.allSteps = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < legSize; i++) {
            NSDictionary *legDict = legs[i];
            
            DirectionLeg *leg = [[DirectionLeg alloc] init];
            leg.distance = legDict[@"distance"][@"text"];
            leg.duration = legDict[@"duration"][@"text"];
            leg.startLocation = CLLocationCoordinate2DMake([legDict[@"start_location"][@"lat"] doubleValue], [legDict[@"start_location"][@"lng"] doubleValue]);
            leg.endLocation = CLLocationCoordinate2DMake([legDict[@"end_location"][@"lat"] doubleValue], [legDict[@"end_location"][@"lng"] doubleValue]);
            
            int strokeWidth = 8;
            UIColor *strokeColor;
            
            if (i % 4 == 0) {
                strokeWidth = 8;
                strokeColor = UIColorFromHex(0x2ECC71);
            }else if(i % 4 == 1){
                strokeWidth = 6;
                strokeColor = UIColorFromHex(0xe74c3c);
            }else if(i % 4 == 2){
                strokeWidth = 4;
                strokeColor = UIColorFromHex(0xf1c40f);
            }else if(i % 4 == 3){
                strokeWidth = 2;
                strokeColor = UIColorFromHex(0x47a1de);
            }
            
            GMSMutablePath *legPath = [GMSMutablePath path];
            
            route.totalDistance += [legDict[@"distance"][@"value"] intValue];
            route.totalDuration += [legDict[@"duration"][@"value"] intValue];
            
            NSArray *steps = legDict[@"steps"];
            NSUInteger stepSize = [steps count];
            
            leg.steps = [[NSMutableArray alloc] initWithCapacity:stepSize];
            
            for (int j = 0; j < stepSize; j++) {
                NSDictionary *stepDict = steps[j];
                
                DirectionStep *step = [[DirectionStep alloc] init];
                step.distance = stepDict[@"distance"][@"text"];
                step.duration = stepDict[@"duration"][@"text"];
                step.startLocation = CLLocationCoordinate2DMake([stepDict[@"start_location"][@"lat"] doubleValue], [stepDict[@"start_location"][@"lng"] doubleValue]);
                step.endLocation = CLLocationCoordinate2DMake([stepDict[@"end_location"][@"lat"] doubleValue], [stepDict[@"end_location"][@"lng"] doubleValue]);
                
                step.polyLine = stepDict[@"polyline"][@"points"];
                step.maneuver = [Constants getManeuverFromName:stepDict[@"maneuver"]];
                step.htmlInstructions = stepDict[@"html_instructions"];
                
                [leg.steps addObject:step];
                [route.allSteps addObject:step];
                
                GMSPath *polylinePath = [GMSPath pathFromEncodedPath:step.polyLine];
                
                for (int k = 0; k < polylinePath.count; k++) {
                    [legPath addCoordinate:[polylinePath coordinateAtIndex:k]];
                }
            }
            
            [route.legs addObject:leg];
            
            GMSPolyline *singleLine = [GMSPolyline polylineWithPath:legPath];
            singleLine.strokeWidth = strokeWidth;
            singleLine.strokeColor = strokeColor;
            singleLine.map = self.mapView;
            
            [navigationLines addObject:singleLine];
        }
        
        [self animateCameraToBoundAllMarkers];
        
        [((NavigationPanelVC*)self.panelContainerVC.panelViewController) updateNavigationDetailWithRoute:route];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Request error: %@", [error description]);
    }];
}

- (IBAction)onBtnMyLocationClick:(id)sender {
    [self animateCameraToMyLocation];
}

- (IBAction)onBtnSwapClick:(id)sender {
    if (!startMarker || !endMarker) {
        return;
    }
    
    NSString *tempAddress = self.tfStart.text;
    [self.tfStart setText:self.tfEnd.text];
    [self.tfEnd setText:tempAddress];
    
    CLLocationCoordinate2D tempPosition = startMarker.position;
    [self addStartMarkerWithLatitude:endMarker.position.latitude longitude:endMarker.position.longitude];
    [self addEndMarkerWithLatitude:tempPosition.latitude longitude:tempPosition.longitude];
    
    if (waypointMarkers.count > 1) {
        [UIAlertView showWithTitle:LString(@"notice") message:@"Do you want to reverse way-point markers order?" cancelButtonTitle:@"No" otherButtonTitles:@[@"Yes"] tapBlock:^(UIAlertView * _Nonnull alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                waypointMarkers = [[[waypointMarkers reverseObjectEnumerator] allObjects] mutableCopy];
                [self reorderWaypointMarkers];
            }
        }];
    }
}

- (IBAction)onBtnCalculateClick:(id)sender {
    if (!startMarker || !endMarker) {
        [self updateSnackBarMessage];
        return;
    }
    
    for (GMSPolyline *line in navigationLines) {
        line.map = nil;
    }
    [navigationLines removeAllObjects];
    
    [self drawDirectionFromStartPoint:startMarker throughtWaypoints:waypointMarkers toDestinationPoint:endMarker];
}

- (IBAction)onBtnClearClick:(id)sender {
    if (!startMarker && !endMarker){
        return;
    }
    
    [UIAlertView showWithTitle:@"Notice" message:@"Do you want to clear map and start over?" cancelButtonTitle:@"No" otherButtonTitles:@[@"Clear"] tapBlock:^(UIAlertView * _Nonnull alertView, NSInteger buttonIndex) {
        
        switch (buttonIndex) {
            case 0:
                break;
            case 1:
                [self.mapView clear];
                startMarker = nil;
                endMarker = nil;
                [waypointMarkers removeAllObjects];
                route = nil;
                [self.panelContainerVC closePanelControllerAnimated:YES completion:nil];
                
                self.tfStart.text = @"";
                self.tfEnd.text = @"";
                
                [self updateSnackBarMessage];
                break;
        }
    }];
}

- (void)shareText:(NSString *)text andImage:(UIImage *)image andUrl:(NSURL *)url {
    NSMutableArray *sharingItems = [NSMutableArray new];
    
    if (text) {
        [sharingItems addObject:text];
    }
    if (image) {
        [sharingItems addObject:image];
    }
    if (url) {
        [sharingItems addObject:url];
    }
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    if (IOS8_OR_LATER) {
        UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topController.presentedViewController && ![topController.presentedViewController isKindOfClass:[UIAlertController class]]) {
            topController = topController.presentedViewController;
        }
        
        UIView *superview = topController.view;
        activityController.popoverPresentationController.sourceView = superview;
    }
    [activityController setCompletionHandler:^(NSString *activityType, BOOL completed)
     {
        
     }];
    
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [self updateSnackBarMessage];
}

- (void) updateSnackBarMessage{
    return;
    if (snackBar) {
        [snackBar dismissAnimated:YES];
        return;
    }
    
    if (!startMarker) {
        snackBar = [SnackBar snackbarWithMessage:@"Long press to add start point marker" actionText:nil duration:DBL_MAX actionBlock:nil dismissalBlock:^(SnackBar *sender) {
            snackBar = nil;
            [self updateSnackBarMessage];
        }];
        [snackBar show:self];
        return;
    }
    
    if (!endMarker) {
        snackBar = [SnackBar snackbarWithMessage:@"Long press to add destination point marker" actionText:nil duration:DBL_MAX actionBlock:nil dismissalBlock:^(SnackBar *sender) {
            snackBar = nil;
            [self updateSnackBarMessage];
        }];
        [snackBar show:self];
        return;
    }
    
    if ([waypointMarkers count] == 0) {
        snackBar = [SnackBar snackbarWithMessage:@"Long press to add way-point marker (if need)" actionText:nil duration:DBL_MAX actionBlock:nil dismissalBlock:^(SnackBar *sender) {
            snackBar = nil;
            [self updateSnackBarMessage];
        }];
        [snackBar show:self];
        return;
    }
}

- (void) animateCameraToMyLocation{
    [self animateCameraToLatitude:self.mapView.myLocation.coordinate.latitude longitude:self.mapView.myLocation.coordinate.longitude zoom:DEFAULT_ZOOM_LEVEL];
}

- (void) animateCameraToLatitude:(CLLocationDegrees) latitude longitude:(CLLocationDegrees)longitude zoom:(int)zoom{
    CLLocationCoordinate2D myLocation = CLLocationCoordinate2DMake(latitude, longitude);
    GMSCameraUpdate *cameraUpdate = [GMSCameraUpdate setTarget:myLocation zoom:zoom];
    [self.mapView animateWithCameraUpdate:cameraUpdate];
}

- (void) animateCameraToBoundAllMarkers{
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:startMarker.position coordinate:startMarker.position];
    bounds = [bounds includingCoordinate:endMarker.position];
    
    for (GMSMarker *marker in waypointMarkers){
        bounds = [bounds includingCoordinate:marker.position];
    }
    
    [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds withPadding:100]];
}

- (void)animateCameraToBound:(CLLocationCoordinate2D)startLocation endLocation:(CLLocationCoordinate2D)endLocation{
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:startLocation coordinate:endLocation];
    [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds withPadding:50]];
}

- (void)highlightStep:(DirectionStep *)step{
    GMSPath *polylinePath = [GMSPath pathFromEncodedPath:step.polyLine];
    
    if (!highlightPolyline) {
        highlightPolyline = [GMSPolyline polylineWithPath:polylinePath];
        highlightPolyline.strokeWidth = 8;
        highlightPolyline.strokeColor = UIColorFromHex(0x9b59b6);
        highlightPolyline.map = self.mapView;
    }
    
    [highlightPolyline setPath:polylinePath];
}

- (IBAction)onTextFieldStartClick:(id)sender {
    currentSearchTextFieldType = START;
    [self showAutoCompleteViewController];
}

- (IBAction)onTextFieldEndClick:(id)sender {
    currentSearchTextFieldType = END;
    [self showAutoCompleteViewController];
}

- (void) showAutoCompleteViewController{
    GMSAutocompleteViewController *vc = [[GMSAutocompleteViewController alloc] init];
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController didAutocompleteWithPlace:(GMSPlace *)place{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    switch (currentSearchTextFieldType) {
        case START:
        {
            [self.tfStart setText:place.formattedAddress];
            [self addStartMarkerWithLatitude:place.coordinate.latitude longitude:place.coordinate.longitude];
        }
            break;
        case END:
        {
            [self.tfEnd setText:place.formattedAddress];
            [self addEndMarkerWithLatitude:place.coordinate.latitude longitude:place.coordinate.longitude];
        }
            break;
        case WAY_POINT:
        {
            if (currentSearchWaypointMarker) {
                [currentSearchWaypointMarker setPosition:place.coordinate];
                currentSearchWaypointMarker = nil;
            }
        }
            break;
        default:
            break;
    }
    
    [self animateCameraToLatitude:place.coordinate.latitude longitude:place.coordinate.longitude zoom:self.mapView.camera.zoom];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController didFailAutocompleteWithError:(NSError *)error{
    NSLog(@"Error: %@", [error description]);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)wasCancelled:(GMSAutocompleteViewController *)viewController{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didRequestAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didUpdateAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void) showLoading{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void) hideLoading{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)panelControllerChangedVisibilityState:(ARSPVisibilityState)state{
    switch (state) {
        case ARSPVisibilityStateMinimized:
        {
            [UIView animateWithDuration:0.3f animations:^{
                ((NavigationPanelVC*)(self.panelContainerVC.panelViewController)).ivHandle.transform = CGAffineTransformMakeScale(1, 1);
            }];
        }
            break;
        case ARSPVisibilityStateMaximized:
        {
            [UIView animateWithDuration:0.3f animations:^{
                ((NavigationPanelVC*)(self.panelContainerVC.panelViewController)).ivHandle.transform = CGAffineTransformMakeScale(1, -1);
            }];
        }
            break;
        default:
            break;
    }
}


@end
