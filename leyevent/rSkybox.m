//
//  rSkybox.m
//  rTeam
//
//  Created by Nick Wroblewski on 4/30/12.
//  Extend by Joe Wroblewski on 4/13/13
//  Copyright (c) 2012 Stretch Computing, Inc. All rights reserved.
//


#import "rSkybox.h"
#import "SBJson.h"
#import "UIDevice-Hardware.h"
#import "Encoder.h"
#import "AppDelegate.h"
#import "ArcClient.h"

static NSString *basicAuthUserName = @"token";
static NSString *baseUrl = @"https://rskybox-stretchcom.appspot.com/rest/v1";
//TODO: rSkybox ids - replace the current basicAuthToken and applicationId with the token and application id you
//      received when you registered for rSkybox
static NSString *basicAuthToken = @"ekokq167k46gbrmr6hvbht9lab";
static NSString *applicationId = @"ahRzfnJza3lib3gtc3RyZXRjaGNvbXITCxILQXBwbGljYXRpb24YgPYvDA";

//Maximum number of App Actions to save
#define NUMBER_EVENTS_STORED 40


static NSMutableArray *traceSession;
static NSMutableArray *traceTimeStamps;
static NSDate *startTime;
static NSString *logNameBeingTimed;
static BOOL isLiveDebugActive = FALSE;
static RSKYBOX_APIS api;
static NSMutableData *serverData;
static int httpStatusCode;
static NSString *streamId;
static NSString *streamName;


NSString* const ARC_VERSION_NUMBER = @"1.0";

NSString *const SUCCESS = @"100";
NSString *const INVALID_STATUS = @"201";
NSString *const USER_NOT_AUTHORIZED_FOR_APPLICATION = @"203";
NSString *const APPLICATION_NOT_AUTHORIZED = @"221";
NSString *const NAME_ALREADY_IN_USE = @"224";
NSString *const STREAM_CLOSED = @"225";
NSString *const APPLICATION_ID_REQUIRED = @"305";
NSString *const STREAM_ID_REQUIRED = @"323";
NSString *const EITHER_USER_ID_OR_MEMBER_ID_IS_REQUIRED = @"324";
NSString *const NAME_IS_REQUIRED = @"325";
NSString *const BODY_REQUIRED = @"326";
NSString *const STREAM_ALREADY_HAS_END_USER = @"427";
NSString *const STREAM_ALREADY_HAS_MEMBER = @"428";
NSString *const BOTH_USER_ID_AND_MEMBER_ID_SPECIFIED = @"429";
NSString *const APPLICATION_NOT_FOUND = @"605";
NSString *const STREAM_NOT_FOUND = @"605";


NSString *const CLOSED_STATUS = @"closed";


@implementation rSkybox

+ (NSString *)getUserId{
    //TODO: rSkybox userId - return instead a uniqiue identifier for this user
    
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"customerEmail"] length] > 0) {
        return [[NSUserDefaults standardUserDefaults] valueForKey:@"customerEmail"];
        
    }else{
        NSString *guestId = [[NSUserDefaults standardUserDefaults] valueForKey:@"guestId"];
        NSString *guestToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"guestToken"];
        
        if (![guestId isEqualToString:@""] && (guestId != nil) && ![guestToken isEqualToString:@""] && (guestToken != nil)) {
            return [[NSUserDefaults standardUserDefaults] valueForKey:@"guestId"];
        }
        
    }
    return @"unknown";
}

+ (void)createEndUser{
    
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionary];
    NSString *statusReturn = @"";
    
    
    @try {
        
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *loginDict = [[NSDictionary alloc] init];
        
        [tempDictionary setObject:[rSkybox getUserId] forKey:@"userId"];
        [tempDictionary setObject:@"ARC" forKey:@"application"];
        [tempDictionary setObject:ARC_VERSION_NUMBER forKey:@"version"];
        
        
        
        loginDict = tempDictionary;
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDict JSONRepresentation], nil];
        
        NSString *tmpUrl = [baseUrl stringByAppendingFormat:@"/applications/%@/endUsers", applicationId];
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:tmpUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *basicAuth = [rSkybox getBasicAuthHeader];
        
        
        [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
        
        //   NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        //   if (connection) {
        
        // }
        
        //
        NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil ];
        
        // parse the returned JSON object
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding: NSUTF8StringEncoding];
        
        //NSLog(@"ReturnString: %@", returnString);
        
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *response = (NSDictionary *) [jsonParser objectWithString:returnString error:NULL];
        
        NSString *apiStatus = [response valueForKey:@"apiStatus"];
        if ([apiStatus isEqualToString:@"100"]) {
            //NSLog(@"Create End User Failed");
        }
        //
        //        statusReturn = apiStatus;
        //        [returnDictionary setValue:statusReturn forKey:@"status"];
        //        return returnDictionary;
    }
    
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.createEndUser - %@ - %@", [e name], [e description]);
        statusReturn = @"1";
        [returnDictionary setValue:statusReturn forKey:@"status"];
    }
}


