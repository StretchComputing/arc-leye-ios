//
//  PaymentViewController.h
//  leyevent
//
//  Created by Nick Wroblewski on 5/8/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventMainViewController.h"
#import "CreditCard.h"
@class EventMainViewController;
@interface PaymentViewController : UIViewController

@property (nonatomic, strong) EventMainViewController *previousScreen;
@property (nonatomic, strong) NSDictionary *paymentDictionary;
@property (strong, nonatomic) IBOutlet UILabel *dueDateLabel;
@property (strong, nonatomic) IBOutlet UILabel *amountDueLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UITextField *amountTextField;
@property (strong, nonatomic) IBOutlet UISegmentedControl *nowLaterSegment;
@property (strong, nonatomic) IBOutlet UIButton *addPaymentButton;
- (IBAction)addPaymentAction:(id)sender;
- (IBAction)segmentChanged;
@property (strong, nonatomic) IBOutlet UILabel *scheduleLabel;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;

@property (strong, nonatomic) IBOutlet UIView *datePickerBackVIew;
@property (strong, nonatomic) IBOutlet UILabel *selectLabel;

@property (nonatomic, strong) CreditCard *cardInfo;
-(IBAction)cancelDate;
-(IBAction)saveDate;
@end
