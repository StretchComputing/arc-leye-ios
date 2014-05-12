//
//  SettingsViewController.m
//  leyevent
//
//  Created by Nick Wroblewski on 5/7/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import "SettingsViewController.h"
#import "rSkybox.h"
#import "ArcClient.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

-(void)viewWillAppear:(BOOL)animated{
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    self.versionLabel.text = [NSString stringWithFormat:@"version %@", appVersionString];
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
    [self.myTableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)goBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
	
    
    if (section == 0){
        return 2;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    @try {
        
        NSUInteger row = indexPath.row;
        NSUInteger section = indexPath.section;
        UITableViewCell *cell;
        
        if (section == 0) {
            
            if (row == 0) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"settingscell"];

            }else{
                cell = [tableView dequeueReusableCellWithIdentifier:@"contactuscell"];

            }
            cell.selectionStyle = UITableViewCellSelectionStyleGray;

        }else{
            
            
            cell = [tableView dequeueReusableCellWithIdentifier:@"logoutcell"];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

        }
        
        
        
        
        
        
        
        
        
        
        
        return cell;
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"SupportViewController.tableView" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
        
    }
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    @try {
        NSUInteger section = indexPath.section;
        NSUInteger row = indexPath.row;
        
        if (section == 0) {
            
            if (row == 0) {
                //Help
                [ArcClient trackEvent:@"SELECT_HELP"];
               
                
            }else if (row == 1){
                
                [ArcClient trackEvent:@"SELECT_CONTACT_US"];
                
                [self emailFeedbackAction];
                
            }
            
            
        }else if (section == 1){
            [self logout];
        }
    }
    @catch (NSException *exception) {
        [rSkybox sendClientLog:@"SupportViewController.didSelectRowAtIndexPath" logMessage:@"Exception Caught" logLevel:@"error" exception:exception];
        
    }
    
    
    
}

-(void)logout{
    
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"customerEmail"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"customerToken"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"customerId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    

    [self dismissViewControllerAnimated:NO completion:nil];
    
}


- (IBAction)callAction {
    
    @try {
        
        [rSkybox addEventToSession:@"phoneCallToArc"];
        
        if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]){
            
            NSString *phoneNumber = [[NSUserDefaults standardUserDefaults] valueForKey:@"arcPhoneNumber"];
            
            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
            
            
            
            NSString *url = [@"tel://" stringByAppendingString:phoneNumber];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            
            
            
        }else {
            
            NSString *message1 = @"You cannot make calls from this device.";
            UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"Invalid Device." message:message1 delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert1 show];
            
        }
        
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"SupportViewController.call" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
    
    
}
- (IBAction)emailAction {
    
    @try {
        
        [rSkybox addEventToSession:@"emailToArc"];
        
        if ([MFMailComposeViewController canSendMail]) {
            
            MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
            mailViewController.mailComposeDelegate = self;
            [mailViewController setToRecipients:@[[[NSUserDefaults standardUserDefaults] valueForKey:@"arcMail"]]];
            
            [self presentViewController:mailViewController animated:YES completion:nil];
            
        }else {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Device." message:@"Your device cannot currently send email." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
        
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"SupportViewController.email" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
}


- (void)emailFeedbackAction {
    
    @try {
        
        [rSkybox addEventToSession:@"emailFeedbackToArc"];
        
        if ([MFMailComposeViewController canSendMail]) {
            
            MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
            mailViewController.mailComposeDelegate = self;
            [mailViewController setToRecipients:[NSArray arrayWithObject:@"support@arcmobile.co"]];
            [mailViewController setSubject:@"Feedback"];
            
            [self presentViewController:mailViewController animated:YES completion:nil];
            
        }else {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Device." message:@"Your device cannot currently send email." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
        
    }
    @catch (NSException *e) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Device." message:@"Your device cannot currently send email." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        
        
        [rSkybox sendClientLog:@"SupportViewController.email" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
    
}

/*
 -(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
 
 if (section == 1) {
 return @"Dono";
 }else if (section == 2){
 return @"Contact Us";
 }else{
 return @"Donations";
 }
 }
 */
-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    @try {
        
        switch (result)
        {
            case MFMailComposeResultCancelled:
                break;
            case MFMailComposeResultSent:
                
                break;
            case MFMailComposeResultFailed:
                
                break;
                
            case MFMailComposeResultSaved:
                
                break;
            default:
                
                break;
        }
        
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    @catch (NSException *e) {
        [rSkybox sendClientLog:@"SupportVC.mailComposeController" logMessage:@"Exception Caught" logLevel:@"error" exception:e];
    }
}



@end
