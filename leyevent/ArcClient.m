
//
//  ArcClient.m
//  ARC
//
//  Created by Joseph Wroblewski on 8/5/12.
//
//

#import "ArcClient.h"
#import "SBJson.h"
#import "AppDelegate.h"
#import "rSkybox.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "ArcIdentifier.h"
#import "Encoder.h"

//NSString *_arcUrl = @"http://68.57.205.193:8700/arc-dev/rest/v1/";    //Jim's Place
//NSString *_arcUrl = @"http://arc-stage.dagher.mobi/rest/v1/";           // STAGE

//NSString *_arcUrl = @"http://dtnetwork.asuscomm.com:8700/arc-dev/rest/v1/";

NSString *_arcUrl = @"http://dev.dagher.mobi/rest/v1/";       //DEV - Cloud
//NSString *_arcUrl = @"http://24.14.40.71:8700/arc-dev/rest/v1/";
//NSString *_arcUrl = @"https://arc.dagher.mobi/rest/v1/";           // CLOUD
//NSString *_arcUrl = @"http://dtnetwork.dyndns.org:8700/arc-dev/rest/v1/";  // Jim's Place

//NSString *_arcServersUrl = @"http://arc-servers.dagher.mobi/rest/v1/"; // Servers API: CLOUD I
//NSString *_arcServersUrl = @"http://arc-servers.dagher.net.co/rest/v1/"; // Servers API: CLOUD II
NSString *_arcServersUrl = @"http://gateway.dagher.mobi/rest/v1/"; // NEW dedicated ServerURL CLOUD

//NSString *_arcServersUrl = @"http://dtnetwork.dyndns.org:8700/arc-servers/rest/v1/"; // Servers API: Jim's Place

int const USER_ALREADY_EXISTS = 103;
int const INCORRECT_PASSCODE = 105;
int const INCORRECT_LOGIN_INFO = 106;
int const INVOICE_CLOSED = 603;
int const INVOICE_NOT_FOUND = 604;
int const MERCHANT_CANNOT_ACCEPT_PAYMENT_TYPE = 400;
int const OVER_PAID = 401;
int const INVALID_AMOUNT = 402;

int const CANNOT_PROCESS_PAYMENT = 500;
int const CANNOT_TRANSFER_TO_SAME_ACCOUNT = 501;
int const INVALID_ACCOUNT_PIN = 502;
int const INSUFFICIENT_FUNDS = 503;

int const PAYMENT_MAYBE_PROCESSED = 602;
int const FAILED_TO_VALIDATE_CARD = 605;
int const FIELD_FORMAT_ERROR = 606;
int const INVALID_ACCOUNT_NUMBER = 607;
int const CANNOT_GET_PAYMENT_AUTHORIZATION = 608;
int const INVALID_EXPIRATION_DATE = 610;
int const UNKOWN_ISIS_ERROR = 699;
int const DUPLICATE_TRANSACTION = 612;

//Micros
int const INVALID_SECURITY_PIN = 626;

int const CARD_ALREADY_PROCESSED = 628;
int const CHECK_IS_LOCKED = 630;
int const NO_AUTHORIZATION_PROVIDED = 631;
int const PAYMENT_POSSIBLE_SUCCESS = 640;


int const NETWORK_ERROR_CONFIRM_PAYMENT = 998;
int const NETWORK_ERROR = 999;
int const MAX_RETRIES_EXCEEDED = 1000;


static NSMutableDictionary *latencyStartTimes = nil;

NSString *const ARC_ERROR_MSG = @"Request failed, please try again.";

@implementation ArcClient

+ (void) initialize{
    latencyStartTimes = [[NSMutableDictionary alloc] init];
}

- (id)init {
    if (self = [super init]) {
        
        self.retryTimes = @[@(3),@(2),@(2),@(2),@(4),@(5),@(6),@(7),@(8),@(9),@(10),@(11), @(15), @(15), @(25)];
        self.retryTimesRegister = @[@(3),@(3),@(2),@(3),@(4),@(6)];
        self.retryTimesInvoice = @[@(2),@(2),@(2),@(3),@(4),@(5)];

        self.serverPingArray = [NSMutableArray array];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if ([prefs valueForKey:@"arcUrl"] && ([[prefs valueForKey:@"arcUrl"] length] > 0)) {
          // _arcUrl = [prefs valueForKey:@"arcUrl"];
        }
        
       // NSLog(@"***** Arc URL = %@ *****", _arcUrl);
    }
    return self;
}

-(NSString *)getCurrentUrl{
    return _arcUrl;
}

