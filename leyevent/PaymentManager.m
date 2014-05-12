//
//  PaymentManager.m
//  leyevent
//
//  Created by Nick Wroblewski on 5/8/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import "PaymentManager.h"
#import "rSkybox.h"
#import "ArcClient.h"
#import "CreditCard.h"

@implementation PaymentManager




static PaymentManager *sharedInstance = nil;

#pragma mark Convenience, init, and dealloc methods
+ (PaymentManager *)sharedInstance {
	if (sharedInstance == nil) {
		sharedInstance = [[PaymentManager alloc] init];
        sharedInstance.cardArray = [NSMutableArray array];
	}
    [[NSNotificationCenter defaultCenter] removeObserver:sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(creditCardsComplete:) name:@"creditCardNotification" object:nil];
	return sharedInstance;
}


-(void)getCreditCardList{
    
    
    ArcClient *tmp = [[ArcClient alloc] init];
    [tmp getListOfCreditCards];
    
}



-(void)creditCardsComplete:(NSNotification *)notification{
    
    //NSLog(@"Notification: %@", notification);
    
    @try {
        NSDictionary *userInfo = [notification valueForKey:@"userInfo"];
        
        @try {
            NSArray *results = [[userInfo valueForKey:@"apiResponse"] valueForKey:@"Results"];
            
            
            if ([results count] > 0) {
                
                for (int i = 0; i < [results count]; i++) {
                    //create card object and add it to card array
                    
                    NSDictionary *cardInfo = [results objectAtIndex:i];

                    CreditCard *tmpCard = [[CreditCard alloc] init];
                    
                    tmpCard.cardPin = @"";
                    tmpCard.cardNumber = [cardInfo valueForKey:@"Number"];
                    tmpCard.cardExpiration = [cardInfo valueForKey:@"ExpirationDate"];
                    tmpCard.cardToken = [cardInfo valueForKey:@"CCToken"];

                    [self.cardArray addObject:tmpCard];
                }
            }
        }
        @catch (NSException *exception) {
            self.cardArray = [NSMutableArray array];
        }
        
    }
    @catch (NSException *exception) {
        [rSkybox sendClientLog:@"PaymentManager.creditCardsComplete" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
        
    }

}



@end
