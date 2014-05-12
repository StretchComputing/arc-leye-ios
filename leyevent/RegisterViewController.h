//
//  RegisterViewController.h
//  leyevent
//
//  Created by Nick Wroblewski on 5/6/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadingViewController.h"

@class LoadingViewController;

@interface RegisterViewController : UIViewController

@property (nonatomic, strong) LoadingViewController *loadingViewController;
@property (strong, nonatomic) IBOutlet UIView *tableBackView;
@property (strong, nonatomic) IBOutlet UITextField *nameText;
@property (strong, nonatomic) IBOutlet UITextField *emailText;
@property (strong, nonatomic) IBOutlet UITextField *passwordText;

-(IBAction)endText;
@end