+(void)startThreshold:(NSString *)logName {
    @try {
        startTime = [NSDate date];
        logNameBeingTimed = logName;
    }
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.startThreshold - %@ - %@", [e name], [e description]);
    }
}

+(void)endThreshold:(NSString *)logName logMessage:(NSString *)logMessage maxValue:(double)maxValue {
    @try {
        NSTimeInterval milliseconds = [[NSDate date] timeIntervalSinceDate:startTime] * 1000;
        
        if(milliseconds > maxValue && ![logName isEqualToString:@"ErrorEncountered"]) {
            NSString *logMessage = [NSString stringWithFormat:@"threshold: %0.0f ms latency: %0.0f ms", maxValue, milliseconds];
            NSLog(@"%@", logMessage);
            // deactivate thresshold reporting for now
        }
        //NSLog(@"Duration of %@: %0.1f", logName, milliseconds);
    }
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.endThreshold - %@ - %@", [e name], [e description]);
    }
}

+(void)sendClientLog:(NSString *)logName logMessage:(NSString *)logMessage logLevel:(NSString *)logLevel exception:(NSException *)exception{
    
    return;
    @try {

        
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *loginDict = [[NSDictionary alloc] init];
        
        //Fill parameter dictionary from input method parameters
        [tempDictionary setObject:logName  forKey:@"logName"];
        [tempDictionary setObject:logLevel forKey:@"logLevel"];
        
        if (exception) {
            logMessage = [logMessage stringByAppendingFormat:@" - %@ - %@", [exception name], [exception description]];
        }
        [tempDictionary setObject:logMessage forKey:@"message"];
        
        [tempDictionary setObject:[rSkybox getUserId] forKey:@"userId"];
        
        //HardCoded at top of page
        [tempDictionary setObject:ARC_VERSION_NUMBER forKey:@"version"];
        
        //Get the device and platform information, and add to a summary string
        float version = [[[UIDevice currentDevice] systemVersion] floatValue];
        NSString *platform = [[UIDevice currentDevice] platformString];
        NSString *summaryString = [NSString stringWithFormat:@"iOS Version: %f, Device: %@, App Version: %@", version, platform, ARC_VERSION_NUMBER];
        [tempDictionary setObject:summaryString forKey:@"summary"];
        
        //Send in the current date
        NSDate *today = [NSDate date];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        NSString *dateString = [dateFormat stringFromDate:today];
        
        [tempDictionary setObject:dateString forKey:@"date"];
        
        //If its an exception, send in the stackBackTrace in an array
        
        if (exception != nil) {
            NSMutableArray *stackTraceArray = [NSMutableArray array];
            NSArray *stackSymbols = [exception callStackSymbols];
            if(stackSymbols) {
                for (NSString *str in stackSymbols) {
                    
                    [stackTraceArray addObject:str];
                    
                }
            }
            
            [tempDictionary setObject:stackTraceArray  forKey:@"stackBackTrace"];
        }
        
        //Adding the App Actions
        NSMutableArray *finalArray = [NSMutableArray array];
        NSMutableArray *appActions = [NSMutableArray arrayWithArray:[rSkybox getActions]];
        NSMutableArray *appTimestamps = [NSMutableArray arrayWithArray:[rSkybox getTimestamps]];
        
        @try {
            for (int i = 0; i < [appActions count]; i++) {
                
                NSString *appAction = [appActions objectAtIndex:i];
                
                NSMutableDictionary *actDictionary = [NSMutableDictionary dictionary];
                
                [actDictionary setObject:appAction forKey:@"description"];
                
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
                NSString *dateString = [dateFormat stringFromDate:[appTimestamps objectAtIndex:i]];
                
                
                [actDictionary setObject:dateString forKey:@"timestamp"];
                
                
                [finalArray addObject:actDictionary];
                
            }
        }
        @catch (NSException *exception) {
            
        }
      
    
        
        [tempDictionary setObject:finalArray forKey:@"appActions"];
        
        //endpoints
        ArcClient *tmp = [[ArcClient alloc] init];
        
        [tempDictionary setValue:[tmp getRemoteEndpoint] forKey:@"remoteEndpoint"];
        [tempDictionary setValue:[tmp getLocalEndpoint] forKey:@"localEndpoint"];

            
        loginDict = tempDictionary;
        
        //Make the call to the server
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDict JSONRepresentation], nil];
                        
        NSString *tmpUrl = [baseUrl stringByAppendingFormat:@"/applications/%@/clientLogs", applicationId];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:tmpUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *basicAuth = [rSkybox getBasicAuthHeader];
        
        //NSLog(@"Basic Auth: %@", basicAuth);
        
        [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
        
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if (connection) {
        }
        
        
            //    NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil ];
        
            // parse the returned JSON object
           //     NSString *returnString = [[NSString alloc] initWithData:returnData encoding: NSUTF8StringEncoding];
        
       // NSLog(@"Return: %@", returnString);
       // NSLog(@"TEST");
        
        //        SBJsonParser *jsonParser = [SBJsonParser new];
        //        NSDictionary *response = (NSDictionary *) [jsonParser objectWithString:returnString error:NULL];
        //
        //        NSString *logStatus = [response valueForKey:@"logStatus"];
        //        NSString *apiStatus = [response valueForKey:@"apiStatus"];
        //
        //        if (![apiStatus isEqualToString:@"100"]) {
        //            //NSLog(@"Send Client Log Failed.");
        //        }
        //
        //
        //        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        //        NSMutableDictionary *logChecklist = [NSMutableDictionary dictionaryWithDictionary:[standardUserDefaults valueForKey:@"logChecklist"]];
        //
        //        //If the log is b
        //        if ([logStatus isEqualToString:@"inactive"]) {
        //
        //            [logChecklist setObject:@"off" forKey:logName];
        //            [standardUserDefaults setObject:logChecklist forKey:@"logChecklist"];
        //        }
        
        
    }
    
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.endThreshold - %@ - %@", [e name], [e description]);
        NSLog(@"Test");
    }
}


