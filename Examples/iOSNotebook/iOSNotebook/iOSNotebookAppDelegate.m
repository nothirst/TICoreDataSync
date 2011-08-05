//
//  iOSNotebookAppDelegate.m
//  iOSNotebook
//
//  Created by Tim Isted on 13/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "iOSNotebookAppDelegate.h"
#import "RootViewController.h"
#import "TICoreDataSync.h"
#import "DropboxSettings.h"
#import "DropboxSDK.h"

@interface iOSNotebookAppDelegate () <DBSessionDelegate, DBLoginControllerDelegate, TICDSApplicationSyncManagerDelegate, TICDSDocumentSyncManagerDelegate>
- (void)registerSyncManager;
@end

@implementation iOSNotebookAppDelegate

#pragma mark -
#pragma mark Initial Sync Registration
- (void)registerSyncManager
{
    [TICDSLog setVerbosity:TICDSLogVerbosityEveryStep];
    
    TICDSDropboxSDKBasedApplicationSyncManager *manager = [TICDSDropboxSDKBasedApplicationSyncManager defaultApplicationSyncManager];
    
    NSString *clientUuid = [[NSUserDefaults standardUserDefaults] stringForKey:@"iOSNotebookAppSyncClientUUID"];
    
    if( !clientUuid ) {
        clientUuid = [TICDSUtilities uuidString];
        [[NSUserDefaults standardUserDefaults] setValue:clientUuid forKey:@"iOSNotebookAppSyncClientUUID"];
    }
    
    NSString *deviceDescription = [[UIDevice currentDevice] name];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidIncrease:) name:TICDSApplicationSyncManagerDidIncreaseActivityNotification object:manager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidDecrease:) name:TICDSApplicationSyncManagerDidDecreaseActivityNotification object:manager];
    
    [manager registerWithDelegate:self
              globalAppIdentifier:@"com.timisted.notebook" 
           uniqueClientIdentifier:clientUuid 
                      description:deviceDescription 
                         userInfo:nil];
}

#pragma mark -
#pragma mark Synchronization
- (IBAction)beginSynchronizing:(id)sender
{
    [[self documentSyncManager] initiateSynchronization];
}

- (void)activityDidIncrease:(NSNotification *)aNotification
{
    _activity++;
    
    if( _activity > 0 ) {
        [[UIApplication sharedApplication] 
         setNetworkActivityIndicatorVisible:YES];
    }
}

- (void)activityDidDecrease:(NSNotification *)aNotification
{
    if( _activity > 0) {
        _activity--;
    }
    
    if( _activity < 1 ) {
        [[UIApplication sharedApplication] 
         setNetworkActivityIndicatorVisible:NO];
    }
}

#pragma mark -
#pragma mark Application Sync Manager Delegate
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
    /* Return nil because this is a non-document based app and this method will never be called.
    
       If you implement multiple documents, you'll need to return a configured (but not yet registered) sync manager.
       See the documentation for details, specifically:
       http://timisted.github.com/TICoreDataSync/reference/html/Protocols/TICDSApplicationSyncManagerDelegate.html#//api/name/applicationSyncManager:preConfiguredDocumentSyncManagerForDownloadedDocumentWithIdentifier:atURL:
    */
    
    return nil;
}

- (void)applicationSyncManagerDidFinishRegistering:(TICDSApplicationSyncManager *)aSyncManager
{
    TICDSDropboxSDKBasedDocumentSyncManager *docSyncManager = [[TICDSDropboxSDKBasedDocumentSyncManager alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidIncrease:) name:TICDSDocumentSyncManagerDidIncreaseActivityNotification object:docSyncManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidDecrease:) name:TICDSDocumentSyncManagerDidDecreaseActivityNotification object:docSyncManager];
    
    [docSyncManager registerWithDelegate:self 
                          appSyncManager:aSyncManager 
                    managedObjectContext:
     (TICDSSynchronizedManagedObjectContext *)
                                         [self managedObjectContext]
                      documentIdentifier:@"Notebook" 
                             description:@"Application's data" 
                                userInfo:nil];
    [self setDocumentSyncManager:docSyncManager];
    [docSyncManager release];
}

#pragma mark -
#pragma mark Document Sync Manager Delegate
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseSynchronizationAwaitingResolutionOfSyncConflict:(id)aConflict
{
    [aSyncManager continueSynchronizationByResolvingConflictWithResolutionType:TICDSSyncConflictResolutionTypeLocalWins];
}

