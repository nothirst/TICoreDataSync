//
//  StringEditorViewController.m
//  iOSNotebook
//
//  Created by Tim Isted on 01/06/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TIStringEditorViewController.h"

@interface TIStringEditorViewController () <UITextFieldDelegate>
@end

@implementation TIStringEditorViewController

#pragma mark -
#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
    [[self navigationItem] setLeftBarButtonItem:cancelButton];
    [cancelButton release];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    [[self navigationItem] setRightBarButtonItem:doneButton];
    [doneButton release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[self textField] setText:[self initialString]];
}

#pragma mark -
#pragma mark Actions
- (void)cancelAction:(id)sender
{
    if( [[self delegate] respondsToSelector:@selector(stringEditorViewControllerDidCancel:)] ) {
        [[self delegate] stringEditorViewControllerDidCancel:self];
    }
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)doneAction:(id)sender
{
    BOOL shouldPop = [[self delegate] stringEditorViewController:self shouldDismissWithString:[[self textField] text]];
    
    if( shouldPop ) {
        [[self navigationController] popViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark Text Field Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self doneAction:textField];
    
    return YES;
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)initWithInitialString:(NSString *)aString delegate:(NSObject <TIStringEditorViewControllerDelegate> *)aDelegate userInfo:(NSObject *)info
{
    self = [super initWithNibName:@"TIStringEditorViewController" bundle:nil];
    if( !self ) {
        return nil;
    }
    
    _initialString = [aString retain];
    _delegate = aDelegate;
    _userInfo = [info retain];
    
    return self;
}

- (void)dealloc
{
    [_initialString release], _initialString = nil;
    [_textField release], _textField = nil;
    [_userInfo release], _userInfo = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize delegate = _delegate;
@synthesize initialString = _initialString;
@synthesize textField = _textField;
@synthesize userInfo = _userInfo;

@end