+ (void)sendCrashDetect:(NSString *)summary theStackData:(NSData *)stackData{

    
    @try {
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *loginDict = [[NSDictionary alloc] init];
        
        [tempDictionary setObject:summary forKey:@"summary"];
        
        [tempDictionary setObject:@"dutch Crash" forKey:@"eventName"];
        
        
        [tempDictionary setObject:[rSkybox getUserId] forKey:@"userId"];
        [tempDictionary setObject:ARC_VERSION_NUMBER forKey:@"version"];
        
        
        NSDate *today = [NSDate date];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        NSString *dateString = [dateFormat stringFromDate:today];
        
        [tempDictionary setObject:dateString forKey:@"date"];
        
        
        
        if(stackData) {
            // stackData is hex and needs to be base64 encoded before packaged inside JSON
            NSString *encodedStackData = [rSkybox encodeBase64data:stackData];
            [tempDictionary setObject:encodedStackData forKey:@"stackData"];
        }
        
        //Adding the last 20 actions
        NSMutableArray *finalArray = [NSMutableArray array];
        NSMutableArray *appActions = [NSMutableArray arrayWithArray:[rSkybox getActions]];
        NSMutableArray *appTimestamps = [NSMutableArray arrayWithArray:[rSkybox getTimestamps]];
        
        
        @try {
            for (int i = 0; i < [appActions count]; i++) {
                NSMutableDictionary *actDictionary = [NSMutableDictionary dictionary];
                
                [actDictionary setObject:[appActions objectAtIndex:i] forKey:@"description"];
                
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
                NSString *dateString = [dateFormat stringFromDate:[appTimestamps objectAtIndex:i]];
                
                [actDictionary setObject:dateString forKey:@"timestamp"];
                
                [finalArray addObject:actDictionary];
                
            }
        }
        @catch (NSException *exception) {
            
        }
      
      
        
        [tempDictionary setObject:finalArray forKey:@"appActions"];
        
        loginDict = tempDictionary;
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDict JSONRepresentation], nil];
        
        NSString *tmpUrl = [baseUrl stringByAppendingFormat:@"/applications/%@/crashDetects", applicationId];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:tmpUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *basicAuth = [rSkybox getBasicAuthHeader];
        
        [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
        
        //NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        // if (connection) {
        
        // }
        
        
        NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil ];
        
        // parse the returned JSON object
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding: NSUTF8StringEncoding];
        
        
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *response = (NSDictionary *) [jsonParser objectWithString:returnString error:NULL];
        
        NSString *apiStatus = [response valueForKey:@"apiStatus"];
        if (![apiStatus isEqualToString:@"100"]) {
            // NSLog(@"Send Crash Failed.");
        }
        
        
    }
    
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.sendCrashDetect - %@ - %@", [e name], [e description]);
    }
}



