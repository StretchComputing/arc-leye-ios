//
//  EventMainViewController.m
//  leyevent
//
//  Created by Nick Wroblewski on 5/7/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import "EventMainViewController.h"
#import "ArcClient.h"
#import "rSkybox.h"
#import "CellButton.h"
#import "AppDelegate.h"
#import "PaymentViewController.h"
#import "PaymentManager.h"
#import "NSString+CharArray.h"

@interface EventMainViewController ()

@end

@implementation EventMainViewController


- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    
}

-(void)paymentsComplete:(NSNotification *)notification{
    
    
    @try {
        
        self.loadingViewController.view.hidden = YES;
        
        NSDictionary *userInfo = [notification valueForKey:@"userInfo"];
        
        NSDictionary *apiResponse = [userInfo valueForKey:@"apiResponse"];
        NSString *messageString = @"";
        
        if ([apiResponse valueForKey:@"Info"]) {
            NSArray *infoArray = [apiResponse valueForKey:@"Info"];
            
            for (int i = 0; i < [infoArray count]; i++) {
                NSString *newString = [infoArray objectAtIndex:i];
                messageString = [messageString stringByAppendingFormat:@"%@ \n", newString];
            }
        }
        
        
        if ([messageString length] == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error processing your request.  Please try again or contact customer support for assistance.  Thank you." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }else{
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result" message:messageString delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
        
        
        
        [self refreshInvoice];

        
        
    }
    @catch (NSException *exception) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error processing your request.  Please try again or contact customer support for assistance.  Thank you." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        
        [rSkybox sendClientLog:@"EventMainViewController.paymentsComplete" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
    }
  
    
    
}

-(void)setDisplays{
    
    self.eventDescriptionLabel.text = self.myInvoice.description;
    
    self.totalAmountLabel.text = [NSString stringWithFormat:@"$%.2f", self.myInvoice.subtotal];
    
    [self.paymentsTableView reloadData];
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paymentsComplete:) name:@"createMultiplePaymentsNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invoiceComplete:) name:@"invoiceNotification" object:nil];
    
    
    [self setDisplays];


}
- (void)viewDidLoad
{
    
    
    @try {
        
        [super viewDidLoad];
        // Do any additional setup after loading the view.
        
        
        self.paymentButton.layer.cornerRadius = 4.0;
        
        self.newCardFrontView.layer.cornerRadius = 5.0;
        
        
        self.cardNumberText.placeholder = @"1234 5678 9102 3456";
        self.cardNumberText.delegate = self;
        [self.cardNumberText setClearButtonMode:UITextFieldViewModeWhileEditing];
        [self.cardNumberText addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventEditingChanged];
        
        
        self.expirationText.placeholder = @"MM/YY";
        
        self.cardPinText.placeholder = @"CVV";
        
        self.cardPinText.delegate = self;
        self.expirationText.delegate = self;
        
        [self.cardPinText setClearButtonMode:UITextFieldViewModeWhileEditing];
        [self.expirationText setClearButtonMode:UITextFieldViewModeWhileEditing];
        
        [self.cardPinText addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventEditingChanged];
        [self.expirationText addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventEditingChanged];
        
        
        if (self.view.frame.size.height < 500) {
            CGRect frame = self.newCardFrontView.frame;
            frame.origin.y -= 60;
            self.newCardFrontView.frame = frame;
        }
        
        self.loadingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"loading"];
        [self.view addSubview:self.loadingViewController.view];
        self.loadingViewController.view.hidden = YES;
    }
    @catch (NSException *exception) {
         [rSkybox sendClientLog:@"EventMainViewController.viewDidLoad" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
    }
  
}



- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
	
    
    return [self.myInvoice.paymentRequests count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    @try {
        
        NSUInteger row = indexPath.row;
        //NSUInteger section = indexPath.section;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"paymentcell"];
            
      
        NSDictionary *paymentDictionary = [self.myInvoice.paymentRequests objectAtIndex:row];
        
        UIView *backView = (UIView *)[cell.contentView viewWithTag:1];
        backView.layer.cornerRadius = 5.0;
        backView.layer.borderWidth = 2.0;
        backView.layer.borderColor = [[UIColor blackColor] CGColor];
        
        
        UILabel *dateLabel = (UILabel *)[cell.contentView viewWithTag:2];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'hh:mm:ss"];
        NSDate *theDate = [dateFormat dateFromString:[paymentDictionary valueForKey:@"PaymentDate"]];
        [dateFormat setDateFormat:@"MM/dd/yyyy"];
        dateLabel.text = [dateFormat stringFromDate:theDate];

        UILabel *amountDueLabel = (UILabel *)[cell.contentView viewWithTag:3];
        amountDueLabel.text = [NSString stringWithFormat:@"$%.2f", [[paymentDictionary valueForKey:@"Amount"] doubleValue]];
        
        BOOL hideBottomLabel = NO;
     
        UILabel *statusLabel = (UILabel *)[cell.contentView viewWithTag:4];
        if ([[paymentDictionary valueForKey:@"IsPaid"] boolValue]) {
            statusLabel.text = @"PAID";
            statusLabel.textColor = [UIColor colorWithRed:0 green:100.0/255.0 blue:0 alpha:1.0];
            hideBottomLabel = YES;
        }else{
            
            if ([[paymentDictionary valueForKey:@"IsScheduled"] boolValue]) {
                statusLabel.text = @"SCHEDULED";
                statusLabel.textColor = [UIColor colorWithRed:0 green:100.0/255.0 blue:0 alpha:1.0];
                hideBottomLabel = YES;
            }else{
                statusLabel.text = @"NOT PAID";
                statusLabel.textColor = [UIColor redColor];
            }
            
        }
        
        CellButton *deleteButton = (CellButton *)[cell.contentView viewWithTag:8];
        deleteButton.hidden = YES;
        deleteButton.selectedRow = indexPath.row;
        [deleteButton addTarget:self action:@selector(deletePaymentInfo:) forControlEvents:UIControlEventTouchUpInside];
   
        UILabel *bottomLabel = (UILabel *)[cell.contentView viewWithTag:7];
        
        
        bottomLabel.textColor = [UIColor blueColor];
        bottomLabel.font = [UIFont systemFontOfSize:15];
        if ([[paymentDictionary valueForKey:@"Via"] isEqualToString:@"CREDIT"]) {
            
            if ([[paymentDictionary valueForKey:@"CardNumber"] length] > 0) {
                
                deleteButton.hidden = NO;
                NSString *cardNumber = [paymentDictionary valueForKey:@"CardNumber"];
                
                NSString *payDate = @"Now";
                
                if (![[paymentDictionary valueForKey:@"IsPayNow"] boolValue]) {
                    payDate = dateLabel.text;
                }
                
                bottomLabel.text = [NSString stringWithFormat:@"Payment: ****%@ (%@)", [cardNumber substringFromIndex:[cardNumber length] - 4], payDate];
            }else{
                bottomLabel.text = @"+ Add Payment Information";
            }
            
            
        }else{
            
            bottomLabel.text = [NSString stringWithFormat:@"*%@ Payment Requested*", [paymentDictionary valueForKey:@"Via"]];
            bottomLabel.textColor = lettuceGreenColor;
            bottomLabel.font = [UIFont systemFontOfSize:12];
        }
        
        
       
        
        if (hideBottomLabel) {
            bottomLabel.hidden = YES;
        }else{
            bottomLabel.hidden = NO;
        }
        
        
        
        
        
        return cell;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"EventMainViewController.tableView" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        
    }
	
}

