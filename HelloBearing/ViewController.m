//
//  ViewController.m
//  HelloBearing
//
//  Created by James Perih on 2016-11-05.
//  Copyright © 2016 Hot Dang Interactive. All rights reserved.
//

#import "ViewController.h"

#import "LocationManager.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *courseLabel;
@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastStreetLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastCrossStreetLabel;

@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@end

@implementation ViewController

static void *LocationSpeedContext = &LocationSpeedContext;
static void *LocationCourseContext = &LocationCourseContext;
static void *LocationPositionContext = &LocationPositionContext;
static void *LocationIsMonitoringContext = &LocationIsMonitoringContext;
static void *LocationLastCurrentStreet = &LocationLastCurrentStreet;
static void *LocationLastCrossStreet = &LocationLastCrossStreet;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self registerAsObservers];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)registerAsObservers {
    [[LocationManager sharedManager]
     addObserver:self
     forKeyPath:@"lastSpeed"
     options:NSKeyValueObservingOptionNew
     context:LocationSpeedContext];
    
    [[LocationManager sharedManager]
     addObserver:self
     forKeyPath:@"lastDirection"
     options:NSKeyValueObservingOptionNew
     context:LocationCourseContext];
    
    [[LocationManager sharedManager] addObserver:self forKeyPath:@"lastCoordinates" options:NSKeyValueObservingOptionNew context:LocationPositionContext];
    
    [[LocationManager sharedManager] addObserver:self forKeyPath:@"isMonitoringLocationUpdates" options:NSKeyValueObservingOptionNew context:LocationIsMonitoringContext];
    
    [[LocationManager sharedManager] addObserver:self forKeyPath:@"lastCurrentStreet" options:NSKeyValueObservingOptionNew context:LocationLastCurrentStreet];
    
    [[LocationManager sharedManager] addObserver:self forKeyPath:@"lastNearStreet" options:NSKeyValueObservingOptionNew context:LocationLastCrossStreet];
    
}

- (void)removeObservers {
    [[LocationManager sharedManager] removeObserver:self forKeyPath:@"lastSpeed" context:LocationSpeedContext];
    [[LocationManager sharedManager] removeObserver:self forKeyPath:@"lastDirection" context:LocationCourseContext];
    [[LocationManager sharedManager] removeObserver:self forKeyPath:@"lastCoordinates" context:LocationPositionContext];
    [[LocationManager sharedManager] removeObserver:self forKeyPath:@"lastCurrentStreet" context:LocationLastCurrentStreet];
    [[LocationManager sharedManager] removeObserver:self forKeyPath:@"lastNearStreet" context:LocationLastCrossStreet];
}

/**
 * Gives N/S/E/W or combination, based on degrees provided
 */
- (NSString *)directionNameFromCompassValue:(CGFloat)compassValue {
    NSString *directionName = [NSString string];
    
    if (compassValue >= 0 && compassValue < 22.5) {
        directionName = @"N";
    } else if (compassValue >= 22.5 && compassValue < 67.5) {
        directionName = @"NE";
    } else if (compassValue >= 67.5 && compassValue < 112.5) {
        directionName = @"E";
    } else if (compassValue >= 112.5 && compassValue < 157.5) {
        directionName = @"SE";
    } else if (compassValue >= 157.5 && compassValue < 202.5) {
        directionName = @"S";
    } else if (compassValue >= 202.5 && compassValue < 247.5) {
        directionName = @"SW";
    } else if (compassValue >= 247.5 && compassValue < 292.5) {
        directionName = @"W";
    } else if (compassValue >= 292.5 && compassValue < 337.5) {
        directionName = @"NW";
    } else if (compassValue > 337.5) {
        directionName = @"N";
    } else if (compassValue < 0) {
        directionName = @"?";
    }
    
    return directionName;
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == LocationPositionContext) {
        _latitudeLabel.text = [NSString stringWithFormat:@"%@", @([LocationManager sharedManager].lastCoordinates.latitude)];
        _longitudeLabel.text = [NSString stringWithFormat:@"%@", @([LocationManager sharedManager].lastCoordinates.longitude)];
        
    } else if (context == LocationCourseContext) {
        NSString *directionName = [self directionNameFromCompassValue:[LocationManager sharedManager].lastDirection];
        _courseLabel.text = [NSString stringWithFormat:@"%@ (%@°)", directionName, @([LocationManager sharedManager].lastDirection)];
        
    } else if (context == LocationSpeedContext) {
        _speedLabel.text = [NSString stringWithFormat:@"%@m/s", @([LocationManager sharedManager].lastSpeed)];
    } else if (context == LocationIsMonitoringContext) {
        [_startStopButton setTitle:[LocationManager sharedManager].isMonitoringLocationUpdates ? @"Stop Course Updates" : @"Start Course Updates" forState:UIControlStateNormal];
    } else if (context == LocationLastCurrentStreet) {
        _lastStreetLabel.text = [LocationManager sharedManager].lastCurrentStreet;
        
    } else if (context == LocationLastCrossStreet) {
        _lastCrossStreetLabel.text = [LocationManager sharedManager].lastNearStreet;
        
    }
    else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

-(IBAction)startStopPressed:(id)sender {
    if ([[LocationManager sharedManager] isMonitoringLocationUpdates]) {
        // already monitoring. Unmonitor
        
        [[LocationManager sharedManager] stopCourseUpdates];
    } else {
        // not monitoring. start monitoring
        [[LocationManager sharedManager] startCourseUpdates];
    }
}
@end
