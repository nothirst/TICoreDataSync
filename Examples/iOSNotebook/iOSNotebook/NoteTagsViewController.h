//
//  NoteTagsViewController.h
//  iOSNotebook
//
//  Created by Tim Isted on 01/06/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

@class TINBNote;

@interface NoteTagsViewController : UITableViewController <NSFetchedResultsControllerDelegate> {
    TINBNote *_note;
    NSFetchedResultsController *__fetchedResultsController;
}

- (id)initWithNote:(TINBNote *)aNote;

@property (nonatomic, retain) TINBNote *note;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@end
