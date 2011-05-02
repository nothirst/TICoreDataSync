//
//  MyDocument.m
//  ShoppingListMac
//
//  Created by Tim Isted on 14/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "MyDocument.h"

#import "TIDocumentSyncChangesWindowController.h"
#import "TIDocumentShopsWindowController.h"

@interface MyDocument () 

- (void)updateInterfaceForSyncEnabled;
- (void)registerSyncManagerIfSyncEnabled;
- (void)increaseActivity;
- (void)decreaseActivity;

@end

NSString * const kTISLIsSyncEnabled = @"kTISLIsSyncEnabled";
NSString * const kTISLDocumentSyncIdentifier = @"kTISLDocumentSyncIdentifier";

@implementation MyDocument

#pragma mark -
#pragma mark Core Data Stack
- (NSManagedObjectContext *)managedObjectContext
{
    if( _synchronizedManagedObjectContext ) {
        return _synchronizedManagedObjectContext;
    }
    
    _synchronizedManagedObjectContext = [[TICDSSynchronizedManagedObjectContext alloc] init];
    [_synchronizedManagedObjectContext setPersistentStoreCoordinator:[[super managedObjectContext] persistentStoreCoordinator]];
    
    [[super managedObjectContext] setUndoManager:nil];
    
    return _synchronizedManagedObjectContext;
}

- (id)managedObjectModel {
    static id sSharedModel = nil;
    if( sSharedModel ) {
        return sSharedModel;
    }
    
    sSharedModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShoppingList" ofType:@"momd"]]];
    
    return sSharedModel;
}

#pragma mark -
#pragma mark Synchronization
- (void)registerSyncManagerIfSyncEnabled
{
    if( ![self isSyncEnabled] ) {
        return;
    }
    
    if( ![self documentSyncManager] ) {
        _documentSyncManager = [[TICDSFileManagerBasedDocumentSyncManager alloc] init];
    }
    
    if( ![self documentSyncIdentifier] ) {
        _documentSyncIdentifier = [[TICDSUtilities uuidString] retain];
    }
    
    [[self documentSyncManager] registerWithDelegate:self appSyncManager:[TICDSApplicationSyncManager defaultApplicationSyncManager] managedObjectContext:(TICDSSynchronizedManagedObjectContext *)[self managedObjectContext] documentIdentifier:[self documentSyncIdentifier] description:[[[self fileURL] path] lastPathComponent] userInfo:[NSDictionary dictionaryWithObject:@"Hello" forKey:@"HelloKey"]];
    
    [self saveDocument:self];
}

- (void)configureSyncManagerForDownloadedStoreWithIdentifier:(NSString *)anIdentifier
{
    if( ![self documentSyncManager] ) {
        _documentSyncManager = [[TICDSFileManagerBasedDocumentSyncManager alloc] init];
    }
    
    [self setDocumentSyncIdentifier:anIdentifier];
    
    [[self documentSyncManager] configureWithDelegate:self appSyncManager:[TICDSApplicationSyncManager defaultApplicationSyncManager] documentIdentifier:anIdentifier];
}

#pragma mark -
#pragma mark CALLBACKS
#pragma mark Registration
- (void)syncManagerDidStartDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager
{
    [self increaseActivity];
}

- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo
{
    [self decreaseActivity];
    
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}

- (void)syncManagerDidResumeRegistration:(TICDSDocumentSyncManager *)aSyncManager
{
    [self increaseActivity];
}

- (void)syncManagerFailedToRegisterDocument:(TICDSDocumentSyncManager *)aSyncManager
{
    [self decreaseActivity];
}

- (void)syncManagerDidRegisterDocumentSuccessfully:(TICDSDocumentSyncManager *)aSyncManager
{
    [self decreaseActivity];
}

#pragma mark Whole Store Upload
- (BOOL)syncManagerShouldUploadWholeStoreAfterDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager
{
    // A Mac desktop Dropbox-sync-based application should upload relatively frequently, as it's just a simple copy from one location to another.
    return YES;
}

