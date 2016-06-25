//
//  Constants.h
//  MapTest
//
//  Created by Khoi Nguyen on 6/25/16.
//  Copyright © 2016 Khoi Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GOOLE_MAPS_API_KEY @"AIzaSyDc840btzIKFtp2UO89zHNiWrDxuRcNgd0"
#define APP_ID @"1086641897"


#define DIRECTION_API_KEY @"AIzaSyAuis_ySm1f5YndBAV0RLzuckNfWm_CmTw"
#define DIRECTION_API_URL @"https://maps.googleapis.com/maps/api/directions/json?origin=%f,%f&waypoints=%@&destination=%f,%f&language=%@&key=%@"

#define DIRECTION_PICTURE_API_URL @"https://maps.googleapis.com/maps/api/staticmap?size=%@&scale=%d&markers=%@&markers=%@&markers=%@&path=%@&key=%@"

#define GEOCODE_API_URL @"http://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&amp;sensor=false"

#define DEFAULT_ZOOM_LEVEL 16

#define IOS8_OR_LATER [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0

#define UIColorFromHex(hexValue) \
[UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0 \
green:((float)((hexValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((hexValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]

#define LString(key) NSLocalizedString(key, nil)

typedef enum MANEUVER : NSUInteger {
    
    TURN_SHARP_LEFT = 1,
    UTURN_RIGHT,
    TURN_SLIGHT_RIGHT,
    MERGE,
    ROUNDABOUT_LEFT,
    ROUNDABOUT_RIGHT,
    UTURN_LEFT,
    TURN_SLIGHT_LEFT,
    TURN_LEFT,
    RAMP_RIGHT,
    TURN_RIGHT,
    FORK_RIGHT,
    STRAIGHT,
    FORK_LEFT,
    FERRY_TRAIN,
    TURN_SHARP_RIGHT,
    RAMP_LEFT,
    FERRY,
    KEEP_LEFT,
    KEEP_RIGHT,
    
    MANEUVER_COUNT
    
}MANEUVER;

@interface Constants : NSObject

+ (NSString*) getManeuverName:(MANEUVER)maneuver;
+ (MANEUVER) getManeuverFromName:(NSString*)maneuverName;

@end