+(void)sendFeedback:(NSData *)recordedData{
    
    @try {
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *loginDict = [[NSDictionary alloc] init];
        
        
        NSString *encodedRecordedData = [rSkybox encodeBase64data:recordedData];
        
        [tempDictionary setObject:encodedRecordedData forKey:@"voice"];
        
        [tempDictionary setObject:[rSkybox getUserId] forKey:@"userId"];
        [tempDictionary setObject:[rSkybox getUserId] forKey:@"userName"];
        
        [tempDictionary setObject:ARC_VERSION_NUMBER forKey:@"version"];
        
        NSDate *today = [NSDate date];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        NSString *dateString = [dateFormat stringFromDate:today];
        
        [tempDictionary setObject:dateString forKey:@"date"];
        
        ArcClient *tmp = [[ArcClient alloc] init];
        
        [tempDictionary setValue:[tmp getRemoteEndpoint] forKey:@"remoteEndpoint"];
        [tempDictionary setValue:[tmp getLocalEndpoint] forKey:@"localEndpoint"];
        
        
        
        loginDict = tempDictionary;
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDict JSONRepresentation], nil];
        
        NSString *tmpUrl = [baseUrl stringByAppendingFormat:@"/applications/%@/feedback", applicationId];
        
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:tmpUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *basicAuth = [rSkybox getBasicAuthHeader];
        [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
        
        //    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        //  if (connection) {
        
        //}
        
        NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil ];
        
        // parse the returned JSON object
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding: NSUTF8StringEncoding];
        
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *response = (NSDictionary *) [jsonParser objectWithString:returnString error:NULL];
        
        NSString *apiStatus = [response valueForKey:@"apiStatus"];
        if ([apiStatus isEqualToString:@"100"]) {
            //NSLog(@"Send Feedback Failed.");
        }
        
    }
    
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.sendFeedback - %@ - %@", [e name], [e description]);
    }
}


//App Actions Methods
+(void)initiateSession{
    @try {
        traceSession = [NSMutableArray array];
        traceTimeStamps = [NSMutableArray array];
        
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"liveDebugStream"];
        isLiveDebugActive = FALSE;
    }
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.initiateSession - %@ - %@", [e name], [e description]);
    }
}

+(void)addEventToSession:(NSString *)event{
    @try {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        
        NSDate *myDate = [NSDate date];
        
        
        
        if ([traceSession count] > NUMBER_EVENTS_STORED || ([traceSession count] != [traceTimeStamps count])) {
            traceSession = [NSMutableArray array];
            traceTimeStamps = [NSMutableArray array];
        }
        
        if ([traceSession count] < NUMBER_EVENTS_STORED) {
            [traceSession addObject:event];
            [traceTimeStamps addObject:myDate];
        }else{
            [traceSession removeObjectAtIndex:0];
            [traceSession addObject:event];
            [traceTimeStamps removeObjectAtIndex:0];
            [traceTimeStamps addObject:myDate];
        }
        
        
        //TODO: rSkybox - instantiate your app delegate (uncomment the line below and replace MyAppDelegate with your app delegate);
        AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        NSString *tmpTrace = @"";
        NSString *tmpTraceTime = @"";
        
        
        for (int i = 0; i < [traceSession count]; i++) {
            
            if (i == ([traceSession count] - 1)) {
                tmpTrace = [tmpTrace stringByAppendingFormat:@"%@", [traceSession objectAtIndex:i]];
                
                tmpTraceTime = [tmpTraceTime stringByAppendingFormat:@"%@", [dateFormatter stringFromDate:[traceTimeStamps objectAtIndex:i]]];
                
            }else{
                tmpTrace = [tmpTrace stringByAppendingFormat:@"%@,", [traceSession objectAtIndex:i]];
                tmpTraceTime = [tmpTraceTime stringByAppendingFormat:@"%@,", [dateFormatter stringFromDate:[traceTimeStamps objectAtIndex:i]]];
                
            }
        }
        
        if(isLiveDebugActive) {
            [rSkybox createPacket:event];
        }
        
        mainDelegate.appActions = [NSString stringWithString:tmpTrace];
        mainDelegate.appActionsTime = [NSString stringWithString:tmpTraceTime];
        [mainDelegate saveUserInfo];
    }
    @catch (NSException *e) {
        //NSLog(@"Exception caught in rSkybox.addEventToSession - %@ - %@", [e name], [e description]);
    }
}