-(void)getServer{
    @try {
        
   
        
        api = GetServer;
        
        //NSString *createUrl = [NSString stringWithFormat:@"%@servers/%@", _arcUrl, [[NSUserDefaults standardUserDefaults] valueForKey:@"customerId"], nil];
        
        NSString *createUrl = [NSString stringWithFormat:@"%@servers/assign/current", _arcServersUrl];
        
        NSString *event = [NSString stringWithFormat:@"getServer - request url - %@", createUrl];
        [rSkybox addEventToSession:event];

        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createUrl]];
        
        [request setHTTPMethod: @"GET"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        if (![[self authHeader] isEqualToString:@""]) {
           [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        }

        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"GetServer"];
        //self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getServer" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)createCustomer:(NSDictionary *)pairs{
    @try {
       
        api = CreateCustomer;
        
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:pairs];
        [newDictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        [newDictionary setValue:[NSNumber numberWithBool:YES] forKeyPath:@"IsLeye"];
        pairs = newDictionary;
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
      
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSString *createUrl = [NSString stringWithFormat:@"%@customers/create", _arcUrl];
        
        
        NSString *eventString = [NSString stringWithFormat:@"createCustomer - URL: %@, request string: %@", createUrl, requestString];
        [rSkybox addEventToSession:eventString];
        
        
        NSLog(@"CreateUrl: %@", createUrl);
        NSLog(@"CreateString: %@", requestString);

        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"CreateCusotmer"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.createCustomer" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)updateGuestCustomer:(NSDictionary *)pairs{
    @try {
        api = UpdateGuestCustomer;
        
        
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:pairs];
        [newDictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        pairs = newDictionary;
        
        
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
       
        
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSString *createUrl = [NSString stringWithFormat:@"%@customers/update/current", _arcUrl];
        
        NSString *eventString = [NSString stringWithFormat:@"updateGuestCustomer - URL: %@, request string: %@", createUrl, requestString];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];

        NSLog(@"Request: %@", requestString);
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"UpdateGuestCustomer"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.updateGuestCustomer" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)getCustomerToken:(NSDictionary *)pairs{
    @try {
        api = GetCustomerToken;
        
        
        NSString * login = [ pairs objectForKey:@"userName"];
        NSString * password = [ pairs objectForKey:@"password"];
        
        
        NSMutableDictionary *loginDictionary = [ NSMutableDictionary dictionary];
        [loginDictionary setValue:login forKey:@"Login"];
        [loginDictionary setValue:password forKey:@"Password"];
        // the phone always sets activate to true. The website never does. Only the phone can reactivate a user.
        NSNumber *activate = [NSNumber numberWithBool:YES];
        [loginDictionary setValue:activate forKey:@"Activate"];

        
        [loginDictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDictionary JSONRepresentation], nil];
        
      
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
       // NSString *getCustomerTokenUrl = [NSString stringWithFormat:@"%@customers?login=%@&password=%@", _arcUrl, login, password,nil];
        NSString *getCustomerTokenUrl = [NSString stringWithFormat:@"%@customers/token", _arcUrl, nil];
                
        NSString *eventString = [NSString stringWithFormat:@"getCustomerToken - URL: %@, request string: %@", getCustomerTokenUrl, requestString];
        [rSkybox addEventToSession:eventString];
        
      //  NSLog(@"URL: %@", getCustomerTokenUrl);
       // NSLog(@"JSON: %@", requestString);
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:getCustomerTokenUrl]];
        [request setHTTPMethod: @"SEARCH"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"GetCusotmerToken"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getCustomerToken" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)getGuestToken:(NSDictionary *)pairs{
    @try {

        api = GetGuestToken;
        
        
        NSString * login = [ pairs objectForKey:@"userName"];
        NSString * password = [ pairs objectForKey:@"password"];
        
        
        NSMutableDictionary *loginDictionary = [ NSMutableDictionary dictionary];
        [loginDictionary setValue:login forKey:@"Login"];
        [loginDictionary setValue:password forKey:@"Password"];
        [loginDictionary setValue:@"Forgetmenot00" forKey:@"GuestKey"];
        [loginDictionary setValue:[NSNumber numberWithBool:YES] forKey:@"IsGuest"];
        
        [loginDictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        
        
        // the phone always sets activate to true. The website never does. Only the phone can reactivate a user.
        NSNumber *activate = [NSNumber numberWithBool:YES];
        [loginDictionary setValue:activate forKey:@"Activate"];
        
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDictionary JSONRepresentation], nil];
        
       
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        // NSString *getCustomerTokenUrl = [NSString stringWithFormat:@"%@customers?login=%@&password=%@", _arcUrl, login, password,nil];
        NSString *getCustomerTokenUrl = [NSString stringWithFormat:@"%@customers/token", _arcUrl, nil];
        
        NSString *eventString = [NSString stringWithFormat:@"getGuestToken - URL: %@, request string: %@", getCustomerTokenUrl,requestString];
        [rSkybox addEventToSession:eventString];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:getCustomerTokenUrl]];
        [request setHTTPMethod: @"SEARCH"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
      //  NSLog(@"URL: %@", getCustomerTokenUrl);
        //NSLog(@"Params: %@", requestString);
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"GetGuestToken"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getCustomerToken" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)getMerchantList:(NSDictionary *)pairs{
    @try {
        
     
    
        
        
       // NSLog(@"Pairs: %@", pairs);
        
        api = GetMerchantList;
        
       // pairs = [NSDictionary dictionary];
        NSMutableDictionary *loginDictionary = [NSMutableDictionary dictionaryWithDictionary:pairs];
        
        [loginDictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        [loginDictionary setValue:@"2" forKey:@"TypeId"];

        NSString *requestString = [NSString stringWithFormat:@"%@", [loginDictionary JSONRepresentation], nil];
        
       
       // NSLog(@"RequestString: %@", requestString);
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        //NSLog(@"getMerchantList requestString = %@", requestString);
        
        NSString *getMerchantListUrl = [NSString stringWithFormat:@"%@merchants/list", _arcUrl, nil];
        //NSLog(@"GertMerchantList URL = %@", getMerchantListUrl);
        
        NSString *eventString = [NSString stringWithFormat:@"getMerchantList - URL: %@, request string: %@", getMerchantListUrl,requestString];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:getMerchantListUrl]];
        [request setHTTPMethod: @"SEARCH"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];   
        
      //  NSLog(@"Request: %@", requestString);
        
       //NSLog(@"Auth Header: %@", [self authHeader]);
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"GetMerchantList"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getMerchantList" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void)getInvoice:(NSDictionary *)pairs{
    @try {
        api = GetInvoice;
        
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

        if (pairs) {
            
            [dictionary setValue:[pairs valueForKey:@"invoiceNumber"] forKey:@"Number"];
           // [dictionary setValue:[pairs valueForKey:@"merchantId"] forKey:@"MerchantId"];
            //[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"Process"];
            
            NSNumber *pos = [NSNumber numberWithBool:NO];
            [dictionary setValue:pos forKey:@"POS"];
        }
        
        [dictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [dictionary JSONRepresentation], nil];
        
        
        
        
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        
        NSString *getInvoiceUrl = [NSString stringWithFormat:@"%@invoices/list", _arcUrl];

        NSString *eventString = [NSString stringWithFormat:@"getInvoice - URL: %@, request string: %@", getInvoiceUrl,requestString];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:getInvoiceUrl]];
        [request setHTTPMethod: @"SEARCH"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];

        [request setHTTPBody: requestData];

        
         //NSLog(@"Request String: %@", requestString);
        
        
     //   NSLog(@"getInvoiceUrl: %@", getInvoiceUrl);

        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"GetInvoice"];
        [ArcClient startLatency:GetInvoice];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getInvoice" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void) createPayment:(NSDictionary *)pairs{
    
  //  NSLog(@"Calling Create Payment at: %@", [NSDate date]);

    @try {

        api = CreatePayment;
        
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:pairs];
        [newDictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        pairs = newDictionary;
        
        
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
        
      
       
        
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSString *createPaymentUrl = [NSString stringWithFormat:@"%@payments/create", _arcUrl, nil];
        
        @try {
            NSString *eventString = [NSString stringWithFormat:@"createPayment - URL: %@, request string: %@", createPaymentUrl,requestString];
            
            int location = [eventString rangeOfString:@"FundSourceAccount"].location;
            int secondQuote = [eventString rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(location + 20, 30)].location;
            
            int totalCcLength = secondQuote - (location + 20);
            NSString *stringValue = [NSString stringWithFormat:@"CC length: %d", totalCcLength];
            eventString = [eventString stringByReplacingCharactersInRange:NSMakeRange(location + 20, 16) withString:stringValue];
            
            //NSLog(@"EventString: %@", eventString);
            
            [rSkybox addEventToSession:eventString];
        }
        @catch (NSException *exception) {
            NSString *eventString = [NSString stringWithFormat:@"Exception trying to eliminate CC from requeststring: %@", exception];
            [rSkybox addEventToSession:eventString];
            
        }
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createPaymentUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        
     //   NSLog(@"Auth Header: %@", [self authHeader]);
      //  NSLog(@"RequestString: %@", requestString);
        
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"CreatePayment"];
        [ArcClient startLatency:CreatePayment];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.createPayment" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void)createReview:(NSDictionary *)pairs{
    @try {

        api = CreateReview;
        
        
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:pairs];
        [newDictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        pairs = newDictionary;
        
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
        
 
        
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSString *createReviewUrl = [NSString stringWithFormat:@"%@reviews/new", _arcUrl, nil];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createReviewUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        
        
        NSString *eventString = [NSString stringWithFormat:@"createReview - URL: %@, request string: %@", createReviewUrl,requestString];
        [rSkybox addEventToSession:eventString];
        
        
       // NSLog(@"Request String: %@", requestString);
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"GetReview"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.createReview" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void)getPointBalance:(NSDictionary *)pairs{
    @try {
        [rSkybox addEventToSession:@"getPointBalance"];
        api = GetPointBalance;
        
        NSString * customerId = [pairs valueForKey:@"customerId"];
        
        NSString *createReviewUrl = [NSString stringWithFormat:@"%@points/balance/%@", _arcUrl, customerId, nil];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createReviewUrl]];
        [request setHTTPMethod: @"GET"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"GetPointBalance"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getPointBalance" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void)trackEvent:(NSDictionary *)pairs{
    @try {
        [rSkybox addEventToSession:@"TrackEventAdded"];

        AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [mainDelegate.trackEventArray addObject:pairs];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.trackEventPairs" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void)sendTrackEvent:(NSMutableArray *)eventArray{
    
    @try {
        api = TrackEvent;
        
        if ([eventArray count] == 0) {
            return;
        }
        
        NSDictionary *myDictionary = @{@"Analytics" : [NSArray arrayWithArray:eventArray], @"AppInfo":[self getAppInfoDictionary]};
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [myDictionary JSONRepresentation], nil];
       // NSLog(@"requestString: %@", requestString);
        
        
     
        
        
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSString *trackEventUrl = [NSString stringWithFormat:@"%@analytics/new", _arcUrl, nil];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:trackEventUrl]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        @try {
            [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        }
        @catch (NSException *exception) {
            
        }
        
        NSString *eventString = [NSString stringWithFormat:@"sendTrackEvents - URL: %@, request string: %@", trackEventUrl,requestString];
        [rSkybox addEventToSession:eventString];
        
        
      //  NSLog(@"TrackEventURL: %@", trackEventUrl);
        
      //  NSLog(@"RequestString: %@", requestString);
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"SendTrackEvents"];
        //self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:nil startImmediately: YES];
        
        [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.sendTrackEvent" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void)getPasscode:(NSDictionary *)pairs{
    @try {
        api = GetPasscode;
        
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:pairs];
        [newDictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        pairs = newDictionary;
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
       
        
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSString *createReviewUrl = [NSString stringWithFormat:@"%@customers/passcode", _arcUrl, nil];
        
        NSString *eventString = [NSString stringWithFormat:@"getPasscode - URL: %@, request string: %@", createReviewUrl,requestString];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createReviewUrl]];
        //[request setHTTPMethod: @"PUT"];
        [request setHTTPMethod: @"POST"];

        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        //[request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        
        
        //NSLog(@"RequestString: %@", requestString);
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"getPasscode"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getPasscode" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void)resetPassword:(NSDictionary *)pairs{
    
    @try {
        api = ResetPassword;
        
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:pairs];
        [newDictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        pairs = newDictionary;
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
      
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSString *createReviewUrl = [NSString stringWithFormat:@"%@customers/passwordreset", _arcUrl, nil];
        
        NSString *eventString = [NSString stringWithFormat:@"resetPassword - URL: %@, request string: %@", createReviewUrl,requestString];
        [rSkybox addEventToSession:eventString];
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createReviewUrl]];
        //[request setHTTPMethod: @"PUT"];
        [request setHTTPMethod: @"POST"];

        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        //[request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        
        //NSLog(@"Request String: %@", requestString);
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"resetPassword"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.resetPassword" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)setServer:(NSString *)serverNumber{
    @try {
        api = SetAdminServer;
        
        NSString *customerId = [[NSUserDefaults standardUserDefaults] valueForKey:@"customerId"];
        
        NSString *createUrl = [NSString stringWithFormat:@"%@servers/%@/setserver/%@", _arcServersUrl, customerId, serverNumber];
        
        
        NSString *eventString = [NSString stringWithFormat:@"resetPassword - request url: %@", createUrl];
        [rSkybox addEventToSession:eventString];
        
        
        //NSLog(@"CreateUrl: %@", createUrl);
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createUrl]];
        [request setHTTPMethod: @"GET"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];

        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"setAdminServer"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.setServerNumber" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

/*
-(void)updatePushToken{
    
    @try {
        api = UpdatePushToken;

        NSMutableDictionary *pairs = [NSMutableDictionary dictionary];
        
        AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if ([mainDelegate.pushToken length] > 0) {
            
            [pairs setValue:mainDelegate.pushToken forKey:@"DeviceId"];
            
            [pairs setValue:@"Production" forKey:@"PushType"];
            
#if DEBUG==1
            [pairs setValue:@"Development" forKey:@"PushType"];
#endif
                        
            NSNumber *noMail = [NSNumber numberWithBool:YES];
            [pairs setValue:noMail forKey:@"NoMail"];
            
            [pairs setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
            
            NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
            
          
            
            
            NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
            
            ArcClient *tmp = [[ArcClient alloc] init];
            NSString *arcUrl = [tmp getCurrentUrl];
            
            NSString *merchantId = [[NSUserDefaults standardUserDefaults] valueForKey:@"customerId"];
            merchantId = @"current";
            
            NSString *createReviewUrl = [NSString stringWithFormat:@"%@customers/update/%@", arcUrl, merchantId, nil];
            
            NSString *eventString = [NSString stringWithFormat:@"updatePushToken - URL: %@, request string: %@", createReviewUrl,requestString];
            [rSkybox addEventToSession:eventString];
            
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createReviewUrl]];
            [request setHTTPMethod: @"POST"];
            
            [request setHTTPBody: requestData];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:[tmp authHeader] forHTTPHeaderField:@"Authorization"];
            
          //  NSLog(@"Request String: %@", requestString);
            
            self.serverData = [NSMutableData data];
            [rSkybox startThreshold:@"updatePushToken"];
            self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
            
            
        }
        
        
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.updatePushToken" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}
*/