- (NSURL *)syncManager:(TICDSDocumentSyncManager *)aSyncManager URLForWholeStoreToUploadForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo
{
    return [self fileURL];
}

- (void)syncManagerDidBeginToUploadWholeStore:(TICDSDocumentSyncManager *)aSyncManager
{
    [self increaseActivity];
}

- (void)syncManagerFailedToUploadWholeStore:(TICDSDocumentSyncManager *)aSyncManager
{
    [self decreaseActivity];
}

- (void)syncManagerDidUploadWholeStoreSuccessfully:(TICDSDocumentSyncManager *)aSyncManager
{
    [self decreaseActivity];
}

#pragma mark Synchronization
- (BOOL)syncManager:(TICDSDocumentSyncManager *)aSyncManager shouldInitiateSynchronizationAfterSaveOfContext:(TICDSSynchronizedManagedObjectContext *)aMoc
{
    return YES;
}

- (void)syncManagerDidBeginToSynchronize:(TICDSDocumentSyncManager *)aSyncManager
{
    [self increaseActivity];
}

- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseSynchronizationAwaitingResolutionOfSyncConflict:(id)aConflict
{
    [self decreaseActivity];
    
    NSLog(@"Conflict = %@", aConflict);
    
    [aSyncManager continueSynchronizationByResolvingConflictWithResolutionType:TICDSSyncConflictResolutionTypeLocalWins];
}

- (void)syncManagerDidResumeSynchronization:(TICDSDocumentSyncManager *)aSyncManager
{
    [self increaseActivity];
}

- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager didMakeChangesToObjectsInBackgroundContextAndSaveWithNotification:(NSNotification *)aNotification
{
    [[[self managedObjectContext] undoManager] disableUndoRegistration];
    [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:aNotification];
    
    NSError *anyError = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:[[self fileURL] path] error:&anyError];
    [fileManager release];
    if( !attributes ) {
        NSLog(@"Failed to get attributes for document's persistent store");
        return;
    }
    
    NSDate *modificationDate = [attributes valueForKey:NSFileModificationDate];
    
    if( !modificationDate ) {
        NSLog(@"Failed to get modification date for document's persistent store");
    }
    
    [self setFileModificationDate:modificationDate];
    
    [[self managedObjectContext] processPendingChanges];
    
    [[[self managedObjectContext] undoManager] enableUndoRegistration];
    [[[self managedObjectContext] undoManager] removeAllActions];

    [self updateChangeCount:NSChangeCleared];
}

- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager encounteredSynchronizationError:(NSError *)anError
{
    NSLog(@"Sync Error: %@", anError);
}

- (void)syncManagerFailedToSynchronize:(TICDSDocumentSyncManager *)aSyncManager
{
    [self decreaseActivity];
}

- (void)syncManagerDidFinishSynchronization:(TICDSDocumentSyncManager *)aSyncManager
{
    [[self documentSyncChangesWindowController] setManagedObjectContext:[[self documentSyncManager] syncChangesMOC]];
    [self decreaseActivity];
}

#pragma mark Vacuuming
- (BOOL)syncManagerShouldVacuumUnneededRemoteFilesAfterDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager
{
    return YES;
}

- (void)syncManagerDidBeginToVacuumUnneededRemoteFiles:(TICDSDocumentSyncManager *)aSyncManager
{
    [self increaseActivity];
}

- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager encounteredVacuumError:(NSError *)anError
{
    NSLog(@"Vacuum Error: %@", anError);
}

- (void)syncManagerFailedToVacuumUnneededRemoteFiles:(TICDSDocumentSyncManager *)aSyncManager
{
    [self decreaseActivity];
}

- (void)syncManagerDidFinishVacuumingUnneededRemoteFiles:(TICDSDocumentSyncManager *)aSyncManager
{
    [self decreaseActivity];
}