+(NSMutableArray *)getActions{
    
    return [NSMutableArray arrayWithArray:traceSession];
}

+(NSMutableArray *)getTimestamps{
    return [NSMutableArray arrayWithArray:traceTimeStamps];
    
}

+(void)setSavedArray:(NSMutableArray *)savedArray :(NSMutableArray *)savedArrayTime{
    @try {
        traceSession = [NSMutableArray arrayWithArray:savedArray];
        traceTimeStamps = [NSMutableArray arrayWithArray:savedArrayTime];
    }
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.setSavedArray - %@ - %@", [e name], [e description]);
    }
}

+(void)printTraceSession{
    @try {
        for (int i = 0; i < [traceSession count]; i++) {
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSS"];
            // NSString *dateString = [dateFormatter stringFromDate:[traceTimeStamps objectAtIndex:i]];
            
            // NSLog(@"%d: %@ - %@", i, [traceSession objectAtIndex:i], dateString);
        }
    }
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.printTraceSession - %@ - %@", [e name], [e description]);
    }
}



//Take input binary and Base 64 encode it
+ (NSString *)encodeBase64data:(NSData *)encodeData{
    
    @try {
        //NSData *encodeData = [stringToEncode dataUsingEncoding:NSUTF8StringEncoding]
        char encodeArray[500000];
        
        memset(encodeArray, '\0', sizeof(encodeArray));
        
        // Base64 Encode username and password
        encode([encodeData length], (char *)[encodeData bytes], sizeof(encodeArray), encodeArray);
        NSString *dataStr = [NSString stringWithCString:encodeArray length:strlen(encodeArray)];
        
        // NSString *dataStr = [NSString stringWithCString:encodeArray encoding:NSUTF8StringEncoding];
        
        NSString *encodedString =[@"" stringByAppendingFormat:@"%@", dataStr];
        
        
        return encodedString;
    }
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.encodeBase64data - %@ - %@", [e name], [e description]);
        return @"";
    }
    
    
}

//Take a String and encode it in Base 64
+ (NSString *)encodeBase64:(NSString *)stringToEncode{
    
    @try {
        NSData *encodeData = [stringToEncode dataUsingEncoding:NSUTF8StringEncoding];
        char encodeArray[512];
        
        memset(encodeArray, '\0', sizeof(encodeArray));
        
        // Base64 Encode username and password
        encode([encodeData length], (char *)[encodeData bytes], sizeof(encodeArray), encodeArray);
        
        NSString *dataStr = [NSString stringWithCString:encodeArray length:strlen(encodeArray)];
        
        NSString *encodedString =[@"" stringByAppendingFormat:@"Basic %@", dataStr];
        
        return encodedString;
    }
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.encodeBase64 - %@ - %@", [e name], [e description]);
        return @"";
    }
    
}

//Initialize and return the Basic Authentication header
+(NSString *)getBasicAuthHeader {
    @try {
        NSString *stringToEncode = [NSString stringWithFormat:@"%@:%@", basicAuthUserName, basicAuthToken];
        
        NSString *encodedAuth = [rSkybox encodeBase64:stringToEncode];
        return encodedAuth;
    }
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.getBasicAuthHeader - %@ - %@", [e name], [e description]);
        return @"";
    }
}

+(void)createStream:(NSString *)name {
    @try {
        api = CreateStream;
        
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *loginDict = [[NSDictionary alloc] init];
        
        streamName = [NSString stringWithString: name];
        [tempDictionary setObject:name forKey:@"name"];
        [tempDictionary setObject:[rSkybox getUserId] forKey:@"userId"];
        
        loginDict = tempDictionary;
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDict JSONRepresentation], nil];
        NSString *tmpUrl = [baseUrl stringByAppendingFormat:@"/applications/%@/streams", applicationId];
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:tmpUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *basicAuth = [rSkybox getBasicAuthHeader];
        [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if (connection) {
        }
        
        //        NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil ];
        //
        //        // parse the returned JSON object
        //        NSString *returnString = [[NSString alloc] initWithData:returnData encoding: NSUTF8StringEncoding];
        //
        //        SBJsonParser *jsonParser = [SBJsonParser new];
        //        NSDictionary *response = (NSDictionary *) [jsonParser objectWithString:returnString error:NULL];
        //
        //        NSString *apiStatus = [response valueForKey:@"apiStatus"];
        //        if ([apiStatus isEqualToString:@"100"]) {
        //            //NSLog(@"Send Feedback Failed.");
        //        }
    }
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.createStream - %@ - %@", [e name], [e description]);
    }
}

