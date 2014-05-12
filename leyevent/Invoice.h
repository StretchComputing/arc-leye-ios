//
//  Invoice.h
//  ARC
//
//  Created by Nick Wroblewski on 6/26/12.
//  Copyright (c) 2012 Stretch Computing, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Invoice : NSObject

@property int invoiceId, merchantId, customerId, paymentId;
@property (strong, nonatomic) NSString *status, *number, *posi, *dateCreated, *paymentsAccepted, *description;
@property double subtotal, serviceCharge, tax, discount, additionalCharge, gratuity, basePaymentAmount;
@property (strong, nonatomic) NSArray *tags, *items, *payments;
@property (strong, nonatomic) NSMutableArray *paymentRequests;
@property BOOL paidInFull;

-(double)taxableAmount;
-(double)subtotal;
-(double)amountDue;
-(double)amountDueForSplit;
-(double)amountDuePlusGratuity;
-(double)calculateAmountPaid;

-(void)setGratuityByAmount:(double)tipAmount;

-(void)setGratuityForSplit:(double)paymentAmount withTipPercent:(double)tipPercent;


//For metrics
@property (nonatomic, strong) NSString *splitType, *splitPercent, *tipEntry;



@end