-(void)referFriend:(NSArray *)emailAddresses{
    
    @try {
        api = ReferFriend;
        
        NSMutableArray *emailAddressArray = [NSMutableArray array];
        
        for (int i = 0; i < [emailAddresses count]; i++) {
            
            NSMutableDictionary *pairs = [NSMutableDictionary dictionary];            
            [pairs setValue:[emailAddresses objectAtIndex:i] forKey:@"eMail"];
            
            [emailAddressArray addObject:pairs];
        }
      
        
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [emailAddressArray JSONRepresentation], nil];
        
      
        
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
    
  
        
        NSString *createReviewUrl = [NSString stringWithFormat:@"%@customers/referfriends", _arcUrl, nil];
        
        NSString *eventString = [NSString stringWithFormat:@"referFriend - URL: %@, request string: %@", createReviewUrl,requestString];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createReviewUrl]];
        [request setHTTPMethod: @"POST"];
        
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"referFriend"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.referFriend" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)confirmPayment{
    
   // NSLog(@"Calling Confirm Payment at: %@", [NSDate date]);
    
    @try {
        api = ConfirmPayment;
        
        NSDictionary *params = @{@"TicketId" : self.ticketId, @"AppInfo":[self getAppInfoDictionary]};
                
        NSString *requestString = [NSString stringWithFormat:@"%@", [params JSONRepresentation], nil];
        
    
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
                
        NSString *createReviewUrl = [NSString stringWithFormat:@"%@payments/confirm", _arcUrl, nil];
        
        NSString *eventString = [NSString stringWithFormat:@"confirmPayment - URL: %@, request string: %@", createReviewUrl,requestString];
        [rSkybox addEventToSession:eventString];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createReviewUrl]];
        [request setHTTPMethod: @"SEARCH"];
        
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        

        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"confirmPayment"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.confirmPayment" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void)confirmRegister{
    
    @try {
        api = ConfirmRegister;
        
        NSDictionary *params = @{@"TicketId" : self.registerTicketId, @"AppInfo":[self getAppInfoDictionary]};
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [params JSONRepresentation], nil];
        
        
     
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        NSString *createReviewUrl = [NSString stringWithFormat:@"%@customers/register/confirm", _arcUrl, nil];
        
        NSString *eventString = [NSString stringWithFormat:@"confirmRegister - URL: %@, request string: %@", createReviewUrl,requestString];
        [rSkybox addEventToSession:eventString];
        
        
        //NSLog(@"Confirm URL: %@", createReviewUrl);
        //NSLog(@"ConfirmData: %@", requestString);
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:createReviewUrl]];
        [request setHTTPMethod: @"SEARCH"];
        
        [request setHTTPBody: requestData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        //[request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        
    
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"confirmRegister"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.confirmRegister" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}



-(void)sendServerPings{
    @try {
        api = PingServer;
        
        
        NSString *pingUrl = @"http://arc.dagher.net.co/rest/v1/tools/ping";
        
        
        NSString *eventString = [NSString stringWithFormat:@"sendServerPing - request url: %@", pingUrl];
        [rSkybox addEventToSession:eventString];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:pingUrl]];
        
        [request setHTTPMethod: @"GET"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"sendServerPing"];
        self.pingStartTime = [NSDate date];
        [request setTimeoutInterval:5];
       // self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.sendServerPings" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)getListOfServers{
    @try {

        api = GetListOfServers;
        
        
        NSString *pingUrl = [NSString stringWithFormat:@"%@servers/list", _arcServersUrl];
        
        
        NSString *eventString = [NSString stringWithFormat:@"getListOfServers - request url: %@", pingUrl];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:pingUrl]];
        
        [request setHTTPMethod: @"GET"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        

        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"getListOfServers"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.sendServerPings" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}



-(void)getListOfPayments{
    @try {
        
        api = GetListOfPayments;
        
        
        NSString *pingUrl = [NSString stringWithFormat:@"%@payments/list", _arcUrl];
        
        NSString *customerId = [[NSUserDefaults standardUserDefaults] valueForKey:@"customerId"];
        if ([customerId length] == 0) {
            customerId = [[NSUserDefaults standardUserDefaults] valueForKey:@"guestId"];
        }
        
        NSDictionary *pairs = @{@"AppInfo": [self getAppInfoDictionary], @"CustomerId":customerId};
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        

        
        
        NSString *eventString = [NSString stringWithFormat:@"getListOfPayments - request url: %@", pingUrl];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:pingUrl]];
        
        [request setHTTPMethod: @"SEARCH"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        [request setHTTPBody: requestData];

        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"getListOfPayments"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getListOfPayments" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)getListOfCreditCards{
    @try {
        
        api = GetCreditCards;
        
        
        NSString *pingUrl = [NSString stringWithFormat:@"%@customers/creditcards/list", _arcUrl];
        
        NSString *customerId = [[NSUserDefaults standardUserDefaults] valueForKey:@"customerId"];
        
        if ([customerId length] == 0) {
            customerId = [[NSUserDefaults standardUserDefaults] valueForKey:@"guestId"];
        }
        
        
        
        NSDictionary *pairs = @{@"AppInfo": [self getAppInfoDictionary], @"UserId":customerId};
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        
      //  NSLog(@"URL: %@", pingUrl);
        NSLog(@"requestString: %@", requestString);
       
      //  NSLog(@"Auth Header: %@", [self authHeader]);
        
        NSString *eventString = [NSString stringWithFormat:@"getListOfCreditCards - request url: %@", pingUrl];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:pingUrl]];
        
        [request setHTTPMethod: @"SEARCH"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        [request setHTTPBody: requestData];
        
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"getListOfCreditCards"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getListOfCreditCards" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)getListOfRecurringPayments{
    @try {
        
        api = GetRecurringPayments;
        
        
        NSString *pingUrl = [NSString stringWithFormat:@"%@customers/schedule/list", _arcUrl];
        
        NSString *customerId = [[NSUserDefaults standardUserDefaults] valueForKey:@"customerId"];
    
        NSDictionary *pairs = @{@"AppInfo": [self getAppInfoDictionary], @"UserId":customerId};
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        
        //  NSLog(@"URL: %@", pingUrl);
        // NSLog(@"requestString: %@", requestString);
        
        //  NSLog(@"Auth Header: %@", [self authHeader]);
        
        NSString *eventString = [NSString stringWithFormat:@"getListOfRecurringPayments - request url: %@", pingUrl];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:pingUrl]];
        
        [request setHTTPMethod: @"SEARCH"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        [request setHTTPBody: requestData];
        
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"getListOfRecurringPayments"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getListOfRecurringPayments" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)deleteRecurringPayment:(NSString *)paymentId{
    @try {
        
        api = DeleteRecurringPayment;
        
        
        NSString *pingUrl = [NSString stringWithFormat:@"%@customers/schedule/delete/%@", _arcUrl, paymentId];
       
        NSDictionary *pairs = @{@"AppInfo": [self getAppInfoDictionary]};
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        
       //   NSLog(@"URL: %@", pingUrl);
        // NSLog(@"requestString: %@", requestString);
        
        //  NSLog(@"Auth Header: %@", [self authHeader]);
        
        NSString *eventString = [NSString stringWithFormat:@"deleteRecurringPayment - request url: %@", pingUrl];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:pingUrl]];
        
        [request setHTTPMethod: @"DELETE"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        [request setHTTPBody: requestData];
        
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"deleteRecurringPayment"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.deleteRecurringPayment" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)createRecurringPayment:(NSDictionary *)pairs{
    @try {
        
        api = CreateReucrringPayment;
        
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:pairs];
        [newDictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        pairs = newDictionary;
        
        
        
        NSString *pingUrl = [NSString stringWithFormat:@"%@customers/schedule/create", _arcUrl];
        
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        
        //  NSLog(@"URL: %@", pingUrl);
        // NSLog(@"requestString: %@", requestString);
        
        //  NSLog(@"Auth Header: %@", [self authHeader]);
        
        NSString *eventString = [NSString stringWithFormat:@"createRecurringPayment - request url: %@", pingUrl];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:pingUrl]];
        
        [request setHTTPMethod: @"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        [request setHTTPBody: requestData];
        
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"createRecurringPayment"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.createRecurringPayment" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void)createMultiplePayments:(NSDictionary *)pairs{
    @try {
        
        api = CreateMultiplePayments;
        
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:pairs];
        [newDictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        pairs = newDictionary;
        
        
        
        NSString *pingUrl = [NSString stringWithFormat:@"%@payments/requests", _arcUrl];
        
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        
         NSLog(@"URL: %@", pingUrl);
         NSLog(@"requestString: %@", requestString);
        
        //  NSLog(@"Auth Header: %@", [self authHeader]);
        
        NSString *eventString = [NSString stringWithFormat:@"createMultiplePayments - request url: %@", pingUrl];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:pingUrl]];
        
        [request setHTTPMethod: @"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        [request setHTTPBody: requestData];
        
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"createMultiplePayments"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.createMultiplePayments" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}




-(void)sendEmailReceipt:(NSDictionary *)pairs{
    @try {
        
        api = SendEmailReceipt;
        
        
        NSString *pingUrl = [NSString stringWithFormat:@"%@payments/sendreceipt", _arcUrl];
        
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:pairs];
        [newDictionary setValue:[self getAppInfoDictionary] forKey:@"AppInfo"];
        pairs = newDictionary;
        
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        
        
        
        NSString *eventString = [NSString stringWithFormat:@"getListOfServers - request url: %@", pingUrl];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:pingUrl]];
        
        [request setHTTPMethod: @"SEARCH"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        [request setHTTPBody: requestData];
        
        
       // NSLog(@"Auth Header: %@", [self authHeader]);
        //NSLog(@"Request: %@", requestString);
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"sendEmailReceipt"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.sendEmailReceipt" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void)getDeviceMessages{
    
    @try {
        
        api = GetDeviceMessages;
        
        
        NSString *pingUrl = [NSString stringWithFormat:@"%@customers/messages/list", _arcUrl];
        
        NSString *customerId = [[NSUserDefaults standardUserDefaults] valueForKey:@"customerId"];
        
        if ([customerId length] == 0) {
            customerId = [[NSUserDefaults standardUserDefaults] valueForKey:@"guestId"];
        }
        
        if ([customerId length] == 0) {
            return;
        }
        
        NSLog(@"CustomerId: %@", customerId);
        
        NSDictionary *pairs = @{@"AppInfo": [self getAppInfoDictionary], @"UserId":customerId};
        
        NSLog(@"Pairs: %@", pairs);
        
        NSString *requestString = [NSString stringWithFormat:@"%@", [pairs JSONRepresentation], nil];
        
        NSData *requestData = [NSData dataWithBytes: [requestString UTF8String] length: [requestString length]];
        
        
        //  NSLog(@"URL: %@", pingUrl);
        // NSLog(@"requestString: %@", requestString);
        
        //  NSLog(@"Auth Header: %@", [self authHeader]);
        
        NSString *eventString = [NSString stringWithFormat:@"getDeviceMessages - request url: %@", pingUrl];
        [rSkybox addEventToSession:eventString];
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:pingUrl]];
        
        [request setHTTPMethod: @"SEARCH"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[self authHeader] forHTTPHeaderField:@"Authorization"];
        [request setHTTPBody: requestData];
        
        
        self.serverData = [NSMutableData data];
        [rSkybox startThreshold:@"getDeviceMessages"];
        self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getDeviceMessages" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)mdata {
    @try {
        
        [self.serverData appendData:mdata];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.connection" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    self.httpStatusCode = [httpResponse statusCode];
    
    //NSLog(@"Server Call: %d", api);
   // NSLog(@"HTTP Status Code: %d", self.httpStatusCode);
    
    
    NSString *eventString = [NSString stringWithFormat:@"didRecieveResponse - server call: %@, http status: %d", [self apiToString], self.httpStatusCode];
    [rSkybox addEventToSession:eventString];
    
    
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    @try {
        
        NSString *logName = [NSString stringWithFormat:@"api.%@.threshold", [self apiToString]];
        [rSkybox endThreshold:logName logMessage:@"fake logMessage" maxValue:14000.00];
        
        NSData *returnData = [NSData dataWithData:self.serverData];
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
        
        NSLog(@"API: %@", [self apiToString]);
        NSLog(@"ReturnString: %@", returnString);
        
        
        NSString *eventString = [NSString stringWithFormat:@"connectionDidFinishLoading - server call: %@, response string: %@", [self apiToString], returnString];
        [rSkybox addEventToSession:eventString];
        
        
        
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *response = (NSDictionary *) [jsonParser objectWithString:returnString error:NULL];
        
        NSDictionary *responseInfo;
        NSString *notificationType;
        
        BOOL httpSuccess = self.httpStatusCode == 200 || self.httpStatusCode == 201 || self.httpStatusCode == 422;
        
        BOOL postNotification = YES;
        BOOL isGetServer = NO;

        if(api == CreateCustomer) { //jpw5
            postNotification = NO;
            if (response && httpSuccess) {
                responseInfo = [self createCustomerResponse:response];
            }else{
                postNotification = YES;

            }
            notificationType = @"registerNotification";
        } else if(api == UpdateGuestCustomer) {
        

            if (response && httpSuccess) {
                responseInfo = [self getUpdateGuestCustomerResponse:response];
            }
            notificationType = @"updateGuestCustomerNotification";
        }else if(api == GetCustomerToken) {
            if (response && httpSuccess) {
                responseInfo = [self getCustomerTokenResponse:response];
            }
            notificationType = @"signInNotification";
        } else if(api == GetGuestToken) {
            
            if (response && httpSuccess) {
                responseInfo = [self getGuestTokenResponse:response];
            }
            notificationType = @"signInNotificationGuest";
        }else if(api == GetMerchantList) {
            if (response && httpSuccess) {
                responseInfo = [self getMerchantListResponse:response];
            }
            notificationType = @"merchantListNotification";
        } else if(api == GetInvoice) {
            
            if (response && httpSuccess) {
                responseInfo = [self getInvoiceResponse:response];
            } else {
                BOOL successful = FALSE;
                [ArcClient endAndReportLatency:GetInvoice logMessage:@"GetInvoice API completed" successful:successful];
            }
            notificationType = @"invoiceNotification";
            
        } else if(api == CreatePayment) {
            
            postNotification = NO;
            if (response && httpSuccess) {
                responseInfo = [self createPaymentResponse:response];
            } else {
                BOOL successful = FALSE;
                postNotification = YES;
                [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreatePayment API completed" successful:successful];
            }
            notificationType = @"createPaymentNotification";
            
        } else if(api == CreateReview) {
            if (response && httpSuccess) {
                responseInfo = [self createReviewResponse:response];
            }
            notificationType = @"createReviewNotification";
        } else if(api == GetPointBalance) {
            
            notificationType = @"registerNotification";

            if (response && httpSuccess) {
                responseInfo = [self getPointBalanceResponse:response];
            }
            notificationType = @"getPointBalanceNotification";
        }  else if(api == GetPasscode) {
            if (response && httpSuccess) {
                responseInfo = [self getPasscodeResponse:response];
            }
            notificationType = @"getPasscodeNotification";
        } else if(api == ResetPassword) {
            if (response && httpSuccess) {
                responseInfo = [self resetPasswordResponse:response];
            }
            notificationType = @"resetPasswordNotification";
        }else if(api == TrackEvent) {
            if (response && httpSuccess) {
                //responseInfo = [self trackEventResponse:response];
            }
            postNotification = NO;
        }else if (api == GetServer){
            postNotification = NO;
            isGetServer = YES;
            if (response && httpSuccess) {
                [self setUrl:response];
            }
        }else if (api == SetAdminServer){
            if (response && httpSuccess) {
                responseInfo = [self setServerResponse:response];
            }
            notificationType = @"setServerNotification";

        }else if (api == UpdatePushToken){
            postNotification = NO;
        }else if (api == ReferFriend){
            if (response && httpSuccess) {
                responseInfo = [self referFriendResponse:response];
            }
            notificationType = @"referFriendNotification";
            
        }else if (api == ConfirmPayment){
            postNotification = NO;
            if (response && httpSuccess) {
                responseInfo = [self confirmPaymentResponse:response];
            }else{
                notificationType = @"createPaymentNotification";
                postNotification = YES;

            }
        }else if (api == ConfirmRegister){
            postNotification = NO;
            if (response && httpSuccess) {
                responseInfo = [self confirmRegisterResponse:response];
            }else{
                notificationType = @"registerNotification";
                postNotification = YES;
            }
        }else if (api == PingServer){
            postNotification = NO;
            if (response && httpSuccess) {
                responseInfo = [self pingServerResponse:response];
            }
        }else if (api == GetListOfServers){
            if (response && httpSuccess) {
                notificationType = @"getServerListNotification";

                responseInfo = [self getServerListResponse:response];
            }
        }else if (api == GetListOfPayments){
            if (response && httpSuccess) {
                notificationType = @"paymentHistoryNotification";
                
                responseInfo = [self getPaymentListResponse:response];
            }
        }else if (api == GetCreditCards){
            if (response && httpSuccess) {
                notificationType = @"creditCardNotification";
                
                responseInfo = [self getCreditCardResponse:response];
            }
        }else if (api == SendEmailReceipt){
            if (response && httpSuccess) {
                notificationType = @"sendEmailReceiptNotification";
                
                responseInfo = [self sendEmailReceiptResponse:response];
            }
        }else if (api == GetRecurringPayments){
            
            if (response && httpSuccess) {
                notificationType = @"getRecurringPaymentsNotification";
                
                responseInfo = [self getRecurringPaymentsResponse:response];
            }
            
        }else if (api == DeleteRecurringPayment){
            
            if (response && httpSuccess) {
                notificationType = @"deleteRecurringPaymentNotification";
                
                responseInfo = [self deleteRecurringPaymentResponse:response];
            }
            
            
        }else if (api == CreateReucrringPayment){
            
            if (response && httpSuccess) {
                notificationType = @"createRecurringPaymentNotification";
                
                responseInfo = [self createRecurringPaymentResponse:response];
            }
            
            
        }else if (api == CreateMultiplePayments){
            
            if (response && httpSuccess) {
                notificationType = @"createMultiplePaymentsNotification";
                
                responseInfo = [self createMultiplePaymentsResponse:response];
            }
            
            
        }else if (api == GetDeviceMessages){
            
            if (response && httpSuccess) {
                notificationType = @"getDeviceMessagesNotification";
                
                responseInfo = response;
            }
            
        }
        
        if(!httpSuccess) {
            // failure scenario -- HTTP error code returned -- for this processing, we don't care which API failed
            
            NSString *sendUrl = _arcUrl;
            if (isGetServer) {
                sendUrl = _arcServersUrl;
            }
            NSString *errorMsg = [NSString stringWithFormat:@"HTTP Status Code:%d for API %@ on %@", self.httpStatusCode, [self apiToString], sendUrl];
            responseInfo = @{@"status": @"fail", @"error": @0};
            [rSkybox sendClientLog:@"ArcClient.connectionDidFinishLoading" logMessage:errorMsg logLevel:@"error" exception:nil];
        }

        if (postNotification) {
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationType object:self userInfo:responseInfo];
        }
        
        [self displayErrorsToAdmins:response];
}
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.connectionDidFinishLoading" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    @try {
        [rSkybox endThreshold:@"ErrorEncountered" logMessage:@"NA" maxValue:0.00];
        
       // NSLog(@"API: %d", api);
        
       // NSLog(@"Error: %@", error);
        //NSLog(@"Code: %i", error.code);
        //NSLog(@"Description: %@", error.localizedDescription);

        
        NSString *eventString = [NSString stringWithFormat:@"connectionDidFailWithError - server call: %@, response error: %@", [self apiToString], [self readableErrorCode:error]];
        [rSkybox addEventToSession:eventString];
        
        NSString *urlString = [[[connection currentRequest] URL] absoluteString];
        
        // TODO make logType a function of the restaurant/location -- not sure the best way to do this yet
        NSString *logName = [NSString stringWithFormat:@"api.%@.%@ - %@", [self apiToString], [self readableErrorCode:error], urlString];
        
        if (api != PingServer && api != GetServer) {
            [rSkybox sendClientLog:logName logMessage:error.localizedDescription logLevel:@"error" exception:nil];
        }
        
        BOOL postNotification = YES;
        BOOL successful = FALSE;

        NSDictionary *responseInfo = @{@"status": @"fail", @"error": @0};
        NSString *notificationType;
        if(api == CreateCustomer) {
            postNotification = NO;
            NSString *status = @"error";
            int errorCode = NETWORK_ERROR;
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
            successful = FALSE;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"registerNotification" object:self userInfo:responseInfo];
            [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreatePayment API completed" successful:successful];
        } else if(api == UpdateGuestCustomer) {
            notificationType = @"updateGuestCustomerNotification";
        }else if(api == GetCustomerToken) {
            notificationType = @"signInNotification";
        }else if(api == GetCustomerToken) {
            notificationType = @"signInNotificationGuest";
        }
        else if(api == GetMerchantList) {
            notificationType = @"merchantListNotification";
        }else if(api == GetInvoice) {
            postNotification = NO;
            NSString *status = @"error";
            int errorCode = NETWORK_ERROR;
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
            successful = FALSE;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"invoiceNotification" object:self userInfo:responseInfo];
            
            [ArcClient endAndReportLatency:GetInvoice logMessage:@"GetInvoice API completed" successful:successful];
        } else if(api == CreatePayment) {
            
            
            postNotification = NO;
            NSString *status = @"error";
            int errorCode = NETWORK_ERROR;
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
            successful = FALSE;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"createPaymentNotification" object:self userInfo:responseInfo];
            [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreatePayment API completed" successful:successful];
            
            
            
        } else if(api == CreatePayment) {
            notificationType = @"createPaymentNotification";
            BOOL successful = FALSE;
            [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreatePayment API completed" successful:successful];
        } else if(api == CreateReview) {
            notificationType = @"createReviewNotification";
        } else if(api == GetPointBalance) {
            notificationType = @"getPointBalanceNotification";
        } else if(api == TrackEvent) {
            notificationType = @"trackEventNotification";   // posting notification for now, but nobody is listenting
        } else if(api == GetPasscode) {
            notificationType = @"getPasscodeNotification";
        } else if(api == ResetPassword) {
            notificationType = @"resetPasswordNotification";
        }else if (api == SetAdminServer){
            notificationType = @"setServerNotification";
        }else if (api == ConfirmPayment){
            
            if(error.code == -1003){
                //try again
                postNotification = NO;
                
                if (self.numberConfirmPaymentTries > [self.retryTimes count] - 1 ) {
                    
                    NSString *status = @"error";
                    int errorCode = NETWORK_ERROR_CONFIRM_PAYMENT;
                    responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
                    successful = FALSE;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"createPaymentNotification" object:self userInfo:responseInfo];
                    [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreatePayment API completed" successful:successful];
                    
                }else{
                    
                    int retryTime = [[self.retryTimes objectAtIndex:self.numberConfirmPaymentTries] intValue];
                    
                    self.myTimer = [NSTimer scheduledTimerWithTimeInterval:retryTime target:self selector:@selector(confirmPayment) userInfo:nil repeats:NO];
                }
                
            }else{
                
                
                postNotification = NO;
                NSString *status = @"error";
                int errorCode = NETWORK_ERROR_CONFIRM_PAYMENT;
                responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
                successful = FALSE;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"createPaymentNotification" object:self userInfo:responseInfo];
                [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreatePayment API completed" successful:successful];
                
                // notificationType = @"createPaymentNotification";
                
                
            }
            
        }else if (api == ConfirmRegister){
            
            if(error.code == -1003){
                //try again
                postNotification = NO;
                if (self.numberRegisterTries > [self.retryTimesRegister count] - 1 ) {
                    
                    NSString *status = @"error";
                    int errorCode = NETWORK_ERROR;
                    responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
                    successful = FALSE;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"registerNotification" object:self userInfo:responseInfo];
                    [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreateCustomer API completed" successful:successful];
                    
                }else{
                    
                    int retryTime = [[self.retryTimesRegister objectAtIndex:self.numberRegisterTries] intValue];
                    
                    self.myRegisterTimer = [NSTimer scheduledTimerWithTimeInterval:retryTime target:self selector:@selector(confirmRegister) userInfo:nil repeats:NO];
                }
                
            }else{
                
                postNotification = NO;
                NSString *status = @"error";
                int errorCode = NETWORK_ERROR;
                responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
                successful = FALSE;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"registerNotification" object:self userInfo:responseInfo];
                [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreatePayment API completed" successful:successful];
                
                //notificationType = @"registerNotification";
                
            }
        }else if (api == PingServer){
            postNotification = NO;
            responseInfo = [self pingServerResponse:nil];

        }else if (api == GetListOfServers){
            notificationType = @"getServerListNotification";
        }else if (api == GetListOfPayments){
            notificationType = @"paymentHistoryNotification";
        }else if (api == GetCreditCards){
            notificationType = @"creditCardNotification";
        }else if (api == SendEmailReceipt){
            notificationType = @"sendEmailReceiptNotification";
        }else if (api == GetRecurringPayments){
            notificationType = @"getRecurringPaymentsNotification";
        }else if (api == DeleteRecurringPayment){
            notificationType = @"deleteRecurringPaymentNotification";
        }else if (api == CreateReucrringPayment){
            notificationType = @"createRecurringPaymentNotification";
        }else if (api == CreateMultiplePayments){
            notificationType = @"createMultiplePaymentsNotification";
            
        }else if (api == GetDeviceMessages){
            notificationType = @"getDeviceMessagesNotification";
        }
        
        
        if (postNotification == YES) {
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationType object:self userInfo:responseInfo];
        }
        
        if (api != PingServer) {
            [self displayErrorMessageToAdmins:logName];
        }
        
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.connection" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
}

