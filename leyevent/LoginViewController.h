//
//  LoginViewController.h
//  leyevent
//
//  Created by Nick Wroblewski on 5/6/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadingViewController.h"

@class LoadingViewController;

@interface LoginViewController : UIViewController

@property (nonatomic, strong) LoadingViewController *loadingViewController;
@property (strong, nonatomic) IBOutlet UITextField *emailTtext;
@property (strong, nonatomic) IBOutlet UITextField *passwordText;
@property (strong, nonatomic) IBOutlet UIView *tableBackView;

-(IBAction)endText;
@end
