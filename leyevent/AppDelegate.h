//
//  AppDelegate.h
//  leyevent
//
//  Created by Nick Wroblewski on 5/6/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "rSkybox.h"

extern UIColor *lettuceGreenColor;
extern BOOL isIos7;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


@property (nonatomic, strong) NSString *appActions;
@property (nonatomic, strong) NSString *appActionsTime;
@property (nonatomic, strong) NSString *crashSummary;
@property (nonatomic, strong) NSString *crashUserName;
@property (nonatomic, strong) NSDate *crashDetectDate;
@property (nonatomic, strong) NSData *crashStackData;
@property (nonatomic, strong) NSString *crashInstanceUrl;
-(void)saveUserInfo;
-(void)handleCrashReport;

@property (nonatomic, strong) NSMutableArray *trackEventArray;
-(NSString *)getCustomerId;
-(NSString *)getCustomerToken;


@end
