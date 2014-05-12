//
//  AppDelegate.m
//  leyevent
//
//  Created by Nick Wroblewski on 5/6/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import "AppDelegate.h"
#import "ArcClient.h"
#import "PaymentManager.h"
#import <Crashlytics/Crashlytics.h>

UIColor *lettuceGreenColor;
BOOL isIos7;


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    lettuceGreenColor = [UIColor colorWithRed:146.0/255.0 green:164.0/255.0 blue:17.0/255.0 alpha:1.0];
    self.trackEventArray = [NSMutableArray array];

    
    [Crashlytics startWithAPIKey:@"c572f3260210edf4b81f7bef249c3083b8c3bc4b"];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    
    ArcClient *tmp = [[ArcClient alloc] init];
    [tmp sendTrackEvent:self.trackEventArray];
    
    self.trackEventArray = [NSMutableArray array];
    
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"customerToken"] length] > 0) {
        
        PaymentManager *tmp = [PaymentManager sharedInstance];
        [tmp getCreditCardList];
    }
    
    
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        isIos7 = YES;
    }else{
        isIos7 = NO;
    }
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


-(void)saveUserInfo{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setValue:self.appActions forKey:@"appActions"];
    [prefs setValue:self.appActionsTime forKey:@"appActionsTime"];
    [prefs synchronize];
}

-(void)handleCrashReport{
    
}


- (id)init {
    [rSkybox initiateSession];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    self.appActions = [prefs valueForKey:@"appActions"];
    self.appActionsTime = [prefs valueForKey:@"appActionsTime"];
    @try {
        if ([self.appActions length] > 0) {
            //Set the trace session array
            NSMutableArray *tmpTraceArray = [NSMutableArray arrayWithArray:[self.appActions componentsSeparatedByString:@","]];
            NSMutableArray *tmpTraceTimeArray = [NSMutableArray arrayWithArray:[self.appActionsTime componentsSeparatedByString:@","]];
            NSMutableArray *tmpDateArray = [NSMutableArray array];
            for (int i = 0; i < [tmpTraceTimeArray count]; i++) {
                NSString *tmpTime = [tmpTraceTimeArray objectAtIndex:i];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init]; [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"]; NSDate *theDate = [dateFormatter dateFromString:tmpTime];
                [tmpDateArray addObject:theDate];
            }
            [rSkybox setSavedArray:tmpTraceArray :tmpDateArray];
        }
    }
    @catch (NSException *exception) {
    }
    return self;
}

-(NSString *)getCustomerId{
    @try {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
        return [prefs valueForKey:@"customerId"];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcAppDelegate.getCustomerId" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        
    }
    
}

-(NSString *)getCustomerToken{
    @try {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
        return [prefs valueForKey:@"customerToken"];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcAppDelegate.getCustomerId" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        
    }
    
}

@end