- (void)displayErrorsToAdmins:(NSDictionary *)response {
    if([self admin]) {
        //NSLog(@"user is an admin");
        
        NSMutableString* errorMsg = [NSMutableString string];
        NSArray *errorArr = [response valueForKey:@"ErrorCodes"];
        NSEnumerator *e = [errorArr objectEnumerator];
        NSDictionary *dict;
        while (dict = [e nextObject]) {
            int code = [[dict valueForKey:@"Code"] intValue];
            NSString *category = [dict valueForKey:@"Category"];
            [errorMsg appendFormat:@"code:%d category:%@", code, category];
        }
        
        if([errorMsg length] > 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"For Admins Only"  message:[NSString stringWithString:errorMsg] delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            [alert show];
        }
        
    }
    
}

- (void)displayErrorMessageToAdmins:(NSString *)errorMsg {
    if([self admin]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"For Admins Only"  message:errorMsg delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [alert show];
    }
    
}

- (int)getErrorCode:(NSDictionary *)response {
    @try {
        int errorCode = 0;
        NSDictionary *error = [[response valueForKey:@"ErrorCodes"] objectAtIndex:0];
        errorCode = [[error valueForKey:@"Code"] intValue];
        return errorCode;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getErrorCode" logMessage:@"Exception Caught" logLevel:@"error" exception:e];

        return 0;
    }
   
}