#pragma mark -
#pragma mark Metadata
- (NSDictionary *)customMetadataDictionary
{
    NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithCapacity:2];
    
    [metadata setValue:[NSNumber numberWithBool:[self isSyncEnabled]] forKey:kTISLIsSyncEnabled];
    
    if( [self documentSyncIdentifier] ) {
        [metadata setValue:[self documentSyncIdentifier] forKey:kTISLDocumentSyncIdentifier];
    }
    
    return metadata;
}

- (void)setAttributesFromMetadataDictionary:(NSDictionary *)aDictionary
{    
    [self setSyncEnabled:[[aDictionary valueForKey:kTISLIsSyncEnabled] boolValue]];
    [self setDocumentSyncIdentifier:[aDictionary valueForKey:kTISLDocumentSyncIdentifier]];
}

- (BOOL)setMetadataForStoreAtURL:(NSURL *)url
{
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[self managedObjectContext] persistentStoreCoordinator];
    NSPersistentStore *store = [persistentStoreCoordinator persistentStoreForURL:url];
    
    if( !store ) {
        return NO;
    }
    
    NSMutableDictionary *metadata = [[[persistentStoreCoordinator metadataForPersistentStore:store] mutableCopy] autorelease];
    if (metadata == nil) {
        metadata = [NSMutableDictionary dictionary];
    }
    
    [metadata setValuesForKeysWithDictionary:[self customMetadataDictionary]];
    
    [persistentStoreCoordinator setMetadata:metadata forPersistentStore:store];
    return YES;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)error
{
    if( [self fileURL] ) {
        [self setMetadataForStoreAtURL:[self fileURL]];
    }
    
    return [super writeToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:error];
}

- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)url ofType:(NSString *)fileType modelConfiguration:(NSString *)configuration storeOptions:(NSDictionary *)storeOptions error:(NSError **)error
{
    BOOL shouldContinue = [super configurePersistentStoreCoordinatorForURL:url ofType:fileType modelConfiguration:configuration storeOptions:storeOptions error:error];
    
    if( !shouldContinue ) {
        return shouldContinue;
    }
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[self managedObjectContext] persistentStoreCoordinator];
    NSPersistentStore *store = [persistentStoreCoordinator persistentStoreForURL:url];
    
    id existingMetadata = [persistentStoreCoordinator metadataForPersistentStore:store];
    if( existingMetadata ) {
        [self setAttributesFromMetadataDictionary:existingMetadata];
    } else {
        shouldContinue = [self setMetadataForStoreAtURL:url];
    }
    
    return shouldContinue;
}

#pragma mark -
#pragma mark Actions
- (IBAction)showSyncChangesWindow:(id)sender
{
    if( [self documentSyncManager] ) {
        [[self documentSyncChangesWindowController] showWindow:sender];
    }
}

- (IBAction)showShopsWindow:(id)sender
{
    [[self documentShopsWindowController] showWindow:sender];
}

/*- (IBAction)saveDocument:(id)sender
{
    [[self managedObjectContext] processPendingChanges];
    
    [super saveDocument:sender];
}*/

- (IBAction)initiateSynchronization:(id)sender
{
    [[self documentSyncManager] initiateSynchronization];
}

- (IBAction)initiateVacuum:(id)sender
{
    [[self documentSyncManager] initiateVacuumOfUnneededRemoteFiles];
}

// Callback from save
- (void)document:(NSDocument *)aDocument didSave:(BOOL)didSave contextInfo:(void *)contextInfo
{
    if( didSave ) {
        [self configureSynchronization:self];
    }
}

- (IBAction)configureSynchronization:(id)sender
{
    // Check that document has been saved before configuring sync:
    if( ![self fileURL] ) {
        [self saveDocumentWithDelegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:nil];
    } else {
        [self setSyncEnabled:YES];
        [self updateInterfaceForSyncEnabled];
        [self registerSyncManagerIfSyncEnabled];
    }
}

#pragma mark -
#pragma mark Notifications
- (void)managedObjectContextDidSave:(NSNotification *)aNotification
{
    if( [aNotification object] == [self managedObjectContext] || [[aNotification object] persistentStoreCoordinator] != [[self managedObjectContext] persistentStoreCoordinator] ) {
        return;
    }
    
    [self performSelectorOnMainThread:@selector(mergeChanges:) withObject:aNotification waitUntilDone:YES];
}

