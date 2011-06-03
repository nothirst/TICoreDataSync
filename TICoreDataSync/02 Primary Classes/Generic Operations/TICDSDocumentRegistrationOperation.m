//
//  TICDSDocumentRegistrationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSDocumentRegistrationOperation () 

- (void)beginCheckForRemoteDocumentDirectory;
- (void)beginCheckingWhetherDocumentWasDeleted;
- (void)beginRequestWhetherToCreateRemoteDocumentFileStructure;
- (void)continueAfterRequestWhetherToCreateRemoteDocumentFileStructure;
- (void)beginCreatingRemoteDocumentDirectoryStructure;
- (void)beginCreatingDocumentInfoPlist;
- (void)beginFetchingListOfIdentifiersOfAllRegisteredClientsForThisApplication;
- (void)beginAddingClientIdentifiersToDocumentDeletedClientsDirectory:(NSArray *)identifiers;
- (void)beginDeletingDocumentPlistInDeletedDocumentsDirectory;
- (void)beginCheckForClientDirectoryInDocumentSyncChangesDirectory;
- (void)beginCreatingClientDirectoriesInRemoteDocumentDirectories;

@end


@implementation TICDSDocumentRegistrationOperation

- (void)main
{
    [self beginCheckForRemoteDocumentDirectory];
}

#pragma mark - Checking for Document Directory
- (void)beginCheckForRemoteDocumentDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Checking whether the remote document directory exists");
    
    [self checkWhetherRemoteDocumentDirectoryExists];
}

- (void)discoveredStatusOfRemoteDocumentDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking for document directory");
            [self operationDidFailToComplete];
            return;
        
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Document directory exists");
            
            [self beginCheckForClientDirectoryInDocumentSyncChangesDirectory];
            break;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Document directory does not exist, so checking whether it was deleted");
            
            [self beginCheckingWhetherDocumentWasDeleted];
            break;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherRemoteDocumentDirectoryExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfRemoteDocumentDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Checking Whether Document was Deleted
- (void)beginCheckingWhetherDocumentWasDeleted
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Checking whether document was deleted");
    
    [self checkWhetherRemoteDocumentWasDeleted];
}

- (void)discoveredDeletionStatusOfRemoteDocument:(TICDSRemoteFileStructureDeletionResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureDeletionResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking whether document was deleted");
            [self operationDidFailToComplete];
            return;
            
        case TICDSRemoteFileStructureDeletionResponseTypeNotDeleted:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Document wasn't deleted");
            [self setDocumentWasDeleted:NO];
            
            [self beginRequestWhetherToCreateRemoteDocumentFileStructure];
            return;
            
        case TICDSRemoteFileStructureDeletionResponseTypeDeleted:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Document was previously deleted");
            [self setDocumentWasDeleted:YES];
            
            [self beginRequestWhetherToCreateRemoteDocumentFileStructure];
            return;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherRemoteDocumentWasDeleted
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredDeletionStatusOfRemoteDocument:TICDSRemoteFileStructureDeletionResponseTypeError];
}

#pragma mark - Asking Whether to Create Remote Hierarchy
- (void)beginRequestWhetherToCreateRemoteDocumentFileStructure
{
    if( [NSThread isMainThread] ) {
        [self performSelectorInBackground:@selector(beginRequestWhetherToCreateRemoteDocumentFileStructure) withObject:nil];
        return;
    }
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self setPaused:YES];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Pausing registration as remote document file structure doesn't exist");
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationPausedToFindOutWhetherToCreateRemoteDocumentStructure:) waitUntilDone:NO];
    
    while( [self isPaused] ) {
        sleep(0.2);
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Continuing registration after instruction from delegate");
    
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationResumedFollowingDocumentStructureCreationInstruction:) waitUntilDone:NO];
    
    [pool release];
    [self continueAfterRequestWhetherToCreateRemoteDocumentFileStructure];
}