-(NSString *)readableErrorCode:(NSError *)error {
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

- (NSString*)apiToString {
    NSString *result = nil;
    
    switch(api) {
        case GetServer:
            result = @"GetServer";
            break;
        case CreateCustomer:
            result = @"CreateCustomer";
            break;
        case GetCustomerToken:
            result = @"GetCustomerToken";
            break;
        case GetGuestToken:
            result = @"GetGuestToken";
            break;
        case GetMerchantList:
            result = @"GetMerchantList";
            break;
        case GetInvoice:
            result = @"GetInvoice";
            break;
        case CreatePayment:
            result = @"CreatePayment";
            break;
        case CreateReview:
            result = @"CreateReview";
            break;
        case GetPointBalance:
            result = @"GetPointBalance";
            break;
        case TrackEvent:
            result = @"TrackEvent";
            break;
        case GetPasscode:
            result = @"GetPasscode";
            break;
        case ResetPassword:
            result = @"ResetPassword";
            break;
        case SetAdminServer:
            result = @"SetAdminServer";
            break;
            
        case UpdatePushToken:
            result = @"UpdatePushToken";
            break;
            
        case ReferFriend:
            result = @"ReferFriend";
            break;
            
        case ConfirmPayment:
            result = @"ConfirmPayment";
            break;
            
        case ConfirmRegister:
            result = @"ConfirmRegister";
            break;
            
        case UpdateGuestCustomer:
            result = @"UpdateGuestCustomer";
            break;
            
        case PingServer:
            result = @"PingServer";
            break;
            
        case GetListOfServers:
            result = @"GetListOfServers";
            break;
            
        case GetListOfPayments:
            result = @"GetListOfPayments";
            break;
            
        case SendEmailReceipt:
            result = @"SendEmailReceipt";
            break;
            
        case GetCreditCards:
            result = @"GetCreditCards";
            break;
            
        case GetRecurringPayments:
            result = @"GetRecurringPayments";
            break;
            
        case DeleteRecurringPayment:
            result = @"DeleteRecurringPayment";
            break;
            
        case CreateReucrringPayment:
            result = @"CreateReucrringPayment";
            break;
            
        case CreateMultiplePayments:
            result = @"CreateMultiplePayments";
            break;
            
        case GetDeviceMessages:
            result = @"GetDeviceMessages";
            break;

            
     
            
            
        default:
            //[NSException raise:NSGenericException format:@"Unexpected FormatType."];
            break;
    }
    
    return result;
}

-(NSDictionary *) createCustomerResponse:(NSDictionary *)response {
    @try {
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            
            self.registerTicketId = [response valueForKey:@"Results"];
            
            self.numberRegisterTries = 0;
            
            int retryTime = [[self.retryTimesRegister objectAtIndex:self.numberRegisterTries] intValue];
            
            self.myRegisterTimer = [NSTimer scheduledTimerWithTimeInterval:retryTime target:self selector:@selector(confirmRegister) userInfo:nil repeats:NO];
            
            
         
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"registerNotification" object:self userInfo:responseInfo];
            [ArcClient endAndReportLatency:CreateCustomer logMessage:@"CreateCustomer API completed" successful:success];
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        
        NSString *status = @"error";
        NSDictionary *responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:9999]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"registerNotification" object:self userInfo:responseInfo];
        
        
        [rSkybox sendClientLog:@"ArcClient.createCustomerResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
    }
}


