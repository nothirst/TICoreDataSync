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
- (void)beginCheckWhetherDocumentWasDeleted;
- (void)beginRequestWhetherToCreateRemoteDocumentFileStructure;
- (void)continueAfterRequestWhetherToCreateRemoteDocumentFileStructure;
- (void)beginCreatingRemoteDocumentDirectoryStructure;
- (void)beginCreatingDocumentInfoPlist;
- (void)beginGeneratingAndSavingIntegrityKey;
- (void)beginFetchingListOfIdentifiersOfAllRegisteredClientsForThisApplication;
- (void)beginAddingClientIdentifiersToDocumentDeletedClientsDirectory:(NSArray *)identifiers;
- (void)beginDeletingDocumentPlistInDeletedDocumentsDirectory;
- (void)beginCheckForClientDirectoryInDocumentSyncChangesDirectory;
- (void)beginCheckWhetherRemoteIntegrityKeyMatchesLocalKey;
- (void)beginCheckWhetherClientWasDeletedFromRemoteDocument;
- (void)sendMessageToDelegateThatToDeleteLocalFilesAndPullDownStore;
- (void)warnDelegateToDeleteLocalFilesAndPullDownStoreBecauseOfDeletion:(BOOL)clientWasDeleted;
- (void)beginDeletingClientIdentifierFileFromDeletedClientsDirectory;
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
            
            [self beginCheckWhetherDocumentWasDeleted];
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
- (void)beginCheckWhetherDocumentWasDeleted
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
    
    @autoreleasepool {
        [self setPaused:YES];
        
        TICDSLog(TICDSLogVerbosityEveryStep, @"Pausing registration as remote document file structure doesn't exist");
        if ([self ti_delegateRespondsToSelector:@selector(registrationOperationPausedToFindOutWhetherToCreateRemoteDocumentStructure:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [(id)self.delegate registrationOperationPausedToFindOutWhetherToCreateRemoteDocumentStructure:self];
            });
        }
        
        while( [self isPaused] && ![self isCancelled] ) {
            [NSThread sleepForTimeInterval:0.2];
        }
        
        TICDSLog(TICDSLogVerbosityEveryStep, @"Continuing registration after instruction from delegate");
        
        if ([self ti_delegateRespondsToSelector:@selector(registrationOperationResumedFollowingDocumentStructureCreationInstruction:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [(id)self.delegate registrationOperationResumedFollowingDocumentStructureCreationInstruction:self];
            });
        }

    }
    [self continueAfterRequestWhetherToCreateRemoteDocumentFileStructure];
}

- (void)continueAfterRequestWhetherToCreateRemoteDocumentFileStructure
{
    if( [self needsMainThread] && ![NSThread isMainThread] ) {
        [self performSelectorOnMainThread:@selector(continueAfterRequestWhetherToCreateRemoteDocumentFileStructure) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if( [self isCancelled] ) {
        [self operationWasCancelled];
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
    
    [self beginGeneratingAndSavingIntegrityKey];
}

#pragma mark Overridden Method
- (void)saveRemoteDocumentInfoPlistFromDictionary:(NSDictionary *)aDictionary
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self savedRemoteDocumentInfoPlistWithSuccess:NO];
}

#pragma mark - Generating and Saving Integrity Key
- (void)beginGeneratingAndSavingIntegrityKey
{
    NSString *integrityKey = [TICDSUtilities uuidString];
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Saving Integrity Key: %@", integrityKey);
    
    [self setIntegrityKey:integrityKey];
    [self saveIntegrityKey:integrityKey];
}

- (void)savedIntegrityKeyWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save integrity key file");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Saved integrity key file successfully");
    
    if( [self documentWasDeleted] ) {
        [self beginFetchingListOfIdentifiersOfAllRegisteredClientsForThisApplication];
    } else {
        [self beginCreatingClientDirectoriesInRemoteDocumentDirectories];
    }
}

#pragma mark Overridden Method
- (void)saveIntegrityKey:(NSString *)aKey
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self savedIntegrityKeyWithSuccess:NO];
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
    
    if( _numberOfDeletedClientIdentifiersAdded == _numberOfDeletedClientIdentifiersToAdd ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Finished adding client identifiers to the DeletedClients directory for this document.");
        [self beginDeletingDocumentPlistInDeletedDocumentsDirectory];
    } else if( _numberOfDeletedClientIdentifiersAdded + _numberOfDeletedClientIdentifiersThatFailedToBeAdded == _numberOfDeletedClientIdentifiersToAdd ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"One or more client identifiers failed to be added to the the DeletedClients directory for this document.");
        [self operationDidFailToComplete];
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
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client's directory exists");
            [self setClientHasPreviouslySynchronizedThisDocument:YES];
            
            [self beginCheckWhetherRemoteIntegrityKeyMatchesLocalKey];
            return;

        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client's directory does not exist");
            
            
            
            [self beginCheckWhetherClientWasDeletedFromRemoteDocument];
            break;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherClientDirectoryExistsInRemoteDocumentSyncChangesDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Check Whether Integrity Keys Match