// Stream name is passed in but not used.
// Assumption is only one stream can be active at a time and its ID is held in static variable 'jjj'
+(void)closeStream:(NSString *)name {
    @try {
        api = CloseStream;
        if(!isLiveDebugActive) {
            NSLog(@"closeStream -- returning because stream is not active");
            return;
        }
        
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *loginDict = [[NSDictionary alloc] init];
        
        [tempDictionary setObject:CLOSED_STATUS forKey:@"status"];
        
        loginDict = tempDictionary;
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDict JSONRepresentation], nil];
        NSString *tmpUrl = [baseUrl stringByAppendingFormat:@"/applications/%@/streams/%@", applicationId, streamId];
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:tmpUrl]];
        [request setHTTPMethod: @"PUT"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *basicAuth = [rSkybox getBasicAuthHeader];
        [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if (connection) {
        }
    }
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.closeStream - %@ - %@", [e name], [e description]);
    }
}

// Creates a new packet
// Checks return and sees if Stream has been ended. If so, deactivates the stream.
+(void)createPacket:(NSString *)packet {
    @try {
        api = CreatePacket;
        
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *loginDict = [[NSDictionary alloc] init];
        
        [tempDictionary setObject:packet forKey:@"body"];
        
        loginDict = tempDictionary;
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDict JSONRepresentation], nil];
        NSString *tmpUrl = [baseUrl stringByAppendingFormat:@"/applications/%@/streams/%@/packets", applicationId, streamId];
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:tmpUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *basicAuth = [rSkybox getBasicAuthHeader];
        [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
        
        //        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        //        if (connection) {
        //        }
        
        NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil ];
        
        // parse the returned JSON object
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding: NSUTF8StringEncoding];
        
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *response = (NSDictionary *) [jsonParser objectWithString:returnString error:NULL];
        [rSkybox createPacketResponse:response];
    }
    @catch (NSException *e) {
        NSLog(@"Exception caught in rSkybox.createPacket - %@ - %@", [e name], [e description]);
    }
}

+ (NSString*)apiToString {
    @try {
        NSString *result = nil;
        switch(api) {
            case CreateStream:
                result = @"CreateStream";
                break;
                
            case CloseStream:
                result = @"CloseStream";
                break;
                
            case CreatePacket:
                result = @"CreatePacket";
                break;
                
            default:
                //[NSException raise:NSGenericException format:@"Unexpected FormatType."];
                break;
        }
        
        return result;
    }
    @catch (NSException *e) {
        NSLog(@"rSkybox.apiToString Exception - %@ - %@", [e name], [e description]);
        return @"";
    }
}

+ (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    @try {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        httpStatusCode = [httpResponse statusCode];
        serverData = [[NSMutableData alloc] init];
    }
    @catch (NSException *e) {
        NSLog(@"rSkybox.connection:didReceiveResponse Exception - %@ - %@", [e name], [e description]);
    }
}

+ (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)mdata {
    @try {
        [serverData appendData:mdata];
    }
    @catch (NSException *e) {
        NSLog(@"rSkybox.connection:didReceiveData Exception - %@ - %@", [e name], [e description]);
    }
}


