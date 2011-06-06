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
    TICDSFileManagerBasedApplicationSyncManager *manager = 
    [TICDSFileManagerBasedApplicationSyncManager 
     defaultApplicationSyncManager];
    
    [manager setApplicationContainingDirectoryLocation:
     [NSURL fileURLWithPath:
      [@"~/Dropbox" stringByExpandingTildeInPath]]];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidIncrease:) name:TICDSApplicationSyncManagerDidIncreaseActivityNotification object:manager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidDecrease:) name:TICDSApplicationSyncManagerDidDecreaseActivityNotification object:manager];
    
    [manager registerWithDelegate:self
              globalAppIdentifier:@"com.timisted.notebook" 
           uniqueClientIdentifier:clientUuid 
                      description:deviceDescription 
                         userInfo:nil];
}

#pragma mark -
#pragma mark Application Sync Manager Delegate
- (void)applicationSyncManagerDidPauseRegistrationToAskWhetherToUseEncryptionForFirstTimeRegistration:
(TICDSApplicationSyncManager *)aSyncManager
{
    [aSyncManager continueRegisteringWithEncryptionPassword:nil];
}

- (void)applicationSyncManagerDidPauseRegistrationToRequestPasswordForEncryptedApplicationSyncData:
(TICDSApplicationSyncManager *)aSyncManager
{
    [aSyncManager continueRegisteringWithEncryptionPassword:nil];
}

- (TICDSDocumentSyncManager *)applicationSyncManager:
(TICDSApplicationSyncManager *)aSyncManager
preConfiguredDocumentSyncManagerForDownloadedDocumentWithIdentifier:
(NSString *)anIdentifier atURL:(NSURL *)aFileURL
{
    return nil;
}

- (void)applicationSyncManagerDidFinishRegistering:
(TICDSApplicationSyncManager *)aSyncManager
{
    TICDSFileManagerBasedDocumentSyncManager *docSyncManager = 
    [[TICDSFileManagerBasedDocumentSyncManager alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidIncrease:) name:TICDSDocumentSyncManagerDidIncreaseActivityNotification object:docSyncManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidDecrease:) name:TICDSDocumentSyncManagerDidDecreaseActivityNotification object:docSyncManager];
    
    [docSyncManager registerWithDelegate:self 
                          appSyncManager:aSyncManager 
                    managedObjectContext:(TICDSSynchronizedManagedObjectContext *)[self managedObjectContext]
                      documentIdentifier:@"Notebook" 
                             description:@"Application's data" 
                                userInfo:nil];
    
    [self setDocumentSyncManager:docSyncManager];
    [docSyncManager release];
}

#pragma mark -
#pragma mark Document Sync Manager Delegate
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager
didPauseSynchronizationAwaitingResolutionOfSyncConflict:
(id)aConflict
{
    [aSyncManager 
     continueSynchronizationByResolvingConflictWithResolutionType:
     TICDSSyncConflictResolutionTypeLocalWins];
}

