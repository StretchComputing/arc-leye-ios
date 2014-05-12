//
//  PaymentViewController.m
//  leyevent
//
//  Created by Nick Wroblewski on 5/8/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import "PaymentViewController.h"
#import "AppDelegate.h"
#import "rSkybox.h"

@interface PaymentViewController ()

@end

@implementation PaymentViewController


-(void)viewWillAppear:(BOOL)animated{
    
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'hh:mm:ss"];
    NSDate *theDate = [dateFormat dateFromString:[self.paymentDictionary valueForKey:@"PaymentDate"]];
    [dateFormat setDateFormat:@"MM/dd/yyyy"];
    self.dueDateLabel.text = [dateFormat stringFromDate:theDate];
    
    self.amountDueLabel.text = [NSString stringWithFormat:@"$%.2f", [[self.paymentDictionary valueForKey:@"Amount"] doubleValue]];
    
    if ([[self.paymentDictionary valueForKey:@"IsPaid"] boolValue]) {
        self.statusLabel.text = @"PAID";
        self.statusLabel.textColor = lettuceGreenColor;
    }else{
        self.statusLabel.text = @"NOT PAID";
        self.statusLabel.textColor = [UIColor redColor];
    }
    
    self.amountTextField.text = [NSString stringWithFormat:@"%.2f", [[self.paymentDictionary valueForKey:@"Amount"] doubleValue]];
    
    self.addPaymentButton.layer.cornerRadius = 4.0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    [toolbar sizeToFit];
    UIBarButtonItem *flexButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *doneButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(resignKeyboard)];
    doneButton.tintColor = [UIColor whiteColor];
    
    NSArray *itemsArray = [NSArray arrayWithObjects:flexButton, doneButton, nil];
    [toolbar setItems:itemsArray];
    [self.amountTextField setInputAccessoryView:toolbar];
    
    
}

-(void)resignKeyboard{
    [self.amountTextField resignFirstResponder];
}

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}



- (IBAction)addPaymentAction:(id)sender {
    
    NSDictionary *paymentDictionary = [self.previousScreen.myInvoice.paymentRequests objectAtIndex:self.previousScreen.selectedRow];
    
    NSMutableDictionary *mutablePayment = [NSMutableDictionary dictionaryWithDictionary:paymentDictionary];
    
    [mutablePayment setValue:self.amountTextField.text forKey:@"PaymentAmount"];
    [mutablePayment setValue:self.cardInfo forKey:@"CreditCard"];
    [mutablePayment setValue:self.scheduleLabel.text forKey:@"ScheduleDate"];
    
    paymentDictionary = [NSDictionary dictionaryWithDictionary:mutablePayment];
    
    [self.previousScreen.paymentsTableView reloadData];
    
    [self.navigationController popViewControllerAnimated:NO];

}

- (IBAction)segmentChanged {
    
    if (self.nowLaterSegment.selectedSegmentIndex == 0) {
        
        [self cancelDate];
    }else{
        //later
        
        self.toolbar.hidden = NO;
        self.datePicker.hidden = NO;
        self.selectLabel.hidden = NO;
        self.datePickerBackVIew.hidden = NO;
        self.datePicker.minimumDate = [NSDate date];
    }
}


-(IBAction)cancelDate{
    self.toolbar.hidden = YES;
    self.datePicker.hidden = YES;
    self.scheduleLabel.text = @"";
    self.selectLabel.hidden = YES;
    self.datePickerBackVIew.hidden = YES;
    self.nowLaterSegment.selectedSegmentIndex = 0;
}
-(IBAction)saveDate{
    
    NSDate *date = self.datePicker.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MM/dd/yyyy"];
    
    self.scheduleLabel.text = [dateFormat stringFromDate:date];
    self.toolbar.hidden = YES;
    self.datePicker.hidden = YES;
    self.datePickerBackVIew.hidden = YES;
    self.selectLabel.hidden = YES;
}
@end
