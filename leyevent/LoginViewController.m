//
//  LoginViewController.m
//  leyevent
//
//  Created by Nick Wroblewski on 5/6/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "ArcClient.h"
#import "PaymentManager.h"

@interface LoginViewController ()

@end

@implementation LoginViewController


-(void)viewWillAppear:(BOOL)animated{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(signInComplete:) name:@"signInNotification" object:nil];
    
    
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)goBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)submitAction:(id)sender {
    
    [self runLogin];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)endText{
    
}


-(void)runLogin{
    @try {
        NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
        NSDictionary *loginDict = [[NSDictionary alloc] init];
        [ tempDictionary setObject:self.emailTtext.text forKey:@"userName"];
        [ tempDictionary setObject:self.passwordText.text forKey:@"password"];
        
        self.loadingViewController.displayLabel.text = @"Logging In...";
        self.loadingViewController.view.hidden = NO;
        
        loginDict = tempDictionary;
        ArcClient *client = [[ArcClient alloc] init];
        [client getCustomerToken:loginDict];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"LoginViewController.runLogin" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
    
}


-(void)signInComplete:(NSNotification *)notification{
    @try {
        
        self.loadingViewController.view.hidden = YES;
        
        
        self.passwordText.text = @"";
        [self.passwordText resignFirstResponder];
        [self.emailTtext resignFirstResponder];
        
        NSDictionary *responseInfo = [notification valueForKey:@"userInfo"];
        
        //NSLog(@"Response Info: %@", responseInfo);
        
        NSString *status = [responseInfo valueForKey:@"status"];
        
        
        NSString *errorMsg = @"";
        if ([status isEqualToString:@"success"]) {
            //success
            [[NSUserDefaults standardUserDefaults] setValue:self.emailTtext.text forKey:@"customerEmail"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            ArcClient *client = [[ArcClient alloc] init];
            [client getServer];
            
            PaymentManager *tmp = [PaymentManager sharedInstance];
            [tmp getCreditCardList];
        
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"You have successfully signed in." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alert show];
            
            
            [self handleSuccess];
            
            
            
            
            //Do the next thing (go home?)
        } else if([status isEqualToString:@"error"]){
            int errorCode = [[responseInfo valueForKey:@"error"] intValue];
            if(errorCode == INCORRECT_LOGIN_INFO) {
                errorMsg = @"Invalid Email and/or Password";
            } else {
                // TODO -- programming error client/server coordination -- rskybox call
                errorMsg = ARC_ERROR_MSG;
            }
        } else {
            // must be failure -- user notification handled by ArcClient
            errorMsg = ARC_ERROR_MSG;
        }
        
        if([errorMsg length] > 0) {
            //self.errorLabel.text = errorMsg;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
        
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"LoginViewController.signInComplete" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        
        
    }
    
}

-(void)handleSuccess{
    
    UIViewController *homenav = [self.storyboard instantiateViewControllerWithIdentifier:@"homenav"];
    [self presentViewController:homenav animated:NO completion:nil];
}

@end