- (void)beginCheckWhetherRemoteIntegrityKeyMatchesLocalKey
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Fetching remote integrity key");
    
    [self fetchRemoteIntegrityKey];
}

- (void)fetchedRemoteIntegrityKey:(NSString *)aKey
{
    if( !aKey ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch an integrity key");
        [self operationDidFailToComplete];
        return;
    }
    
    if( ![self integrityKey] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Setting local integrity key");
        [self setIntegrityKey:aKey];
        
        if( [self clientHasPreviouslySynchronizedThisDocument] ) {
            [self operationDidCompleteSuccessfully];
        } else {
            [self beginCreatingClientDirectoriesInRemoteDocumentDirectories];
        }
        return;
    }
    
    if( ![[self integrityKey] isEqualToString:aKey] ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Integrity keys do not match");
        
        [self warnDelegateToDeleteLocalFilesAndPullDownStoreBecauseOfDeletion:NO];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Integrity keys match, so document registration complete");
    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Method
- (void)fetchRemoteIntegrityKey
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedRemoteIntegrityKey:nil];
}

#pragma mark - Checking Whether Client was Deleted from Document
- (void)beginCheckWhetherClientWasDeletedFromRemoteDocument
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking whether this client has previously been deleted from synchronizing with this document");
    
    [self checkWhetherClientWasDeletedFromRemoteDocument];
}

- (void)discoveredDeletionStatusOfClient:(TICDSRemoteFileStructureDeletionResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureDeletionResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking whether client was deleted from remote document");
            [self operationDidFailToComplete];
            return;
            
        case TICDSRemoteFileStructureDeletionResponseTypeDeleted:
            [self warnDelegateToDeleteLocalFilesAndPullDownStoreBecauseOfDeletion:YES];
            return;
            
        case TICDSRemoteFileStructureDeletionResponseTypeNotDeleted:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client wasn't deleted");
            [self beginCheckWhetherRemoteIntegrityKeyMatchesLocalKey];
            return;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherClientWasDeletedFromRemoteDocument
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredDeletionStatusOfClient:TICDSRemoteFileStructureDeletionResponseTypeError];
}

#pragma mark - Warning that Client had been Deleted
- (void)sendMessageToDelegateThatToDeleteLocalFilesAndPullDownStore
{
    if ([self ti_delegateRespondsToSelector:@selector(registrationOperationDidDetermineThatClientHadPreviouslyBeenDeletedFromSynchronizingWithDocument:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate registrationOperationDidDetermineThatClientHadPreviouslyBeenDeletedFromSynchronizingWithDocument:self];
        }];
    }
}

- (void)warnDelegateToDeleteLocalFilesAndPullDownStoreBecauseOfDeletion:(BOOL)clientWasDeleted
{
    [self sendMessageToDelegateThatToDeleteLocalFilesAndPullDownStore];
    
    if( clientWasDeleted ) {
        [self beginDeletingClientIdentifierFileFromDeletedClientsDirectory];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Delegate warned that integrity didn't match");
        
        [self setIntegrityKey:nil];
        [self beginCheckWhetherRemoteIntegrityKeyMatchesLocalKey];
    }
}

#pragma mark - Deleting Client's File in Document's RecentSync Directory
- (void)beginDeletingClientIdentifierFileFromDeletedClientsDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Deleting client's file from document's DeletedClients directory");
    
    [self deleteClientIdentifierFileFromDeletedClientsDirectory];
}

- (void)deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete client's file from document's DeletedClients directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Deleted client's file from document's DeletedClients directory");
    [self setIntegrityKey:nil];
    [self beginCheckWhetherRemoteIntegrityKeyMatchesLocalKey];
}

#pragma mark Overridden Method
- (void)deleteClientIdentifierFileFromDeletedClientsDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:NO];
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

#pragma mark - Initialization and Deallocation
- (id)initWithDelegate:(NSObject<TICDSDocumentRegistrationOperationDelegate> *)aDelegate
{
    return [super initWithDelegate:aDelegate];
}

- (void)dealloc
{
    _documentIdentifier = nil;
    _documentDescription = nil;
    _clientDescription = nil;
    _documentUserInfo = nil;
    _integrityKey = nil;

}

#pragma mark - Properties
@synthesize paused = _paused;
@synthesize documentWasDeleted = _documentWasDeleted;
@synthesize shouldCreateDocumentFileStructure = _shouldCreateDocumentFileStructure;
@synthesize clientHasPreviouslySynchronizedThisDocument = _clientHasPreviouslySynchronizedThisDocument;
@synthesize documentIdentifier = _documentIdentifier;
@synthesize documentDescription = _documentDescription;
@synthesize clientDescription = _clientDescription;
@synthesize documentUserInfo = _documentUserInfo;
@synthesize integrityKey = _integrityKey;

@end
