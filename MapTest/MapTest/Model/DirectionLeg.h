//
//  DirectionLeg.h
//  MapTest
//
//  Created by Khoi Nguyen on 6/25/16.
//  Copyright © 2016 Khoi Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectionStep.h"
@import GoogleMaps;

@interface DirectionLeg : NSObject

@property (strong, nonatomic) NSString *distance;
@property (strong, nonatomic) NSString *duration;
@property (nonatomic) CLLocationCoordinate2D startLocation;
@property (nonatomic) CLLocationCoordinate2D endLocation;
@property (nonatomic) NSMutableArray<DirectionStep*> *steps;

@end
