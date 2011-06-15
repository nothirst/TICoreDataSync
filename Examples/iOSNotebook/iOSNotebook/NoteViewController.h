//
//  NoteViewController.h
//  iOSNotebook
//
//  Created by Tim Isted on 15/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

@class TINBNote;

@interface NoteViewController : UIViewController {
@private
    TINBNote *_note;
    
    UITextView *_mainTextView;
    UITextField *_tagsTextField;
    UITextField *_titleTextField;
    UITextView *_editingTextView;
}

- (id)initWithNote:(TINBNote *)aNote;

- (IBAction)editTags:(id)sender;

@property (nonatomic, assign) TINBNote *note;

@property (nonatomic, retain) IBOutlet UITextView *mainTextView;
@property (nonatomic, retain) IBOutlet UITextField *tagsTextField;
@property (nonatomic, retain) IBOutlet UITextField *titleTextField;
@property (nonatomic, retain) IBOutlet UITextView *editingTextView;

@end
