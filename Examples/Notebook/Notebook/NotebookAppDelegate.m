//
//  NotebookAppDelegate.m
//  Notebook
//
//  Created by Tim Isted on 04/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "NotebookAppDelegate.h"

#import "TINBTag.h"
#import "TIManagedObjectsToStringsValueTransfomer.h"
#import <SystemConfiguration/SystemConfiguration.h>

@implementation NotebookAppDelegate

+ (void)initialize
{
    [TICDSLog setVerbosity:TICDSLogVerbosityEveryStep];
}

- (void)awakeFromNib
{
    TIManagedObjectsToStringsValueTransfomer *transformer = (TIManagedObjectsToStringsValueTransfomer *)[TIManagedObjectsToStringsValueTransfomer valueTransformerForName:@"StringsToTINBTags"];    
    [transformer setManagedObjectContext:[self managedObjectContext]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidIncrease:) name:TICDSApplicationSyncManagerDidIncreaseActivityNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidDecrease:) name:TICDSApplicationSyncManagerDidDecreaseActivityNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidIncrease:) name:TICDSDocumentSyncManagerDidIncreaseActivityNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidDecrease:) name:TICDSDocumentSyncManagerDidDecreaseActivityNotification object:nil];

    TICDSFileManagerBasedApplicationSyncManager *manager = [TICDSFileManagerBasedApplicationSyncManager defaultApplicationSyncManager];
    [manager setApplicationContainingDirectoryLocation:[NSURL fileURLWithPath:[@"~/Dropbox" stringByExpandingTildeInPath]]];

    NSString *clientUuid = [[NSUserDefaults standardUserDefaults]
                            stringForKey:@"NotebookAppSyncClientUUID"];
    if( !clientUuid ) {
        clientUuid = [TICDSUtilities uuidString];
        [[NSUserDefaults standardUserDefaults]
         setValue:clientUuid
         forKey:@"NotebookAppSyncClientUUID"];
    }

    CFStringRef name = SCDynamicStoreCopyComputerName(NULL,NULL);
    NSString *deviceDescription =
    [NSString stringWithString:(NSString *)name];
    CFRelease(name);

    [manager registerWithDelegate:self
              globalAppIdentifier:@"com.yourcompany.notebook"
           uniqueClientIdentifier:clientUuid
                      description:deviceDescription
                         userInfo:nil];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)init
{
    self = [super init];
    if( !self ) {
        return nil;
    }
    
    TIManagedObjectsToStringsValueTransfomer *transformer = [[TIManagedObjectsToStringsValueTransfomer alloc] init];
    
    [transformer setAttributeName:@"name"];
    [transformer setEntityName:@"Tag"];
    
    [TIManagedObjectsToStringsValueTransfomer setValueTransformer:transformer forName:@"StringsToTINBTags"];
    [transformer release];
    
    return self;
}

- (void)dealloc
{
    [__managedObjectContext release];
    [__persistentStoreCoordinator release];
    [__managedObjectModel release];
    
    [super dealloc];
}

#pragma mark - Local methods

- (IBAction)beginSynchronizing:(id)sender
{
    // Save the managed object context to cause sync change objects to be written
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
    if (saveError != nil) {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, saveError);
    }

    [self.documentSyncManager initiateSynchronization];
}

#pragma mark - TICDSApplicationSyncManagerDelegate methods

- (void)applicationSyncManagerDidPauseRegistrationToAskWhetherToUseEncryptionForFirstTimeRegistration:(TICDSApplicationSyncManager *)aSyncManager
{
    [aSyncManager continueRegisteringWithEncryptionPassword:@"password"];
}

- (void)applicationSyncManagerDidPauseRegistrationToRequestPasswordForEncryptedApplicationSyncData:(TICDSApplicationSyncManager *)aSyncManager
{
    [aSyncManager continueRegisteringWithEncryptionPassword:@"password"];
}

- (TICDSDocumentSyncManager *)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager preConfiguredDocumentSyncManagerForDownloadedDocumentWithIdentifier:(NSString *)anIdentifier atURL:(NSURL *)aFileURL
{
    return nil;
}

- (void)applicationSyncManagerDidFinishRegistering:(TICDSApplicationSyncManager *)aSyncManager
{
    self.managedObjectContext.synchronized = YES;

    TICDSFileManagerBasedDocumentSyncManager *docSyncManager = [[TICDSFileManagerBasedDocumentSyncManager alloc] init];
    [docSyncManager registerWithDelegate:self
                          appSyncManager:aSyncManager
                    managedObjectContext:self.managedObjectContext
                      documentIdentifier:@"Notebook"
                             description:@"Application's data"
                                userInfo:nil];
    [self setDocumentSyncManager:docSyncManager];
}