-(NSDictionary *) getUpdateGuestCustomerResponse:(NSDictionary *)response {
    @try {
        

        //NSLog(@"Response: %@", response);
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        
        
        if (success){
            
            @try {
                if ([[response valueForKey:@"ErrorCodes"] count] > 0 && [[response valueForKey:@"Results"] length] == 0) {
                    NSString *status = @"error";
                    int errorCode = [self getErrorCode:response];
                    responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
                    return responseInfo;
                }
            }
            @catch (NSException *exception) {

            }
            
        
            
            responseInfo = @{@"status": @"success", @"Results":[response valueForKey:@"Results"]};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getUpdateGuestCustomerResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
}




-(NSDictionary *) getCustomerTokenResponse:(NSDictionary *)response {
    @try {
        
       // NSLog(@"Response: %@", response);
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            
            NSDictionary *customer = [response valueForKey:@"Results"];
            NSString *customerId = [[customer valueForKey:@"Id"] stringValue];
            NSString *customerToken = [customer valueForKey:@"Token"];
            BOOL admin = [[customer valueForKey:@"Admin"] boolValue];
            //admin = YES; // for testing admin role
            
            NSString *firstName = @"";
            NSString *lastName = @"";
            
            if ([[customer valueForKey:@"FirstName"] length] > 0) {
                firstName = [customer valueForKey:@"FirstName"];
            }
            
            if ([[customer valueForKey:@"LastName"] length] > 0) {
                lastName = [customer valueForKey:@"LastName"];
            }

            
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            
            [prefs setObject:customerId forKey:@"customerId"];
            [prefs setObject:customerToken forKey:@"customerToken"];
            NSNumber *adminAsNum = [NSNumber numberWithBool:admin];
            [prefs setObject:adminAsNum forKey:@"admin"];
            
            [prefs setValue:firstName forKey:@"customerFirstName"];
            [prefs setValue:lastName forKey:@"customerLastName"];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            
            [prefs synchronize];
            
            //Add this customer to the DB
            [self performSelector:@selector(addToDatabase) withObject:nil afterDelay:1.5];
            
            responseInfo = @{@"status": @"success"};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getCustomerTokenResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};

    }
}


-(NSDictionary *) getGuestTokenResponse:(NSDictionary *)response {
    @try {
        
    //    NSLog(@"GUEST TOKEN RESPONSE: %@", response);
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            
            NSDictionary *customer = [response valueForKey:@"Results"];
            NSString *customerId = [[customer valueForKey:@"Id"] stringValue];
            NSString *customerToken = [customer valueForKey:@"Token"];
 
           // NSLog(@"CustomerToken: %@", customerToken);
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            
            [prefs setObject:customerId forKey:@"guestId"];
            [prefs setObject:customerToken forKey:@"guestToken"];
            
            NSNumber *adminAsNum = [NSNumber numberWithBool:NO];
            [prefs setObject:adminAsNum forKey:@"admin"];
            [prefs synchronize];
            
            //Add this customer to the DB
            //[self performSelector:@selector(addToDatabase) withObject:nil afterDelay:1.5];
            
            responseInfo = @{@"status": @"success"};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getGuestTokenResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
}



-(NSDictionary *) getMerchantListResponse:(NSDictionary *)response {
    @try {
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getMerchantListResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};

    }
}



-(NSDictionary *) getServerListResponse:(NSDictionary *)response {
    @try {
       //
       // NSLog(@"Response: %@", response);
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getServerListResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
}

-(NSDictionary *) sendEmailReceiptResponse:(NSDictionary *)response {
    @try {
        //
        // NSLog(@"Response: %@", response);
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.sendEmailReceiptResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
}


-(NSDictionary *) getCreditCardResponse:(NSDictionary *)response {
    @try {
        //
        // NSLog(@"Response: %@", response);
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getCreditCardResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
}


-(NSDictionary *) deleteRecurringPaymentResponse:(NSDictionary *)response {
    @try {
        //
        // NSLog(@"Response: %@", response);
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getCreditCardResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
}


-(NSDictionary *) createRecurringPaymentResponse:(NSDictionary *)response {
    @try {
        //
        // NSLog(@"Response: %@", response);
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.createRecurringPaymentResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
}

-(NSDictionary *) createMultiplePaymentsResponse:(NSDictionary *)response {
    @try {
        //
        // NSLog(@"Response: %@", response);
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            responseInfo = @{@"status": @"error", @"apiResponse": response};

            //NSString *status = @"error";
            //int errorCode = [self getErrorCode:response];
            //responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.createMultiplePaymentsResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
}

-(NSDictionary *) getRecurringPaymentsResponse:(NSDictionary *)response {
    @try {
        //
        // NSLog(@"Response: %@", response);
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getCreditCardResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
}



-(NSDictionary *) getPaymentListResponse:(NSDictionary *)response {
    @try {
        //
        // NSLog(@"Response: %@", response);
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getPaymentListResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
}



-(void)recallGetInvoice{
    
    [self getInvoice:nil];
}

-(NSDictionary *) getInvoiceResponse:(NSDictionary *)response {
    
   
    @try {
        //
         //NSLog(@"Response: %@", response);
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
        
    }@catch (NSException *e) {
        
        NSString *status = @"error";
        NSDictionary *responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:9999]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"invoiceNotification" object:self userInfo:responseInfo];
        
        
        
        [rSkybox sendClientLog:@"ArcClient.getInvoiceResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
    

    
}
  
    
    

-(NSDictionary *) createPaymentResponse:(NSDictionary *)response {
    @try {
            
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        BOOL successful = TRUE;
        if (success){
            
            self.ticketId = [response valueForKey:@"Results"];

            self.numberConfirmPaymentTries = 0;
          
            int retryTime = [[self.retryTimes objectAtIndex:self.numberConfirmPaymentTries] intValue];
            
            self.myTimer = [NSTimer scheduledTimerWithTimeInterval:retryTime target:self selector:@selector(confirmPayment) userInfo:nil repeats:NO];
            
            
            //responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
            successful = FALSE;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"createPaymentNotification" object:self userInfo:responseInfo];
            [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreatePayment API completed" successful:successful];

        }
        

        return responseInfo;
    }
    @catch (NSException *e) {
        
        NSString *status = @"error";
        NSDictionary *responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:9999]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"createPaymentNotification" object:self userInfo:responseInfo];
        
        
        [rSkybox sendClientLog:@"ArcClient.createPaymentResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};

    }
}

-(NSDictionary *) confirmPaymentResponse:(NSDictionary *)response {
    @try {
        

       // NSLog(@"Response: %@", response);
        
        
        self.numberConfirmPaymentTries++;
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        BOOL successful = TRUE;
        
        if (success){
            
            responseInfo = @{@"status": @"success", @"apiResponse": response};
            
            if ([response valueForKey:@"Results"]) {
                //complete successfully
                   [[NSNotificationCenter defaultCenter] postNotificationName:@"createPaymentNotification" object:self userInfo:responseInfo];
                [ArcClient endAndReportLatency:ConfirmPayment logMessage:@"CreatePayment API completed" successful:successful];

            }else{
                
                if (self.numberConfirmPaymentTries > [self.retryTimes count] - 1 ) {
                    
                    NSString *status = @"error";
                    int errorCode = MAX_RETRIES_EXCEEDED;
                    responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
                    successful = FALSE;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"createPaymentNotification" object:self userInfo:responseInfo];
                    [ArcClient endAndReportLatency:ConfirmPayment logMessage:@"CreatePayment API completed" successful:successful];

                }else{
                    
                    int retryTime = [[self.retryTimes objectAtIndex:self.numberConfirmPaymentTries] intValue];

                    self.myTimer = [NSTimer scheduledTimerWithTimeInterval:retryTime target:self selector:@selector(confirmPayment) userInfo:nil repeats:NO];
                }
            }
                     
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
            successful = FALSE;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"createPaymentNotification" object:self userInfo:responseInfo];
            [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreatePayment API completed" successful:successful];

        }
        
        
        return responseInfo;
    }
    @catch (NSException *e) {
        
        NSString *status = @"error";
        NSDictionary *responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:9999]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"createPaymentNotification" object:self userInfo:responseInfo];
        
        
        [rSkybox sendClientLog:@"ArcClient.confirmPaymentResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
}


-(NSDictionary *)confirmRegisterResponse:(NSDictionary *)response {
    @try {
        
        self.numberRegisterTries++;
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        BOOL successful = TRUE;
        if (success){
            
         
 
            if ([response valueForKey:@"Results"]) {
                //complete successfully
                
                NSDictionary *customer = [response valueForKey:@"Results"];
                NSString *customerId = [[customer valueForKey:@"Id"] stringValue];
                NSString *customerToken = [customer valueForKey:@"Token"];
                
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                
                [prefs setObject:customerId forKey:@"customerId"];
                [prefs setObject:customerToken forKey:@"customerToken"];
                [prefs synchronize];
                
                //Add this customer to the DB
                // TODO is this still needed?
                [self performSelector:@selector(addToDatabase) withObject:nil afterDelay:1.5];
                
                responseInfo = @{@"status": @"success"};
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"registerNotification" object:self userInfo:responseInfo];
                [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreateCustomer API completed" successful:successful];
                
            }else{
                
                
                if (self.numberRegisterTries > [self.retryTimesRegister count] - 1) {
                    
                    NSString *status = @"error";
                    int errorCode = MAX_RETRIES_EXCEEDED;
                    responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
                    successful = FALSE;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"registerNotification" object:self userInfo:responseInfo];
                    [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreateCustomer API completed" successful:successful];
                    
                }else{
                    
                    int retryTime = [[self.retryTimesRegister objectAtIndex:self.numberRegisterTries] intValue];
                    
                    self.myRegisterTimer = [NSTimer scheduledTimerWithTimeInterval:retryTime target:self selector:@selector(confirmRegister) userInfo:nil repeats:NO];
                }
            }
            
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
            successful = FALSE;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"registerNotification" object:self userInfo:responseInfo];
            [ArcClient endAndReportLatency:CreatePayment logMessage:@"CreateCustomer API completed" successful:successful];
            
        }
        
        
        return responseInfo;
    }
    @catch (NSException *e) {
        NSString *status = @"error";
        NSDictionary *responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:9999]};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"registerNotification" object:self userInfo:responseInfo];
        
        
        [rSkybox sendClientLog:@"ArcClient.confirmRegisterResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
}


-(NSDictionary *) createReviewResponse:(NSDictionary *)response {
    @try {
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.createReviewResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};

    }
    
}


-(NSDictionary *)pingServerResponse:(NSDictionary *)response {
    @try {
        
        NSTimeInterval milliseconds = [[NSDate date] timeIntervalSinceDate:self.pingStartTime] * 1000;

        [self.serverPingArray addObject:[NSNumber numberWithDouble:milliseconds]];
        
        if (self.numberServerPings < 4) {
            //send again
            [self sendServerPings];
        }else{
            //calculate average, store in user defaults
            
            double total;
            for (int i = 0; i < [self.serverPingArray count]; i++) {
                
                total += [[self.serverPingArray objectAtIndex:i] doubleValue];
            }
            
            double average = total / (double)[self.serverPingArray count];
            
            NSString *averageTime = [NSString stringWithFormat:@"%.2f", average];
            
            
            [[NSUserDefaults standardUserDefaults] setValue:averageTime forKey:@"averageServerPingTime"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [ArcClient trackEvent:@"GET_SIGNAL_STRENGTH"];
        }
        
        self.numberServerPings ++;
        
        
        return [NSDictionary dictionary];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.pingServerResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
        
    }
    
}

-(NSDictionary *) getPointBalanceResponse:(NSDictionary *)response {
    
    @try {
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getPointBalanceResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
    }
    
 
}

-(NSDictionary *) getPasscodeResponse:(NSDictionary *)response {
    
    @try {
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.getPasscodeResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
    }
    
    
}

-(NSDictionary *) resetPasswordResponse:(NSDictionary *)response {
    
    @try {
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.resetPasswordResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
    }
    
    
}

-(NSDictionary *) setServerResponse:(NSDictionary *)response {
    
    @try {
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.setServerResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
    }
    
    
}

-(NSDictionary *) referFriendResponse:(NSDictionary *)response {
    
    @try {
        
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.setServerResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
    }
    
    
}

-(NSDictionary *) trackEventResponse:(NSDictionary *)response {
    @try {
        BOOL success = [[response valueForKey:@"Success"] boolValue];
        
        NSDictionary *responseInfo;
        if (success){
            responseInfo = @{@"status": @"success", @"apiResponse": response};
        } else {
            NSString *status = @"error";
            int errorCode = [self getErrorCode:response];
            responseInfo = @{@"status": status, @"error": [NSNumber numberWithInt:errorCode]};
        }
        return responseInfo;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.trackEventResponse" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @{};
    }
    
}


-(NSString *) authHeader {
    @try {
        
        
        NSString *customerToken = [self customerToken];
        NSString *guestToken = [self guestToken];


        if (customerToken) {
            
            //NSLog(@"CustomerToken: %@", customerToken);
            
            NSString *stringToEncode = [@"customer:" stringByAppendingString:customerToken];
            NSString *authentication = [self encodeBase64:stringToEncode];
            
            return [@"Basic " stringByAppendingString:customerToken];
            return authentication;
        }else{
            
            
            
            if ([guestToken length] > 0) {
                //Guest
               // NSLog(@"GuestTOken: %@", guestToken);
                
                NSString *stringToEncode = [@"customer:" stringByAppendingString:guestToken];
                NSString *authentication = [self encodeBase64:stringToEncode];
                
                return [@"Basic " stringByAppendingString:guestToken];
                return authentication;
            }else{
                return @"";
                
            }
            
            
            
           
            
            
        }
        
        return @"";
        
    }
    @catch (NSException *e) {
        return @"";
        [rSkybox sendClientLog:@"ArcClient.authHeader" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void) addToDatabase {
    @try {
        
       // NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
       // NSString *customerId = [prefs valueForKey:@"customerId"];
      //  NSString *customerToken = [prefs valueForKey:@"customerToken"];
        
       // AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        //[mainDelegate insertCustomerWithId:customerId andToken:customerToken];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.addToDatabase" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(NSString *) customerToken {
    @try {
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *customerToken = [prefs valueForKey:@"customerToken"];
        return customerToken;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.customerToken" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @"";
    }
}

-(NSString *) guestToken {
    @try {
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *guestToken = [prefs valueForKey:@"guestToken"];
        //NSLog(@"Guest Token: %@", guestToken);
        
        return guestToken;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.guestToken" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @"";
    }
}

-(BOOL) admin {
    @try {
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        BOOL admin = [[prefs valueForKey:@"admin"] boolValue];
        return admin;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.admin" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return NO;
    }
}

-(NSString *)encodeBase64:(NSString *)stringToEncode{	
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
        [rSkybox sendClientLog:@"ArcClient.encodeBase64" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        return @"";
    }
}


-(void)setUrl:(NSDictionary *)response{
    @try{
        
        
     //   NSLog(@"Response: %@", response);
        
        if ([[response valueForKey:@"Success"] boolValue]) {
            
            NSString *serverName = [[response valueForKey:@"Results"] valueForKey:@"Server"];
            BOOL isSSL = [[[response valueForKey:@"Results"] valueForKey:@"SSL"] boolValue];
            NSString *arcTwitterHandler = [[response valueForKey:@"Results"] valueForKey:@"ArcTwitterHandler"];
            NSString *arcFacebookHandler = [[response valueForKey:@"Results"] valueForKey:@"ArcFacebookHandler"];
            NSString *arcPhoneNumber = [[response valueForKey:@"Results"] valueForKey:@"ArcPhoneNumber"];
            NSString *arcMail = [[response valueForKey:@"Results"] valueForKey:@"ArcMail"];
            NSString *userStatus = [[response valueForKey:@"Results"] valueForKey:@"UserStatus"];
            NSString *loginType = [[response valueForKey:@"Results"] valueForKey:@"LoginType"];
            
            
            if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"didShowVersionWarning"] length] == 0) {
                
                NSString *iosVerion = [[response valueForKey:@"Results"] valueForKey:@"VersionIOS"];
                
                if ([iosVerion length] > 0) {
                    
                                    
                    if ([iosVerion compare:ARC_VERSION_NUMBER options:NSNumericSearch] == NSOrderedDescending) {
                        // ARC_VERSION_NUMBER is lower than the iosVersion
                        [[NSUserDefaults standardUserDefaults] setValue:@"yes" forKey:@"didShowVersionWarning"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                      //  AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                       // [mainDelegate showNewVersionAlert];
                    }
                    
                    
                    
                }

            }
            
            
            if (serverName && ([serverName length] > 0)) {
                NSString *scheme = @"https";
                if(!isSSL) scheme = @"http";
                NSString *arcUrl = [NSString stringWithFormat:@"%@://%@/rest/v1/", scheme, serverName];
                
                [[NSUserDefaults standardUserDefaults] setValue:arcUrl forKey:@"arcUrl"];
            }
            
            if(arcFacebookHandler == nil) {arcFacebookHandler = @"ArcMobileApp";}
            
            [[NSUserDefaults standardUserDefaults] setValue:arcTwitterHandler forKey:@"arcTwitterHandler"];
            [[NSUserDefaults standardUserDefaults] setValue:arcFacebookHandler forKey:@"arcFacebookHandler"];
            [[NSUserDefaults standardUserDefaults] setValue:arcPhoneNumber forKey:@"arcPhoneNumber"];
            [[NSUserDefaults standardUserDefaults] setValue:arcMail forKey:@"arcMail"];
            [[NSUserDefaults standardUserDefaults] setValue:loginType forKey:@"arcLoginType"];
            
            // if account is now inactive, clear out the token and go to login screen
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            NSString *customerToken = [prefs valueForKey:@"customerToken"];
            if([userStatus isEqualToString:@"I"] && customerToken != nil) {
                [prefs setObject:nil forKey:@"customerToken"];
                //NSLog(@"GetToken returned UserStatus Inactive -- token has been cleared");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"customerDeactivatedNotification" object:self userInfo:nil];

            }

            [[NSUserDefaults standardUserDefaults] synchronize];
        
        }
        
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.setUrl" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

+(void)trackEvent:(NSString *)action{
    @try{
        NSNumber *measureValue = @1.0F;
        [ArcClient trackEvent:action activityType:@"Analytics" measureType:@"Count" measureValue:measureValue successful:TRUE];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.trackEventAction" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


+(void)trackEvent:(NSString *)activity activityType:(NSString *)activityType measureType:(NSString *)measureType measureValue:(NSNumber *)measureValue successful:(BOOL)successful{
    @try{
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
		NSDictionary *trackEventDict = [[NSDictionary alloc] init];
        
        
        @try {
            [ tempDictionary setObject:[[NSUserDefaults standardUserDefaults] valueForKey:@"merchantId"] forKey:@"MerchantId"];
        }
        @catch (NSException *exception) {
            
        }
       
        
    
        
        [ tempDictionary setObject:activity forKey:@"Activity"]; //ACTION
        [ tempDictionary setObject:activityType forKey:@"ActivityType"]; //CATEGORY

        AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        @try {
            NSString *customerId = [mainDelegate getCustomerId];
            [ tempDictionary setObject:customerId forKey:@"EntityId"]; //get from auth header?
        }
        @catch (NSException *exception) {
            [ tempDictionary setObject:@"" forKey:@"EntityId"]; //get from auth header?

        }
     
        NSDate *currentDate = [NSDate date];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        
        [tempDictionary setObject:[dateFormat stringFromDate:currentDate] forKey:@"EventDate"];
     
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
        NSString *loginType = [prefs valueForKey:@"arcLoginType"];
        if ([prefs valueForKey:@"arcLoginType"]) {
            [tempDictionary setObject:loginType forKey:@"EntityType"];
        }else{
            [tempDictionary setObject:@"LOGIN_TYPE_CUSTOMER" forKey:@"EntityType"];
        }
        
        [ tempDictionary setObject:@0.0 forKey:@"Latitude"];//optional
        [ tempDictionary setObject:@0.0 forKey:@"Longitude"];//optional
        [ tempDictionary setObject:measureType forKey:@"MeasureType"];//LABEL
        [ tempDictionary setObject:measureValue forKey:@"MeasureValue"];//VALUE
        [ tempDictionary setObject:@"Dono" forKey:@"Application"];
        
        //Location
        //if ([mainDelegate.lastLongitude length] > 0) {
       //     [tempDictionary setValue:[NSNumber numberWithDouble:[mainDelegate.lastLatitude doubleValue]] forKey:@"Latitude"];
       //     [tempDictionary setValue:[NSNumber numberWithDouble:[mainDelegate.lastLongitude doubleValue]] forKey:@"Longitude"];
       // }
        
        //PingServerResults
        if ([activity isEqualToString:@"GET_SIGNAL_STRENGTH"]) {
            @try {
                NSString *averageTime = [[NSUserDefaults standardUserDefaults] valueForKey:@"averageServerPingTime"];
                
                [ tempDictionary setObject:@"SIGNAL" forKey:@"MeasureType"];//LABEL
                [ tempDictionary setObject:averageTime forKey:@"MeasureValue"];//VALUE
                [ tempDictionary setObject:@"ANALYTICS" forKey:@"ActivityType"];//VALUE
            }
            @catch (NSException *exception) {
                
            }
        }
        
        NSString *mobileCarrier = @"UNKNOWN";
        @try {
            CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
            CTCarrier *carrier = [netinfo subscriberCellularProvider];
            mobileCarrier = [carrier carrierName];
            [ tempDictionary setObject:mobileCarrier forKey:@"Carrier"]; //TODO add real carrier
        }
        @catch (NSException *exception) {

        }

        //[ tempDictionary setObject:@"Profile page viewed" forKey:@"Description"]; //Jim removed description
        [ tempDictionary setObject:@"iOS" forKey:@"Source"];
        [ tempDictionary setObject:@"phone" forKey:@"SourceType"];//remove
        [ tempDictionary setObject:ARC_VERSION_NUMBER forKey:@"Version"];
        if(successful) {
            [ tempDictionary setObject:@(YES) forKey:@"Successful"];
        } else {
            [ tempDictionary setObject:@(NO) forKey:@"Successful"];
        }
        
		trackEventDict = tempDictionary;

        ArcClient *client = [[ArcClient alloc] init];
        [client trackEvent:trackEventDict];
        
    }
    @catch (NSException *e) {
                
        [rSkybox sendClientLog:@"ArcClient.trackEventActivity" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

+(void)startLatency:(APIS)api{
    @try{
        NSDate *startTime = [NSDate date];
        [latencyStartTimes setObject:startTime forKey:[NSNumber numberWithInt:api]];
        //NSLog(@"size of latencyStartTimes dictionary = %d", [latencyStartTimes count]);
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.startLatency" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

+(void)endAndReportLatency:(APIS)api logMessage:(NSString *)logMessage successful:(BOOL)successful {
    @try{
        NSDate *startTime = [latencyStartTimes objectForKey:[NSNumber numberWithInt:api]];
        if(startTime == nil) {
            //NSLog(@"endLatency() could not retrieve startTime");
            return;
        }
        
        NSString *activity = @"UNKNOWN_API";
        NSString *apiName = @"";
        if(api == GetInvoice) {
            activity = @"LATENCY_INVOICES_GET";
            apiName = @"Get Invoice";
        } else if(api == CreatePayment) {
            activity = @"LATENCY_PAYMENT_POST";
            apiName = @"Create Payment";
        } 
        NSTimeInterval milliseconds = [[NSDate date] timeIntervalSinceDate:startTime] * 1000;
        NSInteger roundedMilliseconds = milliseconds;
        //NSLog(@"total latency for %@ API in milliseconds = %@", apiName, [NSString stringWithFormat:@"%d", roundedMilliseconds]);
        
        
        [ArcClient trackEvent:activity activityType:@"Performance" measureType:@"Milliseconds" measureValue:[NSNumber numberWithInt:roundedMilliseconds] successful:successful];

    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"ArcClient.endAndReportLatency" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


-(void)cancelConnection{
    @try {
        [self.urlConnection cancel];
    }
    @catch (NSException *exception) {
        [rSkybox sendClientLog:@"ArcClient.cancelConnection" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
    }
  
}


-(NSString *)getLocalEndpoint{
    
    @try {
        NSString *localEndpoint = @"leye.ios";
        
        NSString *myString = @"prd.";
    #if DEBUG==1
        myString = @"dev.";
    #endif
        
        localEndpoint = [myString stringByAppendingString:localEndpoint];

        
        return localEndpoint;
    }
    @catch (NSException *exception) {
        return @"ERROR";
    }
  
}

-(NSString *)getRemoteEndpoint{
    
    @try {
        NSString *remote = [_arcUrl stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        remote = [remote stringByReplacingOccurrencesOfString:@"https://" withString:@""];
        remote = [remote stringByReplacingOccurrencesOfString:@"/rest/v1/" withString:@""];
        
        return remote;
    }
    @catch (NSException *exception) {
        return @"ERROR";
    }
   
}

-(NSDictionary *)getAppInfoDictionary{
    
    NSString *version = ARC_VERSION_NUMBER;
    return @{@"App": @"LEYE", @"OS":@"IOS", @"Version":version};
}
@end
