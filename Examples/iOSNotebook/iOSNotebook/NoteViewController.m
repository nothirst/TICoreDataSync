//
//  NoteViewController.m
//  iOSNotebook
//
//  Created by Tim Isted on 15/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "NoteViewController.h"
#import "TINBNote.h"
#import "TINBTag.h"
#import "NoteTagsViewController.h"

@implementation NoteViewController

#pragma mark -
#pragma mark Interface Updates
- (void)updateTags
{
    NSMutableArray *tagNames = [NSMutableArray arrayWithCapacity:[[[self note] tags] count]];
    for( TINBTag *eachTag in [[self note] tags] ) {
        [tagNames addObject:[eachTag name]];
    }
    NSString *tagsString = [tagNames componentsJoinedByString:@", "];
    [[self tagsTextField] setText:tagsString];
}

#pragma mark -
#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    
    //set overlay button for tags text field
    UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [button addTarget:self action:@selector(editTags:) forControlEvents:UIControlEventTouchUpInside];
    [[self tagsTextField] setRightView:button];
    [[self tagsTextField] setRightViewMode:UITextFieldViewModeAlways];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(persistentStoresDidChange:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:[[[self note] managedObjectContext]persistentStoreCoordinator]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setTitle:[[self note] title]];
    
    [[self mainTextView] setText:[[self note] content]];
    [[self editingTextView] setText:[[self note] content]];
    [[self titleTextField] setText:[[self note] title]];
    
    [[self mainTextView] setHidden:[self isEditing]];
    [[self editingTextView] setHidden:![self isEditing]];
    [[self titleTextField] setHidden:![self isEditing]];
    
    [self updateTags];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if( [self isEditing] ) {
        [[self editingTextView] becomeFirstResponder];
    }
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:[[[self note] managedObjectContext]persistentStoreCoordinator]];
    
    [super viewDidUnload];
}

#pragma mark -
#pragma mark Notifications
- (void)persistentStoresDidChange:(NSNotification *)aNotification
{
    [[[self note] managedObjectContext] refreshObject:[self note] mergeChanges:YES];
    
    if( ![[self editingTextView] isFirstResponder] ) {
        [[self editingTextView] setText:[[self note] content]];
    }
    
    if( ![[self titleTextField] isFirstResponder] ) {
        [[self titleTextField] setText:[[self note] title]];
    }
    
    [self updateTags];
}

#pragma mark -
#pragma mark Editing
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [[self titleTextField] setHidden:!editing];
    [[self editingTextView] setHidden:!editing];
    [[self mainTextView] setHidden:editing];
    
    if( editing ) {
        [[self editingTextView] becomeFirstResponder];
    } else {
        [[self titleTextField] resignFirstResponder];
        [[self editingTextView] resignFirstResponder];
    }
}

- (IBAction)editTags:(id)sender
{
    NoteTagsViewController *tagsVC = [[NoteTagsViewController alloc] initWithNote:[self note]];
    
    [[self navigationController] pushViewController:tagsVC animated:YES];
    
    [tagsVC release];
}

#pragma mark -
#pragma mark Controls
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    [[self note] setContent:[[self editingTextView] text]];
    
    NSError *anyError = nil;
    if( ![[[self note] managedObjectContext] save:&anyError] )
        NSLog(@"Error saving: %@", anyError);
    
    [[self mainTextView] setText:[[self note] content]];
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return [self isEditing] && textField != [self tagsTextField];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [[self note] setTitle:[textField text]];
    
    NSError *anyError = nil;
    if( ![[[self note] managedObjectContext] save:&anyError] )
        NSLog(@"Error saving: %@", anyError);
    
    [self setTitle:[[self note] title]];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [[self editingTextView] becomeFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)initWithNote:(TINBNote *)aNote
{
    self = [super initWithNibName:@"NoteViewController" bundle:nil];
    
    if( !self ) {
        return nil;
    }
    
    _note = aNote;
    
    return self;
}

- (void)dealloc
{
    [_mainTextView release], _mainTextView  = nil;
    [_tagsTextField release], _tagsTextField = nil;
    [_titleTextField release], _titleTextField = nil;
    [_editingTextView release], _editingTextView = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize note = _note;
@synthesize mainTextView = _mainTextView;
@synthesize tagsTextField = _tagsTextField;
@synthesize titleTextField = _titleTextField;
@synthesize editingTextView = _editingTextView;

@end