- (void)continueAfterRequestWhetherToCreateRemoteDocumentFileStructure
{
    if( [self needsMainThread] && ![NSThread isMainThread] ) {
        [self performSelectorOnMainThread:@selector(continueAfterRequestWhetherToCreateRemoteDocumentFileStructure) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if( [self shouldCreateDocumentFileStructure] ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating remote document file structure");
        
        [self beginCreatingRemoteDocumentDirectoryStructure];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Cancelling document registration");
        [self operationWasCancelled];
    }
}

#pragma mark - Creating Document Directory
- (void)beginCreatingRemoteDocumentDirectoryStructure
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating remote document directory structure");
    [self createRemoteDocumentDirectoryStructure];
}

- (void)createdRemoteDocumentDirectoryStructureWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create remote document directory structure");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Created remote document directory structure");
    
    [self beginCreatingDocumentInfoPlist];
}

#pragma mark Overridden Method
- (void)createRemoteDocumentDirectoryStructure
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdRemoteDocumentDirectoryStructureWithSuccess:NO];
}

#pragma mark - Creating documentInfo.plist
- (void)beginCreatingDocumentInfoPlist
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating remote documentInfo.plist file");
    
    NSString *pathToFile = [[NSBundle bundleForClass:[self class]] pathForResource:TICDSDocumentInfoPlistFilename ofType:TICDSDocumentInfoPlistExtension];
    
    NSMutableDictionary *documentInfo = [NSMutableDictionary dictionaryWithContentsOfFile:pathToFile];
    
    [documentInfo setValue:[self documentIdentifier] forKey:kTICDSDocumentIdentifier];
    [documentInfo setValue:[self documentDescription] forKey:kTICDSDocumentDescription];
    [documentInfo setValue:[self documentUserInfo] forKey:kTICDSDocumentUserInfo];
    [documentInfo setValue:[self clientIdentifier] forKey:kTICDSOriginalDeviceIdentifier];
    [documentInfo setValue:[self clientDescription] forKey:kTICDSOriginalDeviceDescription];
    
    [self saveRemoteDocumentInfoPlistFromDictionary:documentInfo];
}

- (void)savedRemoteDocumentInfoPlistWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save documentInfo.plist file");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Saved documentInfo.plist file successfully");
    
    if( [self documentWasDeleted] ) {
        [self beginFetchingListOfIdentifiersOfAllRegisteredClientsForThisApplication];
    } else {
        [self beginCreatingClientDirectoriesInRemoteDocumentDirectories];
    }
}

#pragma mark Overridden Method
- (void)saveRemoteDocumentInfoPlistFromDictionary:(NSDictionary *)aDictionary
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self savedRemoteDocumentInfoPlistWithSuccess:NO];
}

#pragma mark - Fetching All Client Identifiers for the Application
- (void)beginFetchingListOfIdentifiersOfAllRegisteredClientsForThisApplication
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Fetching a list of identifiers of all clients registered for this application");
    
    [self fetchListOfIdentifiersOfAllRegisteredClientsForThisApplication];
}

- (void)fetchedListOfIdentifiersOfAllRegisteredClientsForThisApplication:(NSArray *)anArray
{
    if( !anArray ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch a list of client identifiers for the application");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched a list of client identifiers");
    
    NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:[anArray count]];
    for( NSString *eachIdentifier in anArray ) {
        if( [eachIdentifier isEqualToString:[self clientIdentifier]] ) {
            continue;
        }
        
        [identifiers addObject:eachIdentifier];
    }
    
    if( [identifiers count] < 1 ) {
        [self beginDeletingDocumentPlistInDeletedDocumentsDirectory];
    } else {
        [self beginAddingClientIdentifiersToDocumentDeletedClientsDirectory:identifiers];
    }
}

#pragma mark Overridden Method
- (void)fetchListOfIdentifiersOfAllRegisteredClientsForThisApplication
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedListOfIdentifiersOfAllRegisteredClientsForThisApplication:nil];
}

