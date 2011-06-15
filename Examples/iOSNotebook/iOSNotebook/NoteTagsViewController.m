//
//  NoteTagsViewController.m
//  iOSNotebook
//
//  Created by Tim Isted on 01/06/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "NoteTagsViewController.h"
#import "TINBTag.h"
#import "TINBNote.h"
#import "TIStringEditorViewController.h"

@interface NoteTagsViewController () <TIStringEditorViewControllerDelegate>
@end

@implementation NoteTagsViewController

#pragma mark -
#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    [[self tableView] setAllowsSelectionDuringEditing:YES];
    [self setTitle:@"Tags"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(persistentStoresDidChange:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:[[[self note] managedObjectContext] 
             persistentStoreCoordinator]];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:[[[self note] managedObjectContext] 
             persistentStoreCoordinator]];
    
    [super viewDidUnload];
}

#pragma mark -
#pragma mark Notifications
- (void)persistentStoresDidChange:(NSNotification *)aNotification
{
    NSError *anyError = nil;
    BOOL success = [[self fetchedResultsController] performFetch:&anyError];
    if( !success ) {
        NSLog(@"Error fetching: %@", anyError);
    }
    [[self tableView] reloadData];
}

#pragma mark -
#pragma mark Editing
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [[self tableView] beginUpdates];
    if( editing ) {
        [super setEditing:editing animated:animated];
        [[self tableView] insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        [super setEditing:editing animated:animated];
    }
    [[self tableView] endUpdates];
    
}

#pragma mark -
#pragma mark Cell Display
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if( [indexPath section] > 0 ) {
        return;
    }
    
    TINBTag *tag = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    [[cell textLabel] setText:[tag name]];
    
    if( [[[self note] tags] containsObject:tag] ) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
}

#pragma mark -
#pragma mark Insertion
- (void)insertTag
{
    TIStringEditorViewController *stringEditorVC = [[TIStringEditorViewController alloc] initWithInitialString:@"" delegate:self userInfo:nil];
    [stringEditorVC setTitle:@"Add Tag"];
    [[self navigationController] pushViewController:stringEditorVC animated:YES];
    [stringEditorVC release];
}

#pragma mark -
#pragma mark Table View Data Source and Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self isEditing] ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if( section < 1 ) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsController] sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    static NSString *CellIdentifier = @"Cell";
    static NSString *AddCellIdentifier = @"AddCell";
    
    if( [indexPath section] > 0 ) {
        cell = [tableView dequeueReusableCellWithIdentifier:AddCellIdentifier];
        
        if( !cell ) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AddCellIdentifier] autorelease];
            [[cell textLabel] setText:@"Add Tag"];
        }
        
        return cell;
    }
    
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( [indexPath section] < 1 ) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleInsert;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self isEditing];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the managed object for the given index path
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[[self fetchedResultsController] objectAtIndexPath:indexPath]];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if( [indexPath section] > 0 ) {
        [self insertTag];
        return;
    }
    TINBTag *tag = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    if( [self isEditing] ) {
        TIStringEditorViewController *stringEditorVC = [[TIStringEditorViewController alloc] initWithInitialString:[tag name] delegate:self userInfo:tag];
        [stringEditorVC setTitle:@"Edit Tag"];
        [[self navigationController] pushViewController:stringEditorVC animated:YES];
        [stringEditorVC release];
    } else {
        if( [[[self note] tags] containsObject:tag] ) {
            [[self note] removeTagsObject:tag];
        } else {
            [[self note] addTagsObject:tag];
        }
        
        NSError *anyError = nil;
        BOOL success = [[[self note] managedObjectContext] save:&anyError];
        if( !success ) {
            NSLog(@"Error saving: %@", anyError);
        }
        
        [[self tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark -
#pragma mark String Editor VC Delegate
- (BOOL)stringEditorViewController:(TIStringEditorViewController *)aViewController shouldDismissWithString:(NSString *)aString
{
    if( [aString length] < 1 ) {
        return NO;
    }
    
    TINBTag *tag = (id)[aViewController userInfo];
    
    if( !tag ) {
        tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:[[self note] managedObjectContext]];
        [[self note] addTagsObject:tag];
    }
    
    [tag setName:aString];
    
    NSError *anyError = nil;
    BOOL success = [[[self note] managedObjectContext] save:&anyError];
    if( !success ) {
        NSLog(@"Error saving: %@", anyError);
    }
    
    return YES;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil)
    {
        return __fetchedResultsController;
    }
    
    /*
     Set up the fetched results controller.
     */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:[[self note] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[self note] managedObjectContext] sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error])
    {
	    /*
	     Replace this implementation with code to handle the error appropriately.
         
	     abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
	     */
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return __fetchedResultsController;
}    

#pragma mark - Fetched results controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type)
    {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)initWithNote:(TINBNote *)aNote
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if( !self ) {
        return nil;
    }
    
    _note = [aNote retain];
    
    return self;
}

- (void)dealloc
{
    [_note release], _note = nil;
    [__fetchedResultsController release], __fetchedResultsController = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize note = _note;
@synthesize fetchedResultsController=__fetchedResultsController;

@end
