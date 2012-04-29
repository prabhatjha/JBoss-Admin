//
//  ToggleSwitchCell.h
//  JBoss Admin
//
//  Author: Christos Vasilakis <cvasilak@gmail.com>
//  Copyright 2012 All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LabelCell.h"

@interface ToggleSwitchCell : LabelCell

- (id)initWithCellIdentifier:(NSString *)cellID;

@property(strong, readonly, nonatomic) UISwitch *toggler;

@end
