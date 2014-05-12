//
//  EventMainViewController.h
//  leyevent
//
//  Created by Nick Wroblewski on 5/7/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Invoice.h"
#import "LoadingViewController.h"
#import "CreditCard.h"

@class LoadingViewController;

@interface EventMainViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIActionSheetDelegate>
- (IBAction)helpAction;

@property (nonatomic, strong) CreditCard *cardToAdd;

@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) LoadingViewController *loadingViewController;

@property (strong, nonatomic) IBOutlet UILabel *eventDescriptionLabel;

@property (strong, nonatomic) IBOutlet UILabel *totalAmountLabel;
@property (nonatomic, strong) Invoice *myInvoice;

@property (strong, nonatomic) IBOutlet UIButton *paymentButton;
@property int selectedRow;
- (IBAction)paymentAction;
@property (nonatomic, strong) IBOutlet UITableView *paymentsTableView;
@property (nonatomic, strong) NSMutableArray *creditCardArray;
@property (strong, nonatomic, getter = getNewCardFrontView) IBOutlet UIView *newCardFrontView;
- (IBAction)newCardAdd;
- (IBAction)newCardCancel;
@property (strong, nonatomic) IBOutlet UITextField *cardNumberText;
@property (strong, nonatomic) IBOutlet UITextField *expirationText;
@property (strong, nonatomic) IBOutlet UITextField *cardPinText;

@property (nonatomic, strong, getter = getCardBackView) IBOutlet UIView *newCardBackView;



@property BOOL isDelete;
@property BOOL shouldIgnoreValueChanged;
@property BOOL shouldIgnoreValueChangedExpiration;

@property (nonatomic, strong) UIAlertView *scheduleAlert;

@end
