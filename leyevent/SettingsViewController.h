//
//  SettingsViewController.h
//  leyevent
//
//  Created by Nick Wroblewski on 5/7/14.
//  Copyright (c) 2014 Arc Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface SettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) IBOutlet UITableView *myTableView;
@end
