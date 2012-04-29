//
//  JBAServerReplyViewController.h
//  JBoss Admin
//
//  Author: Christos Vasilakis <cvasilak@gmail.com>
//  Copyright 2012 All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JBAServerReplyViewController : UITableViewController

@property(strong, nonatomic) NSString *operationName;
@property(strong, nonatomic) NSString *reply;

@end
