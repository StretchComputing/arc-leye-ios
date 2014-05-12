//
//  CreditCard.h
//  leyevent
//
//  Created by Nick Wroblewski on 5/8/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CreditCard : NSObject

@property (nonatomic, strong) NSString *cardNumber, *cardExpiration, *cardPin, *cardToken;
@end