- (NSURL *)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager 
URLForWholeStoreToUploadForDocumentWithIdentifier:
(NSString *)anIdentifier 
                   description:(NSString *)aDescription 
                      userInfo:(NSDictionary *)userInfo
{
    return [[self applicationFilesDirectory] 
            URLByAppendingPathComponent:@"Notebook.storedata"];
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager
didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:(NSString *)anIdentifier 
description:(NSString *)aDescription 
userInfo:(NSDictionary *)userInfo
{
    [self setDownloadStoreAfterRegistering:NO];
    
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseRegistrationAsRemoteFileStructureWasDeletedForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo
{
    [self setDownloadStoreAfterRegistering:NO];
    
    NSLog(@"DELETED");
    
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}

- (void)documentSyncManagerDidDetermineThatClientHadPreviouslyBeenDeletedFromSynchronizingWithDocument:(TICDSDocumentSyncManager *)aSyncManager
{
    [self setDownloadStoreAfterRegistering:YES];
    
    NSLog(@"DELETED CLIENT");
}

- (BOOL)documentSyncManagerShouldUploadWholeStoreAfterDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager
{
    return ![self shouldDownloadStoreAfterRegistering];
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager 
willReplaceStoreWithDownloadedStoreAtURL:(NSURL *)aStoreURL
{
    NSError *anyError = nil;
    BOOL success = [[self persistentStoreCoordinator] 
                    removePersistentStore:
                    [[self persistentStoreCoordinator] 
                     persistentStoreForURL:aStoreURL] 
                    error:&anyError];
    
    if( !success ) {
        NSLog(@"Failed to remove persistent store at %@: %@", 
              aStoreURL, anyError);
    }
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager 
didReplaceStoreWithDownloadedStoreAtURL:(NSURL *)aStoreURL
{
    NSError *anyError = nil;
    id store = [[self persistentStoreCoordinator]
                addPersistentStoreWithType:NSSQLiteStoreType 
                configuration:nil 
                URL:aStoreURL options:nil error:&anyError];
    
    if( !store ) {
        NSLog(@"Failed to add persistent store at %@: %@", 
              aStoreURL, anyError);
    }
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager
didMakeChangesToObjectsInBackgroundContextAndSaveWithNotification:
(NSNotification *)aNotification
{
    [[self managedObjectContext] 
     mergeChangesFromContextDidSaveNotification:aNotification];
}

- (BOOL)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager
shouldBeginSynchronizingAfterManagedObjectContextDidSave:
(TICDSSynchronizedManagedObjectContext *)aMoc
{
    return YES;
}

- (BOOL)documentSyncManagerShouldVacuumUnneededRemoteFilesAfterDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager
{
    return YES;
}

- (void)documentSyncManagerDidFinishRegistering:
(TICDSDocumentSyncManager *)aSyncManager
{
    if( [self shouldDownloadStoreAfterRegistering] ) {
        [[self documentSyncManager] initiateDownloadOfWholeStore];
    }
    
    if( ![aSyncManager isKindOfClass:
          [TICDSFileManagerBasedDocumentSyncManager class]] ) {
        return;
    }
    
    [(TICDSFileManagerBasedDocumentSyncManager *)aSyncManager 
     enableAutomaticSynchronizationAfterChangesDetectedFromOtherClients];
    
    //[self performSelector:@selector(getPreviouslySynchronizedClients) withObject:nil afterDelay:2.0];
    //[self performSelector:@selector(deleteDocument) withObject:nil afterDelay:2.0];
    //[self performSelector:@selector(deleteClient) withObject:nil afterDelay:2.0];
}

- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFinishFetchingInformationForAllRegisteredDevices:(NSDictionary *)information
{
    NSLog(@"App client info: %@", information);
}

- (void)getPreviouslySynchronizedClients
{
    [[[self documentSyncManager] applicationSyncManager] requestListOfSynchronizedClientsIncludingDocuments:YES];
}

- (void)deleteDocument
{
    [[[self documentSyncManager] applicationSyncManager] deleteDocumentWithIdentifier:@"Notebook"];
}

- (void)deleteClient
{
    [[self documentSyncManager] deleteDocumentSynchronizationDataForClientWithIdentifier:@"97F95326-E1B1-4AD0-82C5-261AA3D9E87D-460-000000D7A0C79BC9"];
}

#pragma mark -
#pragma mark Notifications
- (void)activityDidIncrease:(NSNotification *)aNotification
{
    _activity++;
    
    if( _activity > 0 ) {
        [[self activityIndicator] setHidden:NO];
        [[self activityIndicator] startAnimation:self];
    }
}

- (void)activityDidDecrease:(NSNotification *)aNotification
{
    if( _activity > 0) {
        _activity--;
    }
    
    if( _activity < 1 ) {
        [[self activityIndicator] stopAnimation:self];
        [[self activityIndicator] setHidden:YES];
    }
}

#pragma mark -
#pragma mark Actions
- (IBAction)beginSynchronizing:(id)sender
{
    [[self documentSyncManager] initiateSynchronization];
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
    [_documentSyncManager release], _documentSyncManager = nil;
    
    [__managedObjectContext release];
    [__persistentStoreCoordinator release];
    [__managedObjectModel release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize window = _window;
@synthesize notesArrayController = _notesArrayController;
@synthesize existingStore = _existingStore;
@synthesize documentSyncManager = _documentSyncManager;
@synthesize downloadStoreAfterRegistering = 
_downloadStoreAfterRegistering;
@synthesize activityIndicator = _activityIndicator;

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
    
    if( ![[NSFileManager defaultManager] fileExistsAtPath:[url path]] ) {
        [self setDownloadStoreAfterRegistering:YES];
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
- (NSManagedObjectContext *) managedObjectContext {
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
    __managedObjectContext = [[TICDSSynchronizedManagedObjectContext alloc] init];
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