- (void)mergeChanges:(NSNotification *)notification {
    [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
}

#pragma mark -
#pragma mark User Interface
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    
    [aController setShouldCloseDocument:YES];
    
    [self updateInterfaceForSyncEnabled];
    [self registerSyncManagerIfSyncEnabled];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

- (void)makeWindowControllers
{
    NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"MyDocument" owner:self];
    
    [self addWindowController:windowController];
    
    [windowController release];
}

- (void)updateInterfaceForSyncEnabled
{
    if( [self isSyncEnabled] ) {
        [[self synchronizationStatusLabel] setStringValue:NSLocalizedString(@"Enabled", @"Synchronization Enabled")];
        [[self enableSynchronizationButton] setHidden:YES];
        [[self synchronizeButton] setEnabled:YES];
        [[self vacuumButton] setHidden:NO];
    } else {
        [[self synchronizationStatusLabel] setStringValue:NSLocalizedString(@"Not Enabled", @"Synchronization Not Enabled")];
        [[self enableSynchronizationButton] setHidden:NO];
        [[self synchronizeButton] setEnabled:NO];
        [[self vacuumButton] setHidden:YES];
    }    
}

- (void)increaseActivity
{
    _synchronizationActivity++;
    
    if( _synchronizationActivity > 0 ) {
        [[self synchronizingProgressIndicator] setHidden:NO];
        [[self synchronizingProgressIndicator] startAnimation:self];
    }
}

- (void)decreaseActivity
{
    if( _synchronizationActivity > 0 ) {
        _synchronizationActivity--;
    }
    
    if( _synchronizationActivity < 1 ) {
        [[self synchronizingProgressIndicator] stopAnimation:self];
        [[self synchronizingProgressIndicator] setHidden:YES];
    }
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_documentSyncIdentifier release], _documentSyncIdentifier = nil;
    [_documentSyncManager release], _documentSyncManager = nil;
    [_synchronizedManagedObjectContext release], _synchronizedManagedObjectContext = nil;
    [_documentSyncChangesWindowController release], _documentSyncChangesWindowController = nil;
    [_documentShopsWindowController release], _documentShopsWindowController = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize syncEnabled = _syncEnabled;
@synthesize documentSyncIdentifier = _documentSyncIdentifier;
@synthesize documentSyncManager = _documentSyncManager;
@synthesize synchronizedManagedObjectContext = _synchronizedManagedObjectContext;
@synthesize synchronizationStatusLabel = _synchronizationStatusLabel;
@synthesize synchronizingProgressIndicator = _synchronizingProgressIndicator;
@synthesize enableSynchronizationButton = _enableSynchronizationButton;
@synthesize synchronizeButton = _synchronizeButton;
@synthesize vacuumButton = _vacuumButton;
@synthesize documentSyncChangesWindowController = _documentSyncChangesWindowController;
@synthesize documentShopsWindowController = _documentShopsWindowController;

- (TIDocumentSyncChangesWindowController *)documentSyncChangesWindowController
{
    if( _documentSyncChangesWindowController ) {
        return _documentSyncChangesWindowController;
    }
    
    _documentSyncChangesWindowController = [[TIDocumentSyncChangesWindowController alloc] initWithManagedObjectContext:[[self documentSyncManager] syncChangesMOC]];

    [self addWindowController:_documentSyncChangesWindowController];
    
    return _documentSyncChangesWindowController;
}

- (TIDocumentShopsWindowController *)documentShopsWindowController
{
    if( _documentShopsWindowController ) return _documentShopsWindowController;
    
    _documentShopsWindowController = [[TIDocumentShopsWindowController alloc] initWithManagedObjectContext:[self managedObjectContext]];
    
    [self addWindowController:_documentShopsWindowController];
    
    return _documentShopsWindowController;
}

@end
