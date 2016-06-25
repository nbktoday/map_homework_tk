//
//  DirectionRoute.h
//  MapTest
//
//  Created by Khoi Nguyen on 6/25/16.
//  Copyright © 2016 Khoi Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectionLeg.h"
@import GoogleMaps;

@interface DirectionRoute : NSObject

@property (nonatomic) CLLocation *northeast;
@property (nonatomic) CLLocation *southwest;
@property (nonatomic) NSMutableArray<DirectionLeg*> *legs;
@property (strong, nonatomic) NSString *overviewPolyline;
@property (strong, nonatomic) NSString *viaSummary;
@property (nonatomic) int totalDistance;
@property (nonatomic) int totalDuration;
@property (nonatomic) NSMutableArray<DirectionStep*> *allSteps;

@end
