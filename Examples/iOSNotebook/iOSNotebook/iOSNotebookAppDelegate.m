//
//  iOSNotebookAppDelegate.m
//  iOSNotebook
//
//  Created by Tim Isted on 13/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "iOSNotebookAppDelegate.h"
#import "RootViewController.h"
#import "DropboxSDK.h"

#define kTICDDropboxSyncKey @"fqv4grvh4a1u885"
#define kTICDDropboxSyncSecret @"x7yo7k9bnrus87z"

@interface iOSNotebookAppDelegate () <DBSessionDelegate, TICDSApplicationSyncManagerDelegate, TICDSDocumentSyncManagerDelegate>
@end

@implementation iOSNotebookAppDelegate

+ (void)initialize
{
    [TICDSLog setVerbosity:TICDSLogVerbosityEveryStep];
}

#pragma mark - Application Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidIncrease:) name:TICDSApplicationSyncManagerDidIncreaseActivityNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidDecrease:) name:TICDSApplicationSyncManagerDidDecreaseActivityNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidIncrease:) name:TICDSDocumentSyncManagerDidIncreaseActivityNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidDecrease:) name:TICDSDocumentSyncManagerDidDecreaseActivityNotification object:nil];

    [[self window] setRootViewController:[self navigationController]];
    [[self window] makeKeyAndVisible];

    DBSession *session = [[DBSession alloc] initWithAppKey:kTICDDropboxSyncKey appSecret:kTICDDropboxSyncSecret root:kDBRootDropbox];
    session.delegate = self;
    [DBSession setSharedSession:session];
    [session release];

    if ([[DBSession sharedSession] isLinked]) {
        [self registerSyncManager];
    } else {
        [[DBSession sharedSession] linkFromController:self.navigationController];
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            [self registerSyncManager];
        }

        return YES;
    }

    return NO;
}

#pragma mark - Local methods

- (void)registerSyncManager
{
    TICDSDropboxSDKBasedApplicationSyncManager *manager = [TICDSDropboxSDKBasedApplicationSyncManager defaultApplicationSyncManager];

    NSString *clientUuid = [[NSUserDefaults standardUserDefaults] stringForKey:@"iOSNotebookAppSyncClientUUID"];
    if (clientUuid == nil) {
        clientUuid = [TICDSUtilities uuidString];
        [[NSUserDefaults standardUserDefaults] setValue:clientUuid forKey:@"iOSNotebookAppSyncClientUUID"];
    }

    NSString *deviceDescription = [[UIDevice currentDevice] name];

    [manager registerWithDelegate:self
              globalAppIdentifier:@"com.yourcompany.notebook"
           uniqueClientIdentifier:clientUuid
                      description:deviceDescription
                         userInfo:nil];
}

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

#pragma mark - Sync Manager Activity Notification methods

- (void)activityDidIncrease:(NSNotification *)aNotification
{
    self.activity++;

    if (self.activity > 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

- (void)activityDidDecrease:(NSNotification *)aNotification
{
    if (self.activity > 0) {
        self.activity--;
    }

    if (self.activity < 1) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
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

    TICDSDropboxSDKBasedDocumentSyncManager *docSyncManager = [[TICDSDropboxSDKBasedDocumentSyncManager alloc] init];

    [docSyncManager registerWithDelegate:self
                          appSyncManager:aSyncManager
                    managedObjectContext:[self managedObjectContext]
                      documentIdentifier:@"Notebook"
                             description:@"Application's data"
                                userInfo:nil];

    [self setDocumentSyncManager:docSyncManager];
    [docSyncManager release];
}

#pragma mark - TICDSDocumentSyncManagerDelegate methods

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

- (BOOL)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager shouldBeginSynchronizingAfterManagedObjectContextDidSave:(NSManagedObjectContext *)aMoc;
{
    return YES;
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didMakeChangesToObjectsInBackgroundContextAndSaveWithNotification:(NSNotification *)aNotification
{
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
    if (saveError != nil) {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, saveError);
    }
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFailToSynchronizeWithError:(NSError *)anError
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, anError);
}

#pragma mark - DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId
{
    [[DBSession sharedSession] linkFromController:self.navigationController];
}

#pragma mark -
#pragma mark Properties
@synthesize window=_window;
@synthesize managedObjectContext=__managedObjectContext;
@synthesize managedObjectModel=__managedObjectModel;
@synthesize persistentStoreCoordinator=__persistentStoreCoordinator;
@synthesize navigationController=_navigationController;

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
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
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
    
    /* Add the check for an existing store here... */
    if ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path] == NO) {
        self.downloadStoreAfterRegistering = YES;
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