#pragma mark - TICDSDocumentSyncManagerDelegate methods

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseSynchronizationAwaitingResolutionOfSyncConflict:(id)aConflict
{
    [aSyncManager continueSynchronizationByResolvingConflictWithResolutionType:TICDSSyncConflictResolutionTypeLocalWins];
}

- (NSURL *)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager URLForWholeStoreToUploadForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo
{
    return [[self applicationFilesDirectory] URLByAppendingPathComponent:@"Notebook.storedata"];
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo
{
    self.downloadStoreAfterRegistering = NO;
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseRegistrationAsRemoteFileStructureWasDeletedForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo
{
    self.downloadStoreAfterRegistering = NO;
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}

- (void)documentSyncManagerDidFinishRegistering:(TICDSDocumentSyncManager *)aSyncManager
{
    if (self.shouldDownloadStoreAfterRegistering) {
        [aSyncManager initiateDownloadOfWholeStore];
    } else {
        [aSyncManager initiateSynchronization];
    }

    [aSyncManager beginPollingRemoteStorageForChanges];
}

- (void)documentSyncManagerDidDetermineThatClientHadPreviouslyBeenDeletedFromSynchronizingWithDocument:(TICDSDocumentSyncManager *)aSyncManager
{
    self.downloadStoreAfterRegistering = YES;
}

- (BOOL)documentSyncManagerShouldUploadWholeStoreAfterDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager
{
    return self.shouldDownloadStoreAfterRegistering == NO;
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager willReplaceStoreWithDownloadedStoreAtURL:(NSURL *)aStoreURL
{
    NSError *anyError = nil;
    BOOL success = [self.persistentStoreCoordinator removePersistentStore:[self.persistentStoreCoordinator persistentStoreForURL:aStoreURL] error:&anyError];

    if (success == NO) {
        NSLog(@"Failed to remove persistent store at %@: %@", aStoreURL, anyError);
    }
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didReplaceStoreWithDownloadedStoreAtURL:(NSURL *)aStoreURL
{
    NSError *anyError = nil;
    id store = [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:aStoreURL options:nil error:&anyError];

    if (store == nil) {
        NSLog(@"Failed to add persistent store at %@: %@", aStoreURL, anyError);
    }
}

- (void)documentSyncManagerDidFinishDownloadingWholeStore:(TICDSDocumentSyncManager *)aSyncManager
{
    [aSyncManager initiateSynchronization];
}

- (BOOL)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager shouldBeginSynchronizingAfterManagedObjectContextDidSave:(NSManagedObjectContext *)aMoc;
{
    return YES;
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFailToSynchronizeWithError:(NSError *)anError
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, anError);
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didMakeChangesToObjectsInBackgroundContextAndSaveWithNotification:(NSNotification *)aNotification
{
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
    if (saveError != nil) {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, saveError);
    }
}

#pragma mark - Sync Manager Activity Notification methods

- (void)activityDidIncrease:(NSNotification *)aNotification
{
    self.activity++;

    if (self.activity > 0) {
        [self.activityIndicator startAnimation:self];
    }
}

- (void)activityDidDecrease:(NSNotification *)aNotification
{
    if (self.activity > 0) {
        self.activity--;
    }

    if (self.activity < 1) {
        [self.activityIndicator stopAnimation:self];
    }
}

#pragma mark -
#pragma mark Properties
@synthesize window = _window;
@synthesize notesArrayController = _notesArrayController;
@synthesize existingStore = _existingStore;

#pragma mark -
#pragma mark Apple Stuff
/**
 Returns the directory the application uses to store the Core Data store file. This code uses a directory named "Notebook" in the user's Library directory.
 */
- (NSURL *)applicationFilesDirectory {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryURL URLByAppendingPathComponent:@"Notebook"];
}

/**
 Creates if necessary and returns the managed object model for the application.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel) {
        return __managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Notebook" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if (__persistentStoreCoordinator) {
        return __persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    else {
        if ([[properties objectForKey:NSURLIsDirectoryKey] boolValue] != YES) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Notebook.storedata"];

    /* Add the check for an existing store here... */
    if ([fileManager fileExistsAtPath:url.path] == NO) {
        self.downloadStoreAfterRegistering = YES;
    }

    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        [__persistentStoreCoordinator release], __persistentStoreCoordinator = nil;
        return nil;
    }
    
    return __persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext) {
        return __managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    
    __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [__managedObjectContext setPersistentStoreCoordinator:coordinator];

    return __managedObjectContext;
}

/**
 Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
 */
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}

/**
 Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
 */
- (IBAction) saveAction:(id)sender {
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    
    // Save changes in the application's managed object context before the application terminates.
    
    if (!__managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        
        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}

@end
