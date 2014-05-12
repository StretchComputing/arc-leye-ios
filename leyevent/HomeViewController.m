//
//  HomeViewController.m
//  leyevent
//
//  Created by Nick Wroblewski on 5/6/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import "HomeViewController.h"
#import "ArcClient.h"
#import "EventMainViewController.h"
#import "rSkybox.h"
#import <Crashlytics/Crashlytics.h>

@interface HomeViewController ()

@end

@implementation HomeViewController

-(void)viewDidAppear:(BOOL)animated{
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"customerToken"] length] == 0) {
        //logout
        [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    }
}
- (IBAction)endText:(id)sender {
}
-(void)viewWillAppear:(BOOL)animated{
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invoiceComplete:) name:@"invoiceNotification" object:nil];
    
    @try {
        [Crashlytics setUserEmail:[[NSUserDefaults standardUserDefaults] valueForKey:@"customerEmail"]];

    }
    @catch (NSException *exception) {
        
    }
 

    
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}


- (void)viewDidLoad
{
    @try {
        self.navigationController.navigationBarHidden = YES;
        [super viewDidLoad];
        // Do any additional setup after loading the view.
        
        self.submitButton.layer.cornerRadius = 4.0;
        
        self.loadingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"loading"];
        [self.view addSubview:self.loadingViewController.view];
        self.loadingViewController.view.hidden = YES;
        
        
        UIToolbar *toolbar = [[UIToolbar alloc] init];
        [toolbar setBarStyle:UIBarStyleBlackTranslucent];
        [toolbar sizeToFit];
        UIBarButtonItem *flexButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        UIBarButtonItem *doneButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(resignKeyboard)];
        
        if (isIos7) {
            doneButton.tintColor = [UIColor whiteColor];
        }
        
        NSArray *itemsArray = [NSArray arrayWithObjects:flexButton, doneButton, nil];
        [toolbar setItems:itemsArray];
        [self.numberText setInputAccessoryView:toolbar];

    }
    @catch (NSException *exception) {
         [rSkybox sendClientLog:@"HomeViewController.heightForRow" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
    }

    
    
}

-(void)resignKeyboard{
    [self.numberText resignFirstResponder];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)submitAction {
    
    if ([self.numberText.text length] > 0) {
        [self.numberText resignFirstResponder];
        [self getInvoice];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Number" message:@"Please enter a valid event number to continue." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
    
    
}

-(void)getInvoice{
    
    self.loadingViewController.displayLabel.text = @"Getting Details...";
    self.loadingViewController.view.hidden = NO;
    
    //self.numberText.text = @"489177";
    
    ArcClient *tmp = [[ArcClient alloc] init];
    [tmp getInvoice:@{@"invoiceNumber": self.numberText.text}];
    
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
            
            
            [self performSegueWithIdentifier:@"goevent" sender:self];
            
            
            
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

        
        [rSkybox sendClientLog:@"HomeViewController.invoiceComplete" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    
    @try {
        
        [self.numberText resignFirstResponder];
        
        if ([[segue identifier] isEqualToString:@"goevent"]) {
            
            EventMainViewController *next = [segue destinationViewController];
            next.myInvoice = self.myInvoice;
            
        }
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"HomeViewController.prepareForSegue" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}


@end