#pragma mark - Adding Client Identifiers to Document's DeletedClients Directory
- (void)beginAddingClientIdentifiersToDocumentDeletedClientsDirectory:(NSArray *)identifiers
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Adding other client identifiers to DeletedClients directory for this document");
    _numberOfDeletedClientIdentifiersToAdd = [identifiers count];
    
    for( NSString *eachIdentifier in identifiers ) {
        [self addDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:eachIdentifier];
    }
}

- (void)addedDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:(NSString *)anIdentifier withSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to add %@ client's identifier to the deleted documents directory", anIdentifier);
        _numberOfDeletedClientIdentifiersThatFailedToBeAdded++;
    } else {
        _numberOfDeletedClientIdentifiersAdded++;
    }
    
    if( _numberOfDeletedClientIdentifiersAdded + _numberOfDeletedClientIdentifiersThatFailedToBeAdded == _numberOfDeletedClientIdentifiersToAdd ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"One or more client identifiers failed to be added to the the DeletedClients directory for this document.");
        [self operationDidFailToComplete];
    } else if( _numberOfDeletedClientIdentifiersAdded == _numberOfDeletedClientIdentifiersToAdd ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Finished adding client identifiers to the DeletedClients directory for this document.");
        [self beginDeletingDocumentPlistInDeletedDocumentsDirectory];
    }
}

#pragma mark Overridden Method
- (void)addDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:(NSString *)anIdentifier
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self addedDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:anIdentifier withSuccess:NO];
}

#pragma mark - Removing the identifier.plist File in DeletedDocuments
- (void)beginDeletingDocumentPlistInDeletedDocumentsDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Deleting document's identifier.plist file from the DeletedDocuments directory");
    
    [self deleteDocumentInfoPlistFromDeletedDocumentsDirectory];
}

- (void)deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete document's identifier.plist file from DeletedDocuments directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Deleted document's identifier.plist file from DeletedDocuments directory");
    [self beginCreatingClientDirectoriesInRemoteDocumentDirectories];
}

#pragma mark Overridden Method
- (void)deleteDocumentInfoPlistFromDeletedDocumentsDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:NO];
}

#pragma mark - Checking for Client Directories in Document Directory
- (void)beginCheckForClientDirectoryInDocumentSyncChangesDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Checking for client's directory inside the document's SyncChanges directory");
    
    [self checkWhetherClientDirectoryExistsInRemoteDocumentSyncChangesDirectory];
}

- (void)discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking for status of client's directory");
            [self operationDidFailToComplete];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client's directory exists, so document registration is complete");
            
            [self operationDidCompleteSuccessfully];
            return;

        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client's directory does not exist");
            
            [self beginCreatingClientDirectoriesInRemoteDocumentDirectories];
            break;
    }
}

#pragma mark Overridden Methods
- (void)checkWhetherClientDirectoryExistsInRemoteDocumentSyncChangesDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Creating Client Directories
- (void)beginCreatingClientDirectoriesInRemoteDocumentDirectories
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating client's directories inside the document's SyncChanges and SyncCommands directories");
    
    [self createClientDirectoriesInRemoteDocumentDirectories];
}

- (void)createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error creating client's directories");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Created client's directories, so registration is complete");
    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Method
- (void)createClientDirectoriesInRemoteDocumentDirectories
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:NO];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)initWithDelegate:(NSObject<TICDSDocumentRegistrationOperationDelegate> *)aDelegate
{
    return [super initWithDelegate:aDelegate];
}

- (void)dealloc
{
    [_documentIdentifier release], _documentIdentifier = nil;
    [_documentDescription release], _documentDescription = nil;
    [_clientDescription release], _clientDescription = nil;
    [_documentUserInfo release], _documentUserInfo = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize paused = _paused;
@synthesize documentWasDeleted = _documentWasDeleted;
@synthesize shouldCreateDocumentFileStructure = _shouldCreateDocumentFileStructure;
@synthesize documentIdentifier = _documentIdentifier;
@synthesize documentDescription = _documentDescription;
@synthesize clientDescription = _clientDescription;
@synthesize documentUserInfo = _documentUserInfo;

@end
