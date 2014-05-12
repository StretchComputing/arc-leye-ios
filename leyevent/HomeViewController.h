//
//  HomeViewController.h
//  leyevent
//
//  Created by Nick Wroblewski on 5/6/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadingViewController.h"
#import "Invoice.h";

@class LoadingViewController;

@interface HomeViewController : UIViewController

@property (nonatomic, strong) LoadingViewController *loadingViewController;
@property (strong, nonatomic) IBOutlet UIButton *submitButton;
@property (strong, nonatomic) IBOutlet UITextField *numberText;
@property (nonatomic, strong) Invoice *myInvoice;
@end
