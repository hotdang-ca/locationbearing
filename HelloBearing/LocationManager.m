//
//  LocationManager.m
//  HelloBearing
//
//  Created by James Perih on 2016-11-05.
//  Copyright © 2016 Hot Dang Interactive. All rights reserved.
//

#import "LocationManager.h"
#import <CoreLocation/CoreLocation.h>
#define DESIRED_HORIZONTAL_ACCURACY 50.0
#define DESIRED_LOCATION_AGE 15.0

@interface LocationManager() <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *usefulLocations;

@property (nonatomic, readwrite) CLLocationDirection lastDirection;
@property (nonatomic, readwrite) CLLocationSpeed lastSpeed;
@property (nonatomic, readwrite) CLLocationCoordinate2D lastCoordinates;
@property (nonatomic, readwrite) BOOL isMonitoringLocationUpdates;

@end

@implementation LocationManager

+(instancetype)sharedManager {
    static LocationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[LocationManager alloc] init];
        manager.isMonitoringLocationUpdates = NO;
    });
    
    return manager;
}

-(void)startCourseUpdates {
    if (! [CLLocationManager locationServicesEnabled]) {
        return;
    }

    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        [_locationManager requestWhenInUseAuthorization];
        return;
    }
    
    // we're all good, let's boot up!
    _locationManager.distanceFilter = 5;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    
    [_locationManager startUpdatingLocation];
    
    [self willChangeValueForKey:@"isMonitoringLocationUpdates"];
    _isMonitoringLocationUpdates = YES;
    [self didChangeValueForKey:@"isMonitoringLocationUpdates"];
}

-(void)stopCourseUpdates {
    [_locationManager stopUpdatingLocation];
    
    [self willChangeValueForKey:@"isMonitoringLocationUpdates"];
    _isMonitoringLocationUpdates = NO;
    [self didChangeValueForKey:@"isMonitoringLocationUpdates"];
}
/**
 * Called when location services authorization status has changed
 *
 */
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [self startCourseUpdates];
    }
}

/**
 * Update received from the location services manager
 */
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    if (!_usefulLocations) {
        _usefulLocations = [[NSMutableArray alloc] init];
    }
    _usefulLocations = [self arrayOfUsefulLocationsWithLocations:locations];
    
    CLLocation *lastLocation = [_usefulLocations lastObject];
    if ([_usefulLocations count] > 0) {
        
        if (_lastDirection != lastLocation.course) {
            [self willChangeValueForKey:@"lastDirection"];
            _lastDirection = lastLocation.course;
            [self didChangeValueForKey:@"lastDirection"];
        }
        
        if (_lastSpeed != lastLocation.speed) {
            [self willChangeValueForKey:@"lastSpeed"];
            _lastSpeed = lastLocation.speed;
            [self didChangeValueForKey:@"lastSpeed"];
        }
        
        if (_lastCoordinates.latitude != lastLocation.coordinate.latitude && _lastCoordinates.longitude != lastLocation.coordinate.longitude) {
            [self willChangeValueForKey:@"lastCoordinates"];
            _lastCoordinates = lastLocation.coordinate;
            [self didChangeValueForKey:@"lastCoordinates"];
        }
        
    }
    
    // TODO: get and package the location info for this location
    
}

-(NSMutableArray *)arrayOfUsefulLocationsWithLocations:(NSArray <CLLocation *> *)locations {
    NSMutableArray *usefulLocations = [[NSMutableArray alloc] init];
    for (CLLocation *location in locations) {
        if ([self ageOfLocationUpdate:location] < DESIRED_LOCATION_AGE) {
            if (location.horizontalAccuracy < DESIRED_HORIZONTAL_ACCURACY) {
                [usefulLocations addObject:location];
            }
        }
    }
    
    return usefulLocations;
}

/**
 * Helper method to extract the age of a CLLocation object
 *
 */
-(float)ageOfLocationUpdate:(CLLocation *)location {
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    return fabs(howRecent);
}

@end