+ (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    @try {
        NSData *returnData = [NSData dataWithData:serverData];
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
        
        NSLog(@"ReturnString: %@", returnString);
        
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *response = (NSDictionary *) [jsonParser objectWithString:returnString error:NULL];
        
        NSDictionary *responseInfo;
        NSString *notificationType;
        
        BOOL httpSuccess = httpStatusCode == 200 || httpStatusCode == 201 || httpStatusCode == 422;
        BOOL postNotification = YES;
        
        if(api == CreateStream) {
            if (response && httpSuccess) {
                responseInfo = [rSkybox createStreamResponse:response];
            }
            notificationType = @"createStreamNotification";
        } else if(api == CreatePacket) {
            postNotification = NO;
            if (response && httpSuccess) {
                [rSkybox createPacketResponse:response];
            }
        } else if(api == CloseStream) {
            if (response && httpSuccess) {
                responseInfo = [rSkybox closeStreamResponse:response];
            }
            notificationType = @"closeStreamNotification";
        }
        
        if(!httpSuccess) {
            // failure scenario -- HTTP error code returned -- for this processing, we don't care which API failed
            NSLog(@"HTTP Status Code:%d for API %@", httpStatusCode, [rSkybox apiToString]);
        }
        
        if (postNotification) {
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationType object:self userInfo:responseInfo];
        }
    }
    @catch (NSException *e) {
        NSLog(@"rSkybox.connection:connectionDidFinishLoading Exception - %@ - %@", [e name], [e description]);
    }
}


+ (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    @try {
        NSString *urlString = [[[connection currentRequest] URL] absoluteString];
        
        NSString *logName = [NSString stringWithFormat:@"api.%@.%@ - %@", [self apiToString], [rSkybox readableErrorCode:error], urlString];
        NSLog(@"%@", logName);
        
        if(api == CreateStream) {
            streamId = nil;
        } else if(api == CreatePacket) {
        }
    }
    @catch (NSException *e) {
        NSLog(@"rSkybox.connection:didFailWithError Exception - %@ - %@", [e name], [e description]);
    }
    
}

+(NSString *)readableErrorCode:(NSError *)error {
    @try {
        int errorCode = error.code;
        if(errorCode == -1000) return @"NSURLErrorBadURL";
        else if(errorCode == -1001) return @"TimedOut";
        else if(errorCode == -1002) return @"UnsupportedURL";
        else if(errorCode == -1003) return @"CannotFindHost";
        else if(errorCode == -1004) return @"CannotConnectToHost";
        else if(errorCode == -1005) return @"NetworkConnectionLost";
        else if(errorCode == -1006) return @"DNSLookupFailed";
        else if(errorCode == -1007) return @"HTTPTooManyRedirects";
        else if(errorCode == -1008) return @"ResourceUnavailable";
        else if(errorCode == -1009) return @"NotConnectedToInternet";
        else if(errorCode == -1011) return @"BadServerResponse";
        else return [NSString stringWithFormat:@"%i", error.code];
    }
    @catch (NSException *e) {
        NSLog(@"rSkybox.readableErrorCode Exception - %@ - %@", [e name], [e description]);
        return @"";
    }
}


+(NSDictionary *) createStreamResponse:(NSDictionary *)response {
    @try {
        NSString *apiStatus = [response valueForKey:@"apiStatus"];
        NSDictionary *responseInfo = @{@"apiStatus": apiStatus};
        
        if([apiStatus isEqualToString:SUCCESS]) {
            isLiveDebugActive = TRUE;
            streamId = [response valueForKey:@"id"];
           // BOOL created = [[response valueForKey:@"created"] boolValue];
            NSLog(@"CreateStream API successfully created");
        }
        else if([apiStatus isEqualToString:NAME_ALREADY_IN_USE]){
            NSLog(@"CreateStream API application error -- %@", @"NAME_ALREADY_IN_USE");
        }
        else if([apiStatus isEqualToString:APPLICATION_ID_REQUIRED]){
            NSLog(@"CreateStream API application error -- %@", @"APPLICATION_ID_REQUIRED");
        }
        else if([apiStatus isEqualToString:EITHER_USER_ID_OR_MEMBER_ID_IS_REQUIRED]){
            NSLog(@"CreateStream API application error -- %@", @"EITHER_USER_ID_OR_MEMBER_ID_IS_REQUIRED");
        }
        else if([apiStatus isEqualToString:NAME_IS_REQUIRED]){
            NSLog(@"CreateStream API application error -- %@", @"NAME_IS_REQUIRED");
        }
        else if([apiStatus isEqualToString:STREAM_ALREADY_HAS_END_USER]){
            NSLog(@"CreateStream API application error -- %@", @"STREAM_ALREADY_HAS_END_USER");
        }
        else if([apiStatus isEqualToString:STREAM_ALREADY_HAS_MEMBER]){
            NSLog(@"CreateStream API application error -- %@", @"STREAM_ALREADY_HAS_MEMBER");
        }
        else if([apiStatus isEqualToString:BOTH_USER_ID_AND_MEMBER_ID_SPECIFIED]){
            NSLog(@"CreateStream API application error -- %@", @"BOTH_USER_ID_AND_MEMBER_ID_SPECIFIED");
        }
        else if([apiStatus isEqualToString:APPLICATION_NOT_FOUND]){
            NSLog(@"CreateStream API application error -- %@", @"APPLICATION_NOT_FOUND");
        }
        else {
            NSLog(@"CreateStream API application error -- %@", @"unknown -- should NOT happen!!!");
        }
        
        return responseInfo;
    }
    @catch (NSException *e) {
        NSLog(@"rSkybox.createStreamResponse Exception - %@ - %@", [e name], [e description]);
        return @{};
    }
}

