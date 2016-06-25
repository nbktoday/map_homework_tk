//
//  Constants.m
//  MapTest
//
//  Created by Khoi Nguyen on 6/25/16.
//  Copyright © 2016 Khoi Nguyen. All rights reserved.
//

#import "Constants.h"

@implementation Constants

+ (NSString *)getManeuverName:(MANEUVER)maneuver{
    NSString *name = @"";
    switch (maneuver) {
        case TURN_SHARP_LEFT:
            name = @"turn-sharp-left";
            break;
        case UTURN_RIGHT:
            name = @"uturn-right";
            break;
        case TURN_SLIGHT_RIGHT:
            name = @"turn-slight-right";
            break;
        case MERGE:
            name = @"merge";
            break;
        case ROUNDABOUT_LEFT:
            name = @"roundabout-left";
            break;
        case ROUNDABOUT_RIGHT:
            name = @"roundabout-right";
            break;
        case UTURN_LEFT:
            name = @"uturn-left";
            break;
        case TURN_SLIGHT_LEFT:
            name = @"turn-slight-left";
            break;
        case TURN_LEFT:
            name = @"turn-left";
            break;
        case RAMP_RIGHT:
            name = @"ramp-right";
            break;
        case TURN_RIGHT:
            name = @"turn-right";
            break;
        case FORK_RIGHT:
            name = @"fork-right";
            break;
        case STRAIGHT:
            name = @"straight";
            break;
        case FORK_LEFT:
            name = @"fork-left";
            break;
        case FERRY_TRAIN:
            name = @"ferry-train";
            break;
        case TURN_SHARP_RIGHT:
            name = @"turn-sharp-right";
            break;
        case RAMP_LEFT:
            name = @"ramp-left";
            break;
        case FERRY:
            name = @"ferry";
            break;
        case KEEP_LEFT:
            name = @"keep-left";
            break;
        case KEEP_RIGHT:
            name = @"keep-right";
            break;
        default:
            break;
    }
    return name;
}

+ (MANEUVER)getManeuverFromName:(NSString *)maneuverName{
    for (int i = 1; i < MANEUVER_COUNT; i++) {
        NSString *name = [self getManeuverName:(MANEUVER)i];
        if ([name isEqualToString:maneuverName]) {
            return (MANEUVER)i;
        }
    }
    return 0;
}

@end
