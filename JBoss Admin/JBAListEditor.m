/*
 * JBoss Admin
 * Copyright 2012, Christos Vasilakis, and individual contributors.
 * See the copyright.txt file in the distribution for a full
 * listing of individual contributors.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 */

#import "JBAListEditor.h"
#import "JBossValue.h"
#import "JBAManagementModel.h"

#import "JSONKit.h"

#import "EditCell.h"
#import "ToggleSwitchCell.h"
#import "ButtonCell.h"

// Table Sections
enum JBAListEditorTableSections {
    JBATableEditorSection = 0,
    JBATableAddSection,
    JBATableListEditorNumSections
};

@interface JBAListEditor()

- (void)addValue;

@end

@implementation JBAListEditor {
    UITextField *_textFieldBeingEdited;
}

@synthesize items = _items;
@synthesize valueType = _valueType;
@synthesize isReadOnlyMode = _isReadOnlyMode;

-(void)dealloc {
    DLog(@"JBAListEditor dealloc");    
}

#pragma mark - View lifecycle
- (void)viewDidUnload {
    DLog(@"JBAListEditor viewDidUnLoad");
    
    [super viewDidUnload];
}

- (void)viewDidLoad {
    DLog(@"JBAListEditor viewDidLoad");
    
    UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" 
                                                                        style:UIBarButtonItemStyleBordered 
                                                                       target:self action:@selector(close)];
    self.navigationItem.leftBarButtonItem = closeButtonItem;

    if (!self.isReadOnlyMode)
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Table Data Source Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return JBATableListEditorNumSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == JBATableAddSection)
        return (self.isReadOnlyMode? 0: 1);
    
    return [self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
    
    id cell;
    
    switch (section) {
        case JBATableEditorSection:
        {
            if (self.valueType == BOOLEAN) {
                ToggleSwitchCell *toggleCell = [ToggleSwitchCell cellForTableView:tableView];

                [toggleCell.toggler addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
                toggleCell.toggler.on = [[self.items objectAtIndex:row] boolValue];

                cell = toggleCell;
                
            } else {
                EditCell *editCell = [EditCell cellForTableView:tableView];                

                if (   self.valueType == INT
                    || self.valueType == LONG 
                    || self.valueType == DOUBLE
                    || self.valueType == BIG_DECIMAL
                    || self.valueType == BIG_INTEGER)
                    editCell.txtField.keyboardType = UIKeyboardTypeDecimalPad;
                else
                    editCell.txtField.keyboardType = UIKeyboardTypeDefault;
                
                editCell.txtField.placeholder = [JBAManagementModel stringFromType:self.valueType];
                editCell.txtField.text = [[self.items objectAtIndex:row] cellDisplay];
                editCell.txtField.userInteractionEnabled = !self.isReadOnlyMode;
                editCell.txtField.delegate = self;
                [editCell.txtField addTarget:self action:@selector(textFieldDone:) forControlEvents:UIControlEventEditingDidEndOnExit];                    
                editCell.adjustX = YES;
                
                cell = editCell;
            }
            
            break;
        }
        
        case JBATableAddSection:
        {
            ButtonCell *addCell = [ButtonCell cellForTableView:tableView];
            
            addCell.imageView.image = [UIImage imageNamed:@"add.png"];
            
            addCell.textLabel.font = [UIFont italicSystemFontOfSize:16];
            addCell.textLabel.textAlignment = UITextAlignmentCenter;
            
            addCell.textLabel.text = @"Add Value";                        
            
            cell = addCell;
           
            break;
        }
        
    }
    return cell;
}

#pragma mark - Table Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section = [indexPath section];
    
    if (section == JBATableAddSection)
        [self addValue];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section = [indexPath section];
    
    if (self.isReadOnlyMode || section == JBATableAddSection)
        return NO;
    
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section = [indexPath section];
    
    if (section == JBATableAddSection)
        return NO;
    
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath {
    NSUInteger fromRow = [fromIndexPath row];
    NSUInteger toRow = [toIndexPath row];
    
    id object = [self.items objectAtIndex:fromRow];
    [self.items removeObjectAtIndex:fromRow];
    [self.items insertObject:object atIndex:toRow];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.items removeObjectAtIndex:row];

        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                         withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Update the model as the "widget values" change
- (void)switchValueChanged:(id)sender {
    UISwitch *toggler = (UISwitch *) sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell*)[[toggler superview] superview]];    
    [self.items replaceObjectAtIndex:[indexPath row] withObject:[NSNumber numberWithBool:toggler.on]];
}

#pragma mark - UITextFieldDelegate methods
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _textFieldBeingEdited = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell*)[[textField superview] superview]];

    // TODO couldn't find value to test, need more checks
    if (![textField.text isEqualToString:@""]) {
        if (self.valueType == INT)
            [self.items replaceObjectAtIndex:[indexPath row] withObject:[NSNumber numberWithInt:[textField.text integerValue]]];
        else if (self.valueType == LONG || self.valueType == BIG_INTEGER)
            [self.items replaceObjectAtIndex:[indexPath row] withObject:[NSNumber numberWithLong:[textField.text longLongValue]]];
        else if (self.valueType == DOUBLE || self.valueType == BIG_DECIMAL)
            [self.items replaceObjectAtIndex:[indexPath row] withObject:[NSNumber numberWithDouble:[textField.text doubleValue]]];
        else if (self.valueType == OBJECT) { // TODO: better handling
            id value = [textField.text objectFromJSONString];
            
            if (value == nil) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                                message:@"Invalid JSON string that represents an Object type!"
                                                               delegate:nil 
                                                      cancelButtonTitle:@"Bummer"
                                                      otherButtonTitles:nil];
                [alert show];
                return;

            } else {
                [self.items replaceObjectAtIndex:[indexPath row] withObject:value];                
            }
        }
        else // string
            [self.items replaceObjectAtIndex:[indexPath row] withObject:textField.text];
    }
}

- (void)textFieldDone:(UITextField *)sender {
    [sender resignFirstResponder];
}

#pragma mark - Actions
- (void)close {
    if (!self.isReadOnlyMode) {
        // if the keyboard is open
        // on a textfield textFieldDidEndEditing will be called
        // to fill out the value
        if (_textFieldBeingEdited != nil)
            [_textFieldBeingEdited resignFirstResponder];
        }
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)addValue {
    // TODO couldn't find value to test, need more checks
    if (self.valueType == BOOLEAN)
        [self.items addObject:[NSNumber numberWithBool:NO]];
     else
        [self.items addObject:@""];
    
    NSIndexPath *index = [NSIndexPath indexPathForRow:[self.items count]-1 inSection:JBATableEditorSection];
    
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:index] withRowAnimation:UITableViewRowAnimationBottom];
}

@end