+(NSDictionary *) closeStreamResponse:(NSDictionary *)response {
    @try {
        // even if the server request to close the stream fails, mark the stream as inactive
        isLiveDebugActive = FALSE;
        
        NSString *apiStatus = [response valueForKey:@"apiStatus"];
        NSDictionary *responseInfo = @{@"apiStatus": apiStatus};
        
        if([apiStatus isEqualToString:SUCCESS]) {
            streamId = nil;
            NSLog(@"CloseStream API successful");
        }
        else if([apiStatus isEqualToString:INVALID_STATUS]){
            NSLog(@"CloseStream API application error -- %@", @"INVALID_STATUS");
        }
        else if([apiStatus isEqualToString:USER_NOT_AUTHORIZED_FOR_APPLICATION]){
            NSLog(@"CloseStream API application error -- %@", @"USER_NOT_AUTHORIZED_FOR_APPLICATION");
        }
        else if([apiStatus isEqualToString:APPLICATION_NOT_AUTHORIZED]){
            NSLog(@"CloseStream API application error -- %@", @"APPLICATION_NOT_AUTHORIZED");
        }
        else if([apiStatus isEqualToString:APPLICATION_ID_REQUIRED]){
            NSLog(@"CloseStream API application error -- %@", @"APPLICATION_ID_REQUIRED");
        }
        else if([apiStatus isEqualToString:STREAM_ID_REQUIRED]){
            NSLog(@"CloseStream API application error -- %@", @"STREAM_ID_REQUIRED");
        }
        else if([apiStatus isEqualToString:APPLICATION_NOT_FOUND]){
            NSLog(@"CloseStream API application error -- %@", @"APPLICATION_NOT_FOUND");
        }
        else if([apiStatus isEqualToString:STREAM_NOT_FOUND]){
            NSLog(@"CloseStream API application error -- %@", @"STREAM_NOT_FOUND");
        }
        else {
            NSLog(@"CloseStream API application error -- %@", @"unknown -- should NOT happen!!!");
        }
        
        return responseInfo;
    }
    @catch (NSException *e) {
        NSLog(@"rSkybox.closeStreamResponse Exception - %@ - %@", [e name], [e description]);
        return @{};
    }
}

+(void) createPacketResponse:(NSDictionary *)response {
    @try {
        NSString *apiStatus = [response valueForKey:@"apiStatus"];
        if([apiStatus isEqualToString:SUCCESS]) {
            NSLog(@"CreatePacket API successfully created");
        }
        else if([apiStatus isEqualToString:STREAM_CLOSED]){
            NSLog(@"CreatePacket API STREAM_CLOSED");
            isLiveDebugActive = FALSE;
        }
        else if([apiStatus isEqualToString:APPLICATION_ID_REQUIRED]){
            NSLog(@"CreatePacket API application error -- %@", @"APPLICATION_ID_REQUIRED");
        }
        else if([apiStatus isEqualToString:STREAM_ID_REQUIRED]){
            NSLog(@"CreatePacket API application error -- %@", @"STREAM_ID_REQUIRED");
        }
        else if([apiStatus isEqualToString:BODY_REQUIRED]){
            NSLog(@"CreatePacket API application error -- %@", @"BODY_REQUIRED");
        }
        else {
            NSLog(@"CreatePacket API application error -- %@", @"unknown -- should NOT happen!!!");
        }
    }
    @catch (NSException *e) {
        NSLog(@"rSkybox.createPacketResponse Exception - %@ - %@", [e name], [e description]);
    }
}

+(NSString *)getActiveStream {
    @try {
        if([streamId length] == 0) {
            return nil;
        } else {
            return streamName;
        }
    }
    @catch (NSException *e) {
        NSLog(@"Exception caught in getActiveStream - %@ - %@", [e name], [e description]);
        return @"";
    }
}


@end



