//
//  DirectionStep.m
//  MapTest
//
//  Created by Khoi Nguyen on 6/25/16.
//  Copyright © 2016 Khoi Nguyen. All rights reserved.
//

#import "DirectionStep.h"

@implementation DirectionStep

- (instancetype)init{
    if (self = [super init]) {
        self.maneuver = STRAIGHT;
    }
    return self;
}

@end
