//
//  rSkybox.h
//  rTeam
//
//  Created by Nick Wroblewski on 4/30/12.
//  Copyright (c) 2012 Stretch Computing, Inc. All rights reserved.
//

/*
 @try {
 }
 @catch (NSException *e) {
 [rSkybox sendClientLog:@"initManagedDocument" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
 }
 
 */

#import <Foundation/Foundation.h>


extern NSString *const ARC_VERSION_NUMBER;
extern NSString *const SUCCESS;
extern NSString *const NAME_ALREADY_IN_USE;


typedef enum {
    CreateStream = 0,
    CreatePacket = 1,
    CloseStream = 2
} RSKYBOX_APIS;


@interface rSkybox : NSObject <NSURLConnectionDelegate> {
}


//rSkybox server communication methods
+ (void)createEndUser;
+(void)sendClientLog:(NSString *)logName logMessage:(NSString *)logMessage logLevel:(NSString *)logLevel exception:(NSException *)exception;
+(void)sendCrashDetect:(NSString *)summary theStackData:(NSData *)stackData;
+(void)sendFeedback:(NSData *)recordedData;

+(void)startThreshold:(NSString *)logName;
+(void)endThreshold:(NSString *)logName logMessage:(NSString *)logMessage maxValue:(double)maxValue;


//App Actions Methods
+(void)initiateSession;
+(void)addEventToSession:(NSString *)event;
+(void)printTraceSession;
+(NSMutableArray *)getActions;
+(NSMutableArray *)getTimestamps;
+(void)setSavedArray:(NSMutableArray *)savedArray :(NSMutableArray *)savedArrayTime;

//Base64 Encoder methods
+ (NSString *)encodeBase64data:(NSData *)encodeData;
+ (NSString *)encodeBase64:(NSString *)stringToEncode;
+ (NSString *)getBasicAuthHeader;

// LiveDebug Methods
+(void)createStream:(NSString *)name;
+(void)createPacket:(NSString *)packet;
+(void)closeStream:(NSString *)name;
+(NSString *)getActiveStream;

@end