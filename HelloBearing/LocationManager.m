//
//  LocationManager.m
//  HelloBearing
//
//  Created by James Perih on 2016-11-05.
//  Copyright © 2016 Hot Dang Interactive. All rights reserved.
//

#import "LocationManager.h"
#import <CoreLocation/CoreLocation.h>
#define DESIRED_HORIZONTAL_ACCURACY 15.0
#define DESIRED_LOCATION_AGE 15.0
#define DESIRED_NEAR_STREET_DISTANCE 25.0

@interface LocationManager() <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLGeocoder *geocoder;

@property (strong, nonatomic) NSMutableArray *usefulLocations;

@property (strong, nonatomic, readwrite) NSString *lastCurrentStreet;
@property (strong, nonatomic, readwrite) NSString *lastNearStreet;

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
            
            [self getAddressFromLocation:lastLocation];
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

-(void) getAddressFromLocation:(CLLocation *)location {
    if (!self.geocoder) {
        self.geocoder = [[CLGeocoder alloc] init];
    }
    
//    CLLocationCoordinate2D upLeftCoord = [self locationWithBearing:360.0-45.0 distance:5 fromLocation:location.coordinate];
//    CLLocation *locUpLeft = [[CLLocation alloc] initWithLatitude:upLeftCoord.latitude longitude:upLeftCoord.longitude];
//    

    CLLocationCoordinate2D upRightCoord = [self locationWithBearing:(_lastDirection + 15) distance:DESIRED_NEAR_STREET_DISTANCE fromLocation:location.coordinate];
    CLLocation *locUpRight = [[CLLocation alloc] initWithLatitude:upRightCoord.latitude longitude:upRightCoord.longitude];
    
    [_geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
         if(placemarks && placemarks.count > 0) {

             CLPlacemark *lastPlacemark = [placemarks firstObject];
             
             if ([lastPlacemark.thoroughfare isEqualToString:_lastCurrentStreet]) {
                 NSLog(@"No change to current street.");
             } else {
                 NSLog(@"Probably on %@", lastPlacemark.thoroughfare);
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self willChangeValueForKey:@"lastCurrentStreet"];
                     _lastCurrentStreet = lastPlacemark.thoroughfare;
                     [self didChangeValueForKey:@"lastCurrentStreet"];
                 });
             }
             

             // only seem to be able to geocode one of these
             dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                 [self geocodeRightOf:locUpRight comparedTo:lastPlacemark];
             });
         }
    }];
}

- (void)geocodeLeftOf:(CLLocation *)leftLocation comparedTo:(CLPlacemark *)lastPlacemark {
    
    [_geocoder reverseGeocodeLocation:leftLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        if (placemarks && placemarks.count > 0) {
            CLPlacemark *leftPlacemark = [placemarks firstObject];
            
            if (! [leftPlacemark.thoroughfare isEqualToString:lastPlacemark.thoroughfare]) {
                NSLog(@"Different UpLeft Location: %@", leftPlacemark.thoroughfare);
            } else {
                NSLog(@"left ahead Same as current");
            }
        }
    }];
}

- (void)geocodeRightOf:(CLLocation *)rightLocation comparedTo:(CLPlacemark *)lastPlacemark {
    
    [_geocoder reverseGeocodeLocation:rightLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        if (placemarks && placemarks.count > 0) {
            CLPlacemark *rightPlacemark = [placemarks firstObject];
            
            if (! [rightPlacemark.thoroughfare isEqualToString:lastPlacemark.thoroughfare]) { // it's not the same as the current street
                
                if ([rightPlacemark.thoroughfare isEqualToString:_lastNearStreet]) {
                    NSLog(@"Same near street") ;
                } else if (rightPlacemark.thoroughfare == nil) {
                    NSLog(@"couldn't get the thoroughfare");
                } else { // it's not the same as the last street
                    NSLog(@"Different UpRight Location: %@", rightPlacemark.thoroughfare);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self willChangeValueForKey:@"lastNearStreet"];
                        _lastNearStreet = rightPlacemark.thoroughfare;
                        [self didChangeValueForKey:@"lastNearStreet"];
                    });
                    
                }
            } else {
                NSLog(@"Right ahead Same as current");
            }
        }
    }];
}

- (CLLocationCoordinate2D) locationWithBearing:(float)bearing distance:(float)distanceMeters fromLocation:(CLLocationCoordinate2D)origin {
    CLLocationCoordinate2D target;
    const double distRadians = distanceMeters / (6372797.6); // earth radius in meters
    
    float lat1 = origin.latitude * M_PI / 180;
    float lon1 = origin.longitude * M_PI / 180;
    
    float lat2 = asin( sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing));
    float lon2 = lon1 + atan2( sin(bearing) * sin(distRadians) * cos(lat1),
                              cos(distRadians) - sin(lat1) * sin(lat2) );
    
    target.latitude = lat2 * 180 / M_PI;
    target.longitude = lon2 * 180 / M_PI; // no need to normalize a heading in degrees to be within -179.999999° to 180.00000°
    
    return target;
}
@end