-(void)deletePaymentInfo:(id)sender{
    
    
    @try {
        CellButton *tmp = (CellButton *)sender;
        
        NSLog(@"Row: %d", tmp.selectedRow);
        
        NSDictionary *paymentDictionary = [self.myInvoice.paymentRequests objectAtIndex:tmp.selectedRow];
        
        NSMutableDictionary *mutablePayment = [NSMutableDictionary dictionaryWithDictionary:paymentDictionary];
        
        [mutablePayment setValue:@"" forKey:@"CardNumber"];
        [mutablePayment setValue:@"" forKey:@"CardExpiration"];
        [mutablePayment setValue:@"" forKey:@"CardPin"];
        [mutablePayment setValue:@"" forKey:@"CardToken"];
        
        
        paymentDictionary = [NSDictionary dictionaryWithDictionary:mutablePayment];
        
        
        [self.myInvoice.paymentRequests replaceObjectAtIndex:tmp.selectedRow withObject:paymentDictionary];
        
        [self.paymentsTableView reloadData];

    }
    @catch (NSException *exception) {
        [rSkybox sendClientLog:@"EventMainViewController.deletePaymentInfo" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
    }
  
    
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    @try {
        
        NSDictionary *paymentDictionary = [self.myInvoice.paymentRequests objectAtIndex:indexPath.row];
        
        int shortNumber = 80;
        
        if ([[paymentDictionary valueForKey:@"IsPaid"] boolValue]) {
            return shortNumber;
        }else{
            
            if ([[paymentDictionary valueForKey:@"IsScheduled"] boolValue]) {
                return shortNumber;
                
            }
            
        }
        
        return 107;
    }
    @catch (NSException *exception) {
         [rSkybox sendClientLog:@"EventMainViewController.heightForRow" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
        return 0;

    }
   
 
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    @try {
        NSDictionary *paymentDictionary = [self.myInvoice.paymentRequests objectAtIndex:indexPath.row];

        if ([[paymentDictionary valueForKey:@"IsPaid"] boolValue]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Paid!" message:@"This payment has already been made.  Thank you!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }else{
            
            if ([[paymentDictionary valueForKey:@"IsScheduled"] boolValue]) {
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Scheduled Payment" message:@"This payment has already been scheduled, no further action is needed." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                
            }else{
                
                if ([[paymentDictionary valueForKey:@"Via"] isEqualToString:@"CREDIT"]) {
                    
                    self.selectedRow = indexPath.row;
                    
                    //[self performSegueWithIdentifier:@"gopayment" sender:self];
                    
                    [self showPaymentOptions];
                    
                    
                }else{
                    
                    NSString *message = [NSString stringWithFormat:@"The payment type requested for this payment - %@ - cannot be paid from the app.", [paymentDictionary valueForKey:@"Via"]];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alternate Payment" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                    
                   
                }
                
                
               
            }
            
        }
        
        
    
        
   
        
    }
    @catch (NSException *exception) {
        [rSkybox sendClientLog:@"EventMainViewController.didSelectRowAtIndexPath" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
        
    }
    
    
    
}




- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    
    @try {
        
        
        if ([[segue identifier] isEqualToString:@"gopayment"]) {
            
            PaymentViewController *next = [segue destinationViewController];
            next.paymentDictionary = [self.myInvoice.paymentRequests objectAtIndex:self.selectedRow];
            next.previousScreen = self;
            
        }
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"EventMainViewController.prepareForSegue" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}



-(void)showPaymentOptions{
    
    
    @try {
        PaymentManager *manager = [PaymentManager sharedInstance];
        
        if (self.creditCardArray == nil) {
            self.creditCardArray = [NSMutableArray array];
        }
        
        
        [self.creditCardArray addObjectsFromArray:manager.cardArray];
        
        @try {
            for (int i = 0; i < [self.creditCardArray count]; i++) {
                
                CreditCard *first = [self.creditCardArray objectAtIndex:i];
                
                for (int j = i+1; j < [self.creditCardArray count]; j++) {
                    
                    CreditCard *second = [self.creditCardArray objectAtIndex:j];
                    
                    if ([first.cardToken length] > 0) {
                        
                        if ([first.cardToken isEqualToString:second.cardToken]) {
                            [self.creditCardArray removeObjectAtIndex:j];
                            j--;
                        }
                        
                    }else{
                        break;
                    }
                }
            }
        }
        @catch (NSException *exception) {
            
        }
       
        
        
        if ([self.creditCardArray count] > 0) {
            
            self.actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select Payment Method" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            
            
            for (int i = 0; i < [self.creditCardArray count]; i++) {
                CreditCard *tmpCard = [self.creditCardArray objectAtIndex:i];
                
                NSString *type = [self getCardTypeForNumber:tmpCard.cardNumber];
                
                [self.actionSheet addButtonWithTitle:[NSString stringWithFormat:@"%@  ****%@", type, [tmpCard.cardNumber substringFromIndex:[tmpCard.cardNumber length] - 4]]];
                
            }
            
            [self.actionSheet addButtonWithTitle:@"+ New Card"];
            [self.actionSheet addButtonWithTitle:@"Cancel"];
            self.actionSheet.cancelButtonIndex = [self.creditCardArray count];
            [self.actionSheet showInView:self.view];
            
            
        }else{
            self.newCardBackView.hidden = NO;
            [self.cardNumberText becomeFirstResponder];
        }
    }
    @catch (NSException *exception) {

        [rSkybox sendClientLog:@"EventMainViewController.showPaymentOptions" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
    }
   
}


-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    @try {
        
        
        if (buttonIndex == [self.creditCardArray count] + 1) {
            //cancel
        }else if (buttonIndex == [self.creditCardArray count]){
            //new card
            self.newCardBackView.hidden = NO;
            [self.cardNumberText becomeFirstResponder];
            
        }else{
            
            self.cardToAdd = [self.creditCardArray objectAtIndex:buttonIndex];
            
            [self showScheduleAlert];
            
            
            
        }
        
        
        
        
    }@catch (NSException *e) {
        // NSLog(@"E: %@", e);
        [rSkybox sendClientLog:@"EventMainViewController.actionSheet" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (alertView == self.scheduleAlert) {
        
        if (buttonIndex == 0) {
            
            [self completeAddCardWithPayNow:NO];
        }else{
            [self completeAddCardWithPayNow:YES];

        }
    }
}


- (IBAction)paymentAction {
    
    @try {
        
        
        BOOL foundNotPayed = NO;
        NSMutableArray *toPayArray = [NSMutableArray array];
        for (int i = 0; i < [self.myInvoice.paymentRequests count]; i++) {
            
            NSDictionary *paymentDictionary = [self.myInvoice.paymentRequests objectAtIndex:i];
            
            if (![[paymentDictionary valueForKey:@"IsPaid"] boolValue]) {
                foundNotPayed = YES;
            }
            
            if ([[paymentDictionary valueForKey:@"CardNumber"] length] > 0) {
                [toPayArray addObject:paymentDictionary];
            }
            
        }
        
        
        if (foundNotPayed) {
            //we found at least 1 not paid
            
            if ([toPayArray count] > 0) {
                //at least one payment was scheduled
                
                NSMutableDictionary *clientDictionary = [NSMutableDictionary dictionary];
                
                [clientDictionary setValue:[NSNumber numberWithInt:self.myInvoice.invoiceId] forKey:@"InvoiceId"];
                [clientDictionary setValue:[NSNumber numberWithDouble:self.myInvoice.subtotal] forKey:@"InvoiceAmount"];
                //[clientDictionary setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"customerEmail"] forKey:@"eMail"];
                
                NSMutableArray *clientArray = [NSMutableArray array];
                
                for (int i = 0; i < [toPayArray count]; i++) {
                    
                    NSDictionary *paymentDictionary = [toPayArray objectAtIndex:i];
                    NSMutableDictionary *subDictionary = [NSMutableDictionary dictionary];
                    
                    
                    [subDictionary setValue:[paymentDictionary valueForKey:@"Id"] forKey:@"Id"];
                    [subDictionary setValue:[paymentDictionary valueForKey:@"Amount"] forKey:@"Amount"];
                    
                    if ([[paymentDictionary valueForKey:@"IsPayNow"] boolValue]) {
                        
                        
                        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                        [dateFormat setDateFormat:@"yyyy-MM-dd'T'hh:mm:ss"];
                        NSDate *today = [NSDate date];
                        
                        NSString *paymentDate = [[dateFormat stringFromDate:today] substringToIndex:10];
                        
                        [subDictionary setValue:paymentDate forKey:@"PaymentDate"];
                        
                    }else{
                        
                        NSString *paymentDate = [[paymentDictionary valueForKey:@"PaymentDate"] substringToIndex:10];
                        
                        [subDictionary setValue:paymentDate forKey:@"PaymentDate"];
                        
                    }
                    
                    
                    if ([[paymentDictionary valueForKey:@"CardToken"] length] > 0) {
                        
                        [subDictionary setValue:[paymentDictionary valueForKey:@"CardToken"] forKey:@"CCToken"];
                        
                    }else{
                        
                        [subDictionary setValue:[paymentDictionary valueForKey:@"CardNumber"]  forKey:@"Number"];
                        [subDictionary setValue:[paymentDictionary valueForKey:@"CardExpiration"]  forKey:@"Expiration"];
                        [subDictionary setValue:[paymentDictionary valueForKey:@"CardPin"]  forKey:@"CVV"];
                    }
                    
                    [clientArray addObject:subDictionary];
                    
                }
                
                [clientDictionary setValue:clientArray forKey:@"Payments"];
                
                
                ArcClient *tmp = [[ArcClient alloc] init];
                self.loadingViewController.view.hidden = NO;
                self.loadingViewController.displayLabel.text = @"Making Payment...";
                [tmp createMultiplePayments:clientDictionary];
                
                
            }else{
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Entered Payments" message:@"To make a payment, select one of the due payments to add your payment information, then try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                
            }
        }else{
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Pending Payments" message:@"All of your payments have already been made, thank you." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
    
        
        
    }
    @catch (NSException *exception) {
        [rSkybox sendClientLog:@"EventMainViewController.paymentAction" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
    }
  
   
   
    
    
}

- (IBAction)newCardAdd {
    
    @try {
        
        if ([[self creditCardStatus] isEqualToString:@"valid"]) {
            
            
            if ([self luhnCheck:[self.cardNumberText.text stringByReplacingOccurrencesOfString:@" " withString:@""]]) {
                
                [self addCard];
                
            }else{
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Card" message:@"Please enter a valid card number." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                
            }
            
            
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Missing Field" message:@"Please fill out all credit card information first" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
    }
    @catch (NSException *exception) {
           [rSkybox sendClientLog:@"EventMainViewController.newCardAdd" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
    }

    
    
}

-(NSString *)creditCardStatus{
    @try {
        
        if ([self.cardPinText.text isEqualToString:@""] && [self.cardNumberText.text isEqualToString:@""] && [self.expirationText.text isEqualToString:@""]){
            
            return @"empty";
        }else{
            //At least one is entered, must all be entered
            if (![self.cardPinText.text isEqualToString:@""] && ![self.cardNumberText.text isEqualToString:@""] && ([self.expirationText.text length] == 5)){
                return @"valid";
            }else{
                return @"invalid";
            }
        }
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"EventMainViewController.creditCardStatus" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
}


- (IBAction)newCardCancel {
    self.newCardBackView.hidden = YES;
    
    self.cardNumberText.text = @"";
    self.expirationText.text = @"";
    self.cardPinText.text = @"";
    
    [self.cardNumberText resignFirstResponder];
    [self.expirationText resignFirstResponder];
    [self.cardPinText resignFirstResponder];

    
    
}




//CC Entry

-(void)formatCreditCard:(BOOL)final{
    
    @try {
        if (!self.isDelete) {
            
            
            NSString *cardNumber = self.cardNumberText.text;
            BOOL isAmex = NO;
            
            if ([cardNumber length] > 1) {
                if ([[cardNumber substringToIndex:2] isEqualToString:@"34"] || [[cardNumber substringToIndex:2] isEqualToString:@"37"]) {
                    isAmex = YES;
                }
            }
            
            if (isAmex) {
                
                
                if (final) {
                    
                    cardNumber = [NSString stringWithFormat:@"%@ %@ %@", [cardNumber substringToIndex:4], [cardNumber substringWithRange:NSMakeRange(4, 6)], [cardNumber substringFromIndex:10]];
                    
                }else{
                    if ([cardNumber length] == 4) {
                        cardNumber = [cardNumber stringByAppendingString:@" "];
                    }else if ([cardNumber length] == 11){
                        cardNumber = [cardNumber stringByAppendingString:@" "];
                    }else if ([cardNumber length] == 17){
                        [self.expirationText becomeFirstResponder];
                    }else if ([cardNumber length] == 5) {
                        cardNumber = [NSString stringWithFormat:@"%@ %@", [cardNumber substringToIndex:4], [cardNumber substringFromIndex:4]];
                    }else if ([cardNumber length] == 12){
                        cardNumber = [NSString stringWithFormat:@"%@ %@", [cardNumber substringToIndex:11], [cardNumber substringFromIndex:11]];
                        
                    }
                }
                
                
                
            }else{
                
                if (final) {
                    
                    cardNumber = [NSString stringWithFormat:@"%@ %@ %@ %@", [cardNumber substringToIndex:4], [cardNumber substringWithRange:NSMakeRange(4, 4)], [cardNumber substringWithRange:NSMakeRange(8, 4)], [cardNumber substringFromIndex:12]];
                }else{
                    if ([cardNumber length] == 4) {
                        cardNumber = [cardNumber stringByAppendingString:@" "];
                    }else if ([cardNumber length] == 9){
                        cardNumber = [cardNumber stringByAppendingString:@" "];
                    }else if ([cardNumber length] == 14){
                        cardNumber = [cardNumber stringByAppendingString:@" "];
                    }else if ([cardNumber length] == 19){
                        [self.expirationText becomeFirstResponder];
                    }else if ([cardNumber length] == 5) {
                        cardNumber = [NSString stringWithFormat:@"%@ %@", [cardNumber substringToIndex:4], [cardNumber substringFromIndex:4]];
                    }else if ([cardNumber length] == 10){
                        cardNumber = [NSString stringWithFormat:@"%@ %@", [cardNumber substringToIndex:9], [cardNumber substringFromIndex:9]];
                        
                    }else if ([cardNumber length] == 15){
                        cardNumber = [NSString stringWithFormat:@"%@ %@", [cardNumber substringToIndex:14], [cardNumber substringFromIndex:14]];
                    }
                }
                
            }
            
            
            
            //self.shouldIgnoreValueChanged = YES;
            
            self.cardNumberText.text = cardNumber;
        }
    }
    
    @catch (NSException *exception) {
        [rSkybox sendClientLog:@"EventMainViewController.formatCreditCard" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
    }
    
    
    
}

-(void)formatExpiration{
    
    @try {
        NSString *expiration = self.expirationText.text;
        
        if (self.isDelete) {
            
            if ([expiration length] == 2) {
                expiration = [expiration substringToIndex:1];
            }
            
        }else{
            if ([expiration length] == 5) {
                [self.cardPinText becomeFirstResponder];
            }
            
            if ([expiration length] == 1) {
                if (![expiration isEqualToString:@"1"] && ![expiration isEqualToString:@"0"]) {
                    expiration = [NSString stringWithFormat:@"0%@/", expiration];
                }
            }else if ([expiration length] == 2){
                expiration = [expiration stringByAppendingString:@"/"];
            }
        }
        
        // self.shouldIgnoreValueChangedExpiration = YES;
        
        
        self.expirationText.text = expiration;
    }
    @catch (NSException *exception) {
        [rSkybox sendClientLog:@"EventMainViewController.formatException" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
    }
    
    
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    
    @try {
        self.isDelete = NO;
        
        
        if (textField == self.cardNumberText){
            
            if ([string isEqualToString:@""]) {
                self.isDelete = YES;
                return TRUE;
            }
            
            if ([self.cardNumberText.text length] >= 20) {
                
                if ([string isEqualToString:@""]) {
                    return YES;
                }
                return FALSE;
            }
            
        }else if (textField == self.expirationText){
            
            if ([string isEqualToString:@""]) {
                self.isDelete = YES;
                
                
                return TRUE;
            }
            if ([self.expirationText.text length] >= 5) {
                if ([string isEqualToString:@""]) {
                    return YES;
                }
                return FALSE;
            }
            
        }else if (textField == self.cardPinText){
            
            if ([string isEqualToString:@""]) {
                
                
                return TRUE;
            }
            
            if ([self.cardPinText.text length] >= 4) {
                if ([string isEqualToString:@""]) {
                    return YES;
                }
                return FALSE;
            }
            
        }
        return TRUE;
        
    }
    @catch (NSException *exception) {
        [rSkybox sendClientLog:@"EventMainViewController.shouldChangeCharacters" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
    }
    
    
}


-(void)valueChanged:(id)sender{
    
    @try {
        
        if (self.shouldIgnoreValueChanged) {
            self.shouldIgnoreValueChanged = NO;
        }else{
            if (sender == self.cardNumberText){
                [self formatCreditCard:NO];
            }
        }
        
        if (self.shouldIgnoreValueChangedExpiration) {
            self.shouldIgnoreValueChangedExpiration = NO;
        }else{
            if (sender == self.expirationText) {
                
                [self formatExpiration];
            }
        }
        
    }
    @catch (NSException *exception) {
        [rSkybox sendClientLog:@"EventMainViewController.valueChanged" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
        
    }
    
    
    
}

- (BOOL) luhnCheck:(NSString *)stringToTest {
    
    
    @try {
        stringToTest = [stringToTest stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSMutableArray *stringAsChars = [stringToTest toCharArray];
        
        BOOL isOdd = YES;
        int oddSum = 0;
        int evenSum = 0;
        
        for (int i = [stringToTest length] - 1; i >= 0; i--) {
            
            int digit = [(NSString *)[stringAsChars objectAtIndex:i] intValue];
            
            if (isOdd)
                oddSum += digit;
            else
                evenSum += digit/5 + (2*digit) % 10;
            
            isOdd = !isOdd;
        }
        
        return ((oddSum + evenSum) % 10 == 0);
    }
    @catch (NSException *exception) {
        
        [rSkybox sendClientLog:@"EventMainViewController.luhnCheck" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
        
        return NO;
    }
    
    
}


-(void)showScheduleAlert{
    
    NSDictionary *paymentDictionary = [self.myInvoice.paymentRequests objectAtIndex:self.selectedRow];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'hh:mm:ss"];
    NSDate *theDate = [dateFormat dateFromString:[paymentDictionary valueForKey:@"PaymentDate"]];
    [dateFormat setDateFormat:@"MM/dd/yyyy"];
    
    
    
    
    NSString *message = [NSString stringWithFormat:@"Would you like this payment to be processed now, or scheduled for the dute date - %@", [dateFormat stringFromDate:theDate]];
    
    
    NSDate *today = [NSDate date];
    
    if ([[theDate earlierDate:today] isEqualToDate:theDate]) {
        //if the due date is in the past, must pay now
        [self completeAddCardWithPayNow:YES];
    }else{
        self.scheduleAlert = [[UIAlertView alloc] initWithTitle:@"Payment Date" message:message delegate:self cancelButtonTitle:@"Schedule" otherButtonTitles:@"Pay Now", nil];
        [self.scheduleAlert show];
    }
  
    
    
}


-(void)completeAddCardWithPayNow:(BOOL)isPayNow{
    
    
    NSDictionary *paymentDictionary = [self.myInvoice.paymentRequests objectAtIndex:self.selectedRow];

    //Add this as the payment info for the selected row
    
    NSMutableDictionary *mutablePayment = [NSMutableDictionary dictionaryWithDictionary:paymentDictionary];
    
    [mutablePayment setValue:self.cardToAdd.cardNumber forKey:@"CardNumber"];
    [mutablePayment setValue:self.cardToAdd.cardExpiration forKey:@"CardExpiration"];
    [mutablePayment setValue:self.cardToAdd.cardPin forKey:@"CardPin"];
    [mutablePayment setValue:self.cardToAdd.cardToken forKey:@"CardToken"];
    [mutablePayment setValue:[NSNumber numberWithBool:isPayNow] forKey:@"IsPayNow"];

    
    paymentDictionary = [NSDictionary dictionaryWithDictionary:mutablePayment];
    
    
    [self.myInvoice.paymentRequests replaceObjectAtIndex:self.selectedRow withObject:paymentDictionary];
    
    if ([self.cardToAdd.cardToken length] == 0) {
        [self.creditCardArray addObject:self.cardToAdd];
    }
    
    [self.paymentsTableView reloadData];
    
    [self newCardCancel];
    
    
}
-(void)addCard{
    
   
    
    CreditCard *tmpCard = [[CreditCard alloc] init];
    
    tmpCard.cardNumber = [self.cardNumberText.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    tmpCard.cardExpiration = self.expirationText.text;
    tmpCard.cardPin = self.cardPinText.text;
    tmpCard.cardToken = @"";
    
    self.cardToAdd = tmpCard;
    
    [self showScheduleAlert];

    
    
}


-(NSString *)getCardTypeForNumber:(NSString *)cardNumber{
    
    
    @try {
        
        if ([cardNumber length] > 0) {
            
            NSString *firstOne = [cardNumber substringToIndex:1];
            NSString *firstTwo = [cardNumber substringToIndex:2];
            NSString *firstThree = [cardNumber substringToIndex:3];
            NSString *firstFour = [cardNumber substringToIndex:4];
            
            int numberLength = [cardNumber length];
            
            if ([firstOne isEqualToString:@"4"] && ((numberLength == 15) || (numberLength == 16))) {
                return @"Visa";
            }
            
            double cardDigits = [firstTwo doubleValue];
            if ((cardDigits >= 51) && (cardDigits <= 55) && (numberLength == 16)) {
                return @"MasterCard";
            }
            
            if (([firstTwo isEqualToString:@"34"] || [firstTwo isEqualToString:@"37"]) && (numberLength == 15)) {
                return @"Amex";
            }
            
            if (([firstTwo isEqualToString:@"65"] || [firstFour isEqualToString:@"6011"]) && (numberLength == 16)) {
                return @"Discover";
            }
            
            double threeDigits = [firstThree doubleValue];
            if ((numberLength == 14) && ([firstTwo isEqualToString:@"36"] || [firstTwo isEqualToString:@"38"] || ((threeDigits >= 300) && (threeDigits <= 305) ))) {
                return @"Diners";
            }
            
            return @"Credit";
        }else{
            return @"";
        }
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"EventMainViewController.getCardTypeForNumber" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
    
    
}

- (IBAction)helpAction {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Event Help" message:@"The payments due for your event are listed below.  To make or schedule a payment, click on one of the payment requests and add your payment information, then click on the 'Make Payments' button below." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(void)refreshInvoice{
    
    
    self.loadingViewController.displayLabel.text = @"Refreshing...";
    self.loadingViewController.view.hidden = NO;
    
    //self.numberText.text = @"489177";
    
    ArcClient *tmp = [[ArcClient alloc] init];
    [tmp getInvoice:@{@"invoiceNumber": self.myInvoice.number}];
    
    
}


-(void)invoiceComplete:(NSNotification *)notification{
    @try {
        
        
        //NSLog(@"Notification: %@", notification);
        
        self.loadingViewController.view.hidden = YES;
        
        
        ArcClient *pingClient = [[ArcClient alloc] init];
        [pingClient sendServerPings];
        
        BOOL displayAlert = NO;
        
        
        
        NSDictionary *responseInfo = [notification valueForKey:@"userInfo"];
        
        NSLog(@"ResponseInfo: %@", responseInfo);
        
        NSString *status = [responseInfo valueForKey:@"status"];
        
        NSString *errorMsg = @"";
        if ([status isEqualToString:@"success"]) {
            //NSDictionary *theInvoice = [[[responseInfo valueForKey:@"apiResponse"] valueForKey:@"Results"] objectAtIndex:0];
            
            NSDictionary *theInvoice = [[[responseInfo valueForKey:@"apiResponse"] valueForKey:@"Results"] objectAtIndex:0];
            
            
            self.myInvoice = [[Invoice alloc] init];
            self.myInvoice.invoiceId = [[theInvoice valueForKey:@"Id"] intValue];
            self.myInvoice.status = [theInvoice valueForKey:@"Status"];
            self.myInvoice.number = [theInvoice valueForKey:@"Number"];
            self.myInvoice.merchantId = [[theInvoice valueForKey:@"MerchantId"] intValue];
            self.myInvoice.customerId = [[theInvoice valueForKey:@"CustomerId"] intValue];
            self.myInvoice.posi = [theInvoice valueForKey:@"POSI"];
            
            self.myInvoice.subtotal = [[theInvoice valueForKey:@"BaseAmount"] doubleValue];
            self.myInvoice.serviceCharge = [[theInvoice valueForKey:@"ServiceCharge"] doubleValue];
            self.myInvoice.tax = [[theInvoice valueForKey:@"Tax"] doubleValue];
            self.myInvoice.discount = [[theInvoice valueForKey:@"Discount"] doubleValue];
            self.myInvoice.additionalCharge = [[theInvoice valueForKey:@"AdditionalCharge"] doubleValue];
            
            self.myInvoice.dateCreated = [theInvoice valueForKey:@"DateCreated"];
            
            self.myInvoice.tags = [NSArray arrayWithArray:[theInvoice valueForKey:@"Tags"]];
            self.myInvoice.items = [NSArray arrayWithArray:[theInvoice valueForKey:@"Items"]];
            self.myInvoice.payments = [NSArray arrayWithArray:[theInvoice valueForKey:@"Payments"]];
            
            self.myInvoice.paymentRequests = [NSMutableArray arrayWithArray:[theInvoice valueForKey:@"PaymentRequests"]];
            
            self.myInvoice.description = [theInvoice valueForKey:@"Description"];
            
            
            [self setDisplays];
            
            
            
        } else if([status isEqualToString:@"error"]){
            int errorCode = [[responseInfo valueForKey:@"error"] intValue];
            if(errorCode == INVOICE_NOT_FOUND) {
                errorMsg = @"Can not find invoice.";
            } else if(errorCode == INVOICE_CLOSED) {
                errorMsg = @"Invoice closed.";
            }else if (errorCode == CHECK_IS_LOCKED){
                errorMsg = @"Invoice being accessed by your waiter.  Try again in a few minutes.";
            } else if (errorCode == NETWORK_ERROR){
                displayAlert = YES;
                errorMsg = @"We are having problems connecting to the internet.  Please check your connection and try again.  Thank you!";
                
            } else {
                errorMsg = ARC_ERROR_MSG;
            }
        } else {
            // must be failure -- user notification handled by ArcClient
            errorMsg = ARC_ERROR_MSG;
        }
        
        if([errorMsg length] > 0) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could Not Get Invoice" message:errorMsg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alert show];
            
        }
    }
    @catch (NSException *e) {
        
        
        [rSkybox sendClientLog:@"EventMainViewController.invoiceComplete" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
}




@end