- (NSURL *)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager URLForWholeStoreToUploadForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo
{
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Notebook.sqlite"];
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo
{
    [self setDownloadStoreAfterRegistering:NO];
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseRegistrationAsRemoteFileStructureWasDeletedForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo
{
    [self setDownloadStoreAfterRegistering:NO];
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}

- (void)documentSyncManagerDidDetermineThatClientHadPreviouslyBeenDeletedFromSynchronizingWithDocument:(TICDSDocumentSyncManager *)aSyncManager
{
    NSLog(@"DOC WAS DELETED");
    [self setDownloadStoreAfterRegistering:YES];
}

- (void)documentSyncManagerDidFinishRegistering:(TICDSDocumentSyncManager *)aSyncManager
{
    if( [self shouldDownloadStoreAfterRegistering] ) {
        [[self documentSyncManager] initiateDownloadOfWholeStore];
    }
    
    //[self performSelector:@selector(removeAllRemoteSyncData) withObject:nil afterDelay:8.0];
    //[self performSelector:@selector(getPreviouslySynchronizedClients) withObject:nil afterDelay:8.0];
    //[self performSelector:@selector(deleteClient) withObject:nil afterDelay:8.0];
}

- (void)removeAllRemoteSyncData
{
    [[[self documentSyncManager] applicationSyncManager] removeAllSyncDataFromRemote];
}

- (void)getPreviouslySynchronizedClients
{
    [[[self documentSyncManager] applicationSyncManager] requestListOfSynchronizedClientsIncludingDocuments:YES];
}

- (void)deleteClient
{
    [[self documentSyncManager] deleteDocumentSynchronizationDataForClientWithIdentifier:@"B29A21AB-529A-4CBB-A603-332CAD8F2D33-715-000001314CB7EE5B"];
}

- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFinishFetchingInformationForAllRegisteredDevices:(NSDictionary *)information
{
    NSLog(@"App client info: %@", information);
}

- (BOOL)documentSyncManagerShouldUploadWholeStoreAfterDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager
{
    return ![self shouldDownloadStoreAfterRegistering];
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager willReplaceStoreWithDownloadedStoreAtURL:(NSURL *)aStoreURL
{
    NSError *anyError = nil;
    BOOL success = [[self persistentStoreCoordinator] removePersistentStore:[[self persistentStoreCoordinator] persistentStoreForURL:aStoreURL] error:&anyError];
    
    if( !success ) {
        NSLog(@"Failed to remove persistent store at %@: %@", 
              aStoreURL, anyError);
    }
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didReplaceStoreWithDownloadedStoreAtURL:(NSURL *)aStoreURL
{
    NSError *anyError = nil;
    id store = [[self persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:aStoreURL options:nil error:&anyError];
    
    if( !store ) {
        NSLog(@"Failed to add persistent store at %@: %@", aStoreURL, anyError);
    }
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didMakeChangesToObjectsInBackgroundContextAndSaveWithNotification:(NSNotification *)aNotification
{
    [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:aNotification];
}

#pragma mark -
#pragma mark Application Lifecycle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    DBSession *session = 
    [[DBSession alloc] initWithConsumerKey:kTICDDropboxSyncKey consumerSecret:kTICDDropboxSyncSecret];
    [session setDelegate:self];
    [DBSession setSharedSession:session];
    [session release];
    
    if( [session isLinked] ) {
        [self registerSyncManager];
    } else {
        DBLoginController *loginController = [[DBLoginController alloc] init];
        [loginController setDelegate:self];
        [[self navigationController] pushViewController:loginController animated:NO];
        [loginController release];
    }
    
    [[self window] setRootViewController:[self navigationController]];
    [[self window] makeKeyAndVisible];
    return YES;
}

#pragma mark -
#pragma mark DBSession Delegate
- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session
{
    DBLoginController *loginController = [[DBLoginController alloc] init];
    [loginController setDelegate:self];
    
    [[self navigationController] pushViewController:loginController animated:YES];
    [loginController release];
}

- (void)loginControllerDidLogin:(DBLoginController *)controller
{
    [[self navigationController] popViewControllerAnimated:YES];
    
    [self registerSyncManager];
}

- (void)loginControllerDidCancel:(DBLoginController *)controller
{
    [[self navigationController] popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Properties
@synthesize window=_window;
@synthesize managedObjectContext=__managedObjectContext;
@synthesize managedObjectModel=__managedObjectModel;
@synthesize persistentStoreCoordinator=__persistentStoreCoordinator;
@synthesize navigationController=_navigationController;
@synthesize documentSyncManager = _documentSyncManager;
@synthesize downloadStoreAfterRegistering = _downloadStoreAfterRegistering;

#pragma mark -
#pragma mark Apple Stuff
- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)dealloc
{
    [_window release];
    [__managedObjectContext release];
    [__managedObjectModel release];
    [__persistentStoreCoordinator release];
    [_navigationController release];
    [_documentSyncManager release], _documentSyncManager = nil;
    
    [super dealloc];
}

- (void)awakeFromNib
{
    RootViewController *rootViewController = (RootViewController *)[self.navigationController topViewController];
    rootViewController.managedObjectContext = self.managedObjectContext;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
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

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[TICDSSynchronizedManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Notebook" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Notebook.sqlite"];
    
    if( ![[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]] ) {
        [self setDownloadStoreAfterRegistering:YES];
    }
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
