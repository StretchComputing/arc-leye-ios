//
//  ViewController.m
//  leyevent
//
//  Created by Nick Wroblewski on 5/6/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated{

    
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"customerToken"] length] > 0){
        //logged in, go home
        UIViewController *homenav = [self.storyboard instantiateViewControllerWithIdentifier:@"homenav"];
        [self presentViewController:homenav animated:NO completion:nil];
        
    }else{
        //not logged in, sign up/register screen
        UIViewController *homenav = [self.storyboard instantiateViewControllerWithIdentifier:@"register"];
        [self presentViewController:homenav animated:NO completion:nil];
    }

    
 
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
