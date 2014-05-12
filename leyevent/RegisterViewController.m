//
//  RegisterViewController.m
//  leyevent
//
//  Created by Nick Wroblewski on 5/6/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import "RegisterViewController.h"
#import "AppDelegate.h"
#import "ArcClient.h"
#import "PaymentManager.h"

@interface RegisterViewController ()

@end

@implementation RegisterViewController


-(void)viewWillAppear:(BOOL)animated{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerComplete:) name:@"registerNotification" object:nil];
    
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableBackView.layer.cornerRadius = 5.0;
    self.tableBackView.layer.borderColor = [lettuceGreenColor CGColor];
    self.tableBackView.layer.borderWidth = 2.0;
    
    self.loadingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"loading"];
    [self.view addSubview:self.loadingViewController.view];
    self.loadingViewController.view.hidden = YES;
}

-(void)endText{
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)submitAction:(id)sender {
    
    [self runRegister];
}

-(void)runRegister{
    
    
    
    @try{
        
        self.loadingViewController.displayLabel.text = @"Registering...";
        self.loadingViewController.view.hidden = NO;

        NSString *firstName = @"";
        NSString *lastName = @"";
        
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
		NSDictionary *loginDict = [[NSDictionary alloc] init];
        
        NSArray *nameArray = [self.nameText.text componentsSeparatedByString:@" "];
        
        if ([nameArray count] > 0) {
            
            firstName = [nameArray objectAtIndex:0];
            
            for (int i = 1; i < [nameArray count]; i++) {
                
                if ([lastName length] == 0) {
                    lastName = [lastName stringByAppendingFormat:@"%@", [nameArray objectAtIndex:i]];
                    
                }else{
                    lastName = [lastName stringByAppendingFormat:@" %@", [nameArray objectAtIndex:i]];
                    
                }
            }
        }
        
        
		[ tempDictionary setObject:firstName forKey:@"FirstName"];
		[ tempDictionary setObject:lastName forKey:@"LastName"];
		[ tempDictionary setObject:self.emailText.text forKey:@"eMail"];
		[ tempDictionary setObject:self.passwordText.text forKey:@"Password"];
        [ tempDictionary setObject:@"Phone" forKey:@"Source"];
        
        [ tempDictionary setObject:[NSNumber numberWithBool:NO] forKey:@"IsGuest"];
        
        
        
        //[ tempDictionary setObject:genderString forKey:@"Gender"];
        
        // TODO hard coded for now
        [ tempDictionary setObject:@"123" forKey:@"PassPhrase"];
        
        
        
        //[ tempDictionary setObject:birthDayString forKey:@"BirthDate"];
        [ tempDictionary setObject:@(YES) forKey:@"AcceptTerms"];
        [ tempDictionary setObject:@(YES) forKey:@"Notifications"];
        [ tempDictionary setObject:@(NO) forKey:@"Facebook"];
        [ tempDictionary setObject:@(NO) forKey:@"Twitter"];
        
		loginDict = tempDictionary;
        ArcClient *client = [[ArcClient alloc] init];
        [client createCustomer:loginDict];
        
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"RegisterViewController.runRegister" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
}


-(void)registerComplete:(NSNotification *)notification{
    @try {
        self.loadingViewController.view.hidden = YES;
        
        
        NSDictionary *responseInfo = [notification valueForKey:@"userInfo"];
        NSString *status = [responseInfo valueForKey:@"status"];
        
        NSString *errorMsg = @"";
        if ([status isEqualToString:@"success"]) {
            
            
            
            [[NSUserDefaults standardUserDefaults] setValue:self.emailText.text forKey:@"customerEmail"];
            NSString *firstName = @"";
            NSString *lastName = @"";
            
            
            
            NSArray *nameArray = [self.nameText.text componentsSeparatedByString:@" "];
            
            if ([nameArray count] > 0) {
                
                firstName = [nameArray objectAtIndex:0];
                
                for (int i = 1; i < [nameArray count]; i++) {
                    
                    if ([lastName length] == 0) {
                        lastName = [lastName stringByAppendingFormat:@"%@", [nameArray objectAtIndex:i]];
                        
                    }else{
                        lastName = [lastName stringByAppendingFormat:@" %@", [nameArray objectAtIndex:i]];
                        
                    }
                }
            }
            
            
            
            
            [[NSUserDefaults standardUserDefaults] setValue:firstName forKey:@"customerFirstName"];
            [[NSUserDefaults standardUserDefaults] setValue:lastName forKey:@"customerLastName"];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            ArcClient *client = [[ArcClient alloc] init];
            [client getServer];
            
            PaymentManager *tmp = [PaymentManager sharedInstance];
            [tmp getCreditCardList];
            
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"You have successfully registered." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alert show];
            
            
            self.passwordText.text = @"";
            self.emailText.text = @"";
            self.nameText.text = @"";
            [self.passwordText resignFirstResponder];
            [self.emailText resignFirstResponder];
            [self.nameText resignFirstResponder];

            
            
            [self handleSuccess];
            
            
            
        } else if([status isEqualToString:@"error"]){
            int errorCode = [[responseInfo valueForKey:@"error"] intValue];
            if(errorCode == USER_ALREADY_EXISTS) {
                errorMsg = @"Email Address already used.";
            }else if (errorCode == NETWORK_ERROR){
                
                errorMsg = @"dono is having problems connecting to the internet.  Please check your connection and try again.  Thank you!";
                
            }else {
                errorMsg = ARC_ERROR_MSG;
            }
        } else {
            // must be failure -- user notification handled by ArcClient
            errorMsg = ARC_ERROR_MSG;
        }
        
        if([errorMsg length] > 0) {
            //self.activityView.hidden = NO;
            //self.errorLabel.hidden = NO;
            //self.errorLabel.text = errorMsg;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Registration Failed" message:errorMsg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alert show];
        }
    }
    @catch (NSException *e) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Registration Failed" message:@"We encountered an error processing your request, please try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
        
        [rSkybox sendClientLog:@"RegisterViewController.registerComplete" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
}

-(void)handleSuccess{
    
    UIViewController *homenav = [self.storyboard instantiateViewControllerWithIdentifier:@"homenav"];
    [self presentViewController:homenav animated:NO completion:nil];
}


@end
