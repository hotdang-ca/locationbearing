//
//  LocationManager.h
//  HelloBearing
//
//  Created by James Perih on 2016-11-05.
//  Copyright © 2016 Hot Dang Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationManager : NSObject

@property (nonatomic, readonly) CLLocationDirection lastDirection;
@property (nonatomic, readonly) CLLocationSpeed lastSpeed;
@property (nonatomic, readonly) CLLocationCoordinate2D lastCoordinates;
@property (nonatomic, readonly) BOOL isMonitoringLocationUpdates;

@property (strong, nonatomic, readonly) NSString *lastCurrentStreet;
@property (strong, nonatomic, readonly) NSString *lastNearStreet;


+(instancetype)sharedManager;
-(void)startCourseUpdates;
-(void)stopCourseUpdates;

@end
