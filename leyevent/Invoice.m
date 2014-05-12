//
//  Invoice.m
//  ARC
//
//  Created by Nick Wroblewski on 6/26/12.
//  Copyright (c) 2012 Stretch Computing, Inc. All rights reserved.
//

#import "Invoice.h"
#import "rSkybox.h"
//#import "ArcUtility.h"

@implementation Invoice

- (id)init {
    if (self = [super init]) {
        self.gratuity = 0.0f;
        self.basePaymentAmount = 0.0f;
        self.basePaymentAmount = 0.0f;
        self.splitPercent = @"NONE";
        self.splitType = @"NONE";
        self.tipEntry = @"NONE";
    }
    return self;
}


- (double)taxableAmount
{
    @try {
        return self.subtotal - self.discount;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"Invoice.taxableAmount" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

- (double)amountDue
{
    @try {
        return self.subtotal + self.serviceCharge + self.tax - self.discount;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"Invoice.amountDue" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

- (double)amountDuePlusGratuity
{
    @try {
        return self.subtotal + self.serviceCharge + self.tax - self.discount + self.gratuity;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"Invoice.totalAmount" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

- (double)amountDueForSplit
{
    @try {
        return self.subtotal + self.serviceCharge + self.tax - self.discount - [self calculateAmountPaid];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"Invoice.amountDueForSplit" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

- (double)amountDueForSplitPlusGratuity
{
    @try {
        return self.subtotal + self.serviceCharge + self.tax - self.discount + self.gratuity - [self calculateAmountPaid];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"Invoice.totalAmount" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void)setGratuityByAmount:(double)tipAmount
{
    @try {
       // self.gratuity = [ArcUtility roundUpToNearestPenny:tipAmount];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"Invoice.setGratuityByAmount" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

-(void)setGratuityForSplit:(double)paymentAmount withTipPercent:(double)tipPercent
{
    @try {        
        double percentTax = [self tax]/[self taxableAmount];
        double percentServiceCharge = [self serviceCharge]/[self taxableAmount];
        double yourBaseAmount = paymentAmount/(percentServiceCharge + 1 + percentTax);
        //self.gratuity = [ArcUtility roundUpToNearestPenny:(yourBaseAmount * tipPercent)];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"Invoice.setGratuityByPercentage" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}

- (double)calculateAmountPaid {
    @try {
        double amountPaid = 0.0;
        double paymentAmount = 0.0;
        for (int i = 0; i < [self.payments count]; i++) {      
            NSDictionary *paymentDictionary = [self.payments objectAtIndex:i];
            paymentAmount = [[paymentDictionary valueForKey:@"Amount"] doubleValue];
            paymentAmount = [[NSString stringWithFormat:@"%.2f", paymentAmount] doubleValue];
            amountPaid += paymentAmount;
        }
        
        
        return amountPaid;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"Invoice.calculateAmountPaid" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}





@end
