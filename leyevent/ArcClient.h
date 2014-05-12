//
//  ArcClient.h
//  ARC
//
//  Created by Joseph Wroblewski on 8/5/12.
//
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

extern int const USER_ALREADY_EXISTS;
extern int const INCORRECT_PASSCODE;
extern int const INCORRECT_LOGIN_INFO;
extern int const INVOICE_CLOSED;
extern int const INVOICE_NOT_FOUND;
extern int const CANNOT_PROCESS_PAYMENT;
extern int const MERCHANT_CANNOT_ACCEPT_PAYMENT_TYPE;
extern int const OVER_PAID;
extern int const INVALID_AMOUNT;
extern int const CANNOT_TRANSFER_TO_SAME_ACCOUNT;
extern int const FAILED_TO_VALIDATE_CARD;
extern int const FIELD_FORMAT_ERROR;
extern int const INVALID_ACCOUNT_NUMBER;
extern int const CANNOT_GET_PAYMENT_AUTHORIZATION;
extern int const INVALID_ACCOUNT_PIN;
extern int const INSUFFICIENT_FUNDS;
extern int const UNKOWN_ISIS_ERROR;
extern int const INVALID_EXPIRATION_DATE;
extern int const PAYMENT_MAYBE_PROCESSED;
extern int const DUPLICATE_TRANSACTION;
extern int const MAX_RETRIES_EXCEEDED;
extern int const CARD_ALREADY_PROCESSED;
extern int const CHECK_IS_LOCKED;
extern int const NO_AUTHORIZATION_PROVIDED;
extern int const NETWORK_ERROR_CONFIRM_PAYMENT;
extern int const NETWORK_ERROR;
extern int const PAYMENT_POSSIBLE_SUCCESS;
extern int const INVALID_SECURITY_PIN;

extern NSString *const ARC_ERROR_MSG;

typedef enum {
    GetServer = 0,
    CreateCustomer=1,
    GetCustomerToken=2,
    GetMerchantList=3,
    GetInvoice=4,
    CreatePayment=5,
    CreateReview=6,
    GetPointBalance=7,
    TrackEvent=8,
    GetPasscode=9,
    ResetPassword = 10,
    SetAdminServer = 11,
    UpdatePushToken = 12,
    ReferFriend = 13,
    ConfirmPayment = 14,
    ConfirmRegister = 15,
    PingServer = 16,
    GetGuestToken = 17,
    UpdateGuestCustomer = 18,
    GetListOfServers = 19,
    GetListOfPayments = 20,
    SendEmailReceipt = 21,
    GetCreditCards = 22,
    GetRecurringPayments = 23,
    DeleteRecurringPayment = 24,
    CreateReucrringPayment = 25,
    GetDeviceMessages = 26,
    CreateMultiplePayments = 27





} APIS;

@interface ArcClient : NSObject <NSURLConnectionDelegate> {
    APIS api;
}

@property (nonatomic, strong) NSArray *retryTimes;
@property int numberConfirmPaymentTries;
@property int numberRegisterTries;
@property int numberGetInvoiceTries;

@property int numberServerPings;
@property NSDate *pingStartTime;
@property (nonatomic, strong) NSMutableArray *serverPingArray;

@property (nonatomic, strong) NSString *getInvoiceInvoiceNumber;
@property (nonatomic, strong) NSString *getInvoiceMerchantId;

@property (nonatomic, strong) NSArray *retryTimesRegister;
@property (nonatomic, strong) NSTimer *myRegisterTimer;


@property (nonatomic, strong) NSString *ticketId;
@property (nonatomic, strong) NSString *registerTicketId;

@property (nonatomic, strong) NSArray *retryTimesInvoice;
@property (nonatomic, strong) NSTimer *myInvoiceTimer;
@property (nonatomic, strong) NSString *invoiceTicketId;
@property (nonatomic, strong) NSString *invoiceRequestId;

@property (nonatomic, strong) NSTimer *myTimer;
@property (nonatomic, strong) NSMutableData *serverData;
@property int httpStatusCode;
@property (nonatomic, strong) NSURLConnection *urlConnection;

-(void)createCustomer:(NSDictionary *)pairs;
-(NSDictionary *) createCustomerResponse:(NSDictionary *)response;

-(void)getCustomerToken:(NSDictionary *)pairs;
-(NSDictionary *) getCustomerTokenResponse:(NSDictionary *)response;

-(void)getMerchantList:(NSDictionary *)pairs;
-(NSDictionary *) getMerchantListResponse:(NSDictionary *)response;

-(void)getInvoice:(NSDictionary *)pairs;
-(NSDictionary *) getInvoiceResponse:(NSDictionary *)response;

-(void)createPayment:(NSDictionary *)pairs;
-(NSDictionary *) createPaymentResponse:(NSDictionary *)response;

-(void)createReview:(NSDictionary *)pairs;
-(NSDictionary *) createReviewResponse:(NSDictionary *)response;

-(void)getPointBalance:(NSDictionary *)pairs;
-(NSDictionary *) getPointBalanceResponse:(NSDictionary *)response;

-(void)trackEvent:(NSDictionary *)pairs;
-(NSDictionary *) trackEventResponse:(NSDictionary *)response;

-(void)getPasscode:(NSDictionary *)pairs;
-(void)resetPassword:(NSDictionary *)pairs;

-(void)getServer;
-(void)setServer:(NSString *)serverNumber;

-(BOOL) admin;

-(NSString *)getCurrentUrl;
-(void)referFriend:(NSArray *)emailAddresses;

+(void)trackEvent:(NSString *)action;

-(void)getGuestToken:(NSDictionary *)pairs;
-(void)confirmPayment;

// Footprint analytics
+(void)startLatency:(APIS)api;
//+(void)endAndReportLatency:(APIS)api logMessage:(NSString *)logMessage;

-(void)updatePushToken;

-(void)cancelConnection;

-(void)sendTrackEvent:(NSMutableArray *)array;

-(void)sendServerPings;

-(void)updateGuestCustomer:(NSDictionary *)pairs;

-(void)getListOfServers;
-(void)getListOfPayments;
-(void)sendEmailReceipt:(NSDictionary *)pairs;

-(NSString *)getLocalEndpoint;
-(NSString *)getRemoteEndpoint;
-(NSString *) authHeader;
-(void)getListOfCreditCards;


-(void)getListOfRecurringPayments;
-(void)deleteRecurringPayment:(NSString *)paymentId;
-(void)createRecurringPayment:(NSDictionary *)pairs;

-(void)getDeviceMessages;

-(void)createMultiplePayments:(NSDictionary *)pairs;

@end

