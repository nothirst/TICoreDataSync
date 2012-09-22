//
//  TICDSDocumentSyncManager.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSDocumentSyncManager () <TICoreDataFactoryDelegate>

- (BOOL)startDocumentConfigurationProcess:(NSError **)outError;
- (BOOL)startDocumentRegistrationProcess:(NSError **)outError;
- (void)bailFromRegistrationProcessWithError:(NSError *)anError;
- (BOOL)checkForHelperFileDirectoryOrCreateIfNecessary:(NSError **)outError;

- (void)startWholeStoreUploadProcess;
- (void)bailFromUploadProcessWithError:(NSError *)anError;

- (void)startSynchronizationProcess;
- (void)bailFromSynchronizationProcessWithError:(NSError *)anError;
- (void)moveUnsynchronizedSyncChangesToMergeLocation;

- (void)startVacuumProcess;
- (void)bailFromVacuumProcessWithError:(NSError *)anError;

- (void)startWholeStoreDownloadProcess;
- (void)bailFromDownloadProcessWithError:(NSError *)anError;

- (NSManagedObjectContext *)addSyncChangesMocForDocumentMoc:(TICDSSynchronizedManagedObjectContext *)aContext;
- (NSString *)keyForContext:(NSManagedObjectContext *)aContext;

- (void)startRegisteredDevicesInformationProcess;
- (void)bailFromRegisteredDevicesInformationProcessWithError:(NSError *)anError;

- (void)startClientDeletionProcessForClient:(NSString *)anIdentifier;
- (void)bailFromClientDeletionProcessForClient:(NSString *)anIdentifier withError:(NSError *)anError;

@property (nonatomic, strong) NSString *documentIdentifier;
@property (nonatomic, strong) NSString *documentDescription;
@property (nonatomic, strong) NSString *clientIdentifier;
@property (nonatomic, strong) NSDictionary *documentUserInfo;
@property (strong) NSURL *helperFileDirectoryLocation;

@end

@implementation TICDSDocumentSyncManager

#pragma mark -
#pragma mark ACTIVITY
- (void)postIncreaseActivityNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TICDSDocumentSyncManagerDidIncreaseActivityNotification object:self];
}

- (void)postDecreaseActivityNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TICDSDocumentSyncManagerDidDecreaseActivityNotification object:self];
}

#pragma mark -
#pragma mark DELAYED REGISTRATION
- (void)configureWithDelegate:(id <TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager managedObjectContext:(TICDSSynchronizedManagedObjectContext *)aContext documentIdentifier:(NSString *)aDocumentIdentifier description:(NSString *)aDocumentDescription userInfo:(NSDictionary *)someUserInfo
{
    [self preConfigureWithDelegate:aDelegate appSyncManager:anAppSyncManager documentIdentifier:aDocumentIdentifier];
    
    [self setPrimaryDocumentMOC:aContext];
    [aContext setDocumentSyncManager:self];
    
    // setup the syncChangesMOC
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating SyncChangesMOC");
    
    [self addSyncChangesMocForDocumentMoc:[self primaryDocumentMOC]];
    if( ![self syncChangesMocForDocumentMoc:[self primaryDocumentMOC]] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create sync changes MOC");
        [self bailFromRegistrationProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFailedToCreateSyncChangesMOC classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    TICDSLog(TICDSLogVerbosityEveryStep, @"Finished creating SyncChangesMOC");
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Registration Information:\n   Delegate: %@,\n   App Sync Manager: %@,\n   Document ID: %@,\n   Description: %@,\n   User Info: %@", aDelegate, anAppSyncManager, aDocumentIdentifier, aDocumentDescription, someUserInfo);
    [self setApplicationSyncManager:anAppSyncManager];
    [self setDocumentDescription:aDocumentDescription];
    NSString *userDefaultsIntegrityKey = [TICDSUtilities userDefaultsKeyForIntegrityKeyForDocumentWithIdentifier:aDocumentIdentifier];
    NSString *integrityKey = [[NSUserDefaults standardUserDefaults] valueForKey:userDefaultsIntegrityKey];
    [self setIntegrityKey:integrityKey];
    [self setClientIdentifier:[anAppSyncManager clientIdentifier]];
    [self setDocumentUserInfo:someUserInfo];
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Document sync manager configured for future registration");
}

- (void)registerConfiguredDocumentSyncManager
{
    if( [self state] != TICDSDocumentSyncManagerStateConfigured ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Can't register this document sync manager because it wasn't configured");
        [self bailFromRegistrationProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeUnableToRegisterUnconfiguredSyncManager classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[self applicationSyncManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationSyncManagerWillRemoveAllRemoteSyncData:) name:TICDSApplicationSyncManagerWillRemoveAllSyncDataNotification object:[self applicationSyncManager]];
    
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidBeginRegistering:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidBeginRegistering:self];
        });
    }
    
    if( [[self applicationSyncManager] state] == TICDSApplicationSyncManagerStateAbleToSync ) {
        [[self registrationQueue] setSuspended:NO];
    } else { 
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appSyncManagerDidRegister:) name:TICDSApplicationSyncManagerDidFinishRegisteringNotification object:[self applicationSyncManager]];
    }
    
    NSError *anyError = nil;
    BOOL shouldContinue = [self startDocumentRegistrationProcess:&anyError];
    if( !shouldContinue ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error registering: %@", anyError);
        [self bailFromRegistrationProcessWithError:anyError];
        return;
    }
}

#pragma mark -
#pragma mark PRECONFIGURATION
- (void)preConfigureWithDelegate:(id <TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager documentIdentifier:(NSString *)aDocumentIdentifier
{
    [self setDelegate:aDelegate];
    [self setDocumentIdentifier:aDocumentIdentifier];
    [self setShouldUseEncryption:[anAppSyncManager shouldUseEncryption]];
    
    [self postIncreaseActivityNotification];
    
    NSError *anyError = nil;
    BOOL success = [self startDocumentConfigurationProcess:&anyError];
    
    if( !success ) {
        if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToRegisterWithError:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [(id)self.delegate documentSyncManager:self didFailToRegisterWithError:anyError];
            });
        }
    }
    
    [self postDecreaseActivityNotification];
}

- (BOOL)startDocumentConfigurationProcess:(NSError **)outError
{
    // get the location of the helper file directory from the delegate, or create default location if necessary
    BOOL shouldContinue = [self checkForHelperFileDirectoryOrCreateIfNecessary:outError];
    
    if( !shouldContinue ) {
        return NO;
    }
    
    [self setState:TICDSDocumentSyncManagerStateConfigured];
    
    return YES;
}

#pragma mark Helper File Directory
- (NSString *)applicationSupportDirectory
{    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]];
}

- (NSURL *)defaultHelperFileLocation
{
    NSString *location = [[self applicationSupportDirectory] stringByAppendingPathComponent:TICDSDocumentsDirectoryName];
    location = [location stringByAppendingPathComponent:[self documentIdentifier]];
    
    return [NSURL fileURLWithPath:location];
}

- (BOOL)createHelperFileDirectoryFileStructure:(NSError **)outError
{
    NSError *anyError = nil;
    
    NSString *unappliedSyncChangesPath = [[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:TICDSUnappliedSyncChangesDirectoryName];
    BOOL success = YES;
    
    if( ![[self fileManager] fileExistsAtPath:unappliedSyncChangesPath] ) {
        success = [[self fileManager] createDirectoryAtPath:unappliedSyncChangesPath withIntermediateDirectories:YES attributes:nil error:&anyError];
    }
    
    NSString *unappliedSyncCommandsPath = [[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:TICDSUnappliedSyncCommandsDirectoryName];
    if( success && ![[self fileManager] fileExistsAtPath:unappliedSyncCommandsPath] ) {
        success = [[self fileManager] createDirectoryAtPath:unappliedSyncCommandsPath withIntermediateDirectories:YES attributes:nil error:&anyError];
    }
    
    if( !success ) {
        if( outError ) {
            *outError = [TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)checkForHelperFileDirectoryOrCreateIfNecessary:(NSError **)outError
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Asking delegate for location of helper file directory");
    NSURL *finalURL = [self ti_objectFromDelegateWithSelector:@selector(documentSyncManager:helperFileDirectoryURLForDocumentWithIdentifier:description:userInfo:), [self documentIdentifier], [self documentDescription], [self documentUserInfo]];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Checking that delegate-provided helper file directory exists");
    
    if( finalURL && ![[self fileManager] fileExistsAtPath:[finalURL path]] ) {
        [self setState:TICDSDocumentSyncManagerStateUnableToSyncBecauseDelegateProvidedHelperFileDirectoryDoesNotExist];
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Delegate-provided helper file directory does not exist");
        
        if( outError ) {
            *outError = [TICDSError errorWithCode:TICDSErrorCodeHelperFileDirectoryDoesNotExist classAndMethod:__PRETTY_FUNCTION__];
        }
        return NO;
    }
    
    if( finalURL ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Delegate-provided helper file directory");
        
        [self setHelperFileDirectoryLocation:finalURL];
        return [self createHelperFileDirectoryFileStructure:outError];
    }
    
    // delegate did not provide a location for the helper files
    TICDSLog(TICDSLogVerbosityEveryStep, @"Delegate did not provide a location for helper files, so checking default location");
    
    [self setHelperFileDirectoryLocation:[self defaultHelperFileLocation]];
    if( [[self fileManager] fileExistsAtPath:[[self defaultHelperFileLocation] path]] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Default helper file location exists, so using it");
        return [self createHelperFileDirectoryFileStructure:outError];
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Default helper file location does not exist, so creating it");
    NSError *anyError = nil;
    BOOL success = [[self fileManager] createDirectoryAtPath:[[self helperFileDirectoryLocation] path] withIntermediateDirectories:YES attributes:nil error:&anyError];
    if( !success ) {
        [self setState:TICDSDocumentSyncManagerStateFailedToCreateDefaultHelperFileDirectory];
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create default helper file directory: %@", anyError);
        
        if( outError ) {
            *outError = [TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__];
        }
        return NO;
    }
    
    success = [self createHelperFileDirectoryFileStructure:outError];
    if( !success ) {
        return NO;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Created default helper file directory");
    
    return YES;
}

#pragma mark -
#pragma mark ONE-SHOT REGISTRATION
- (void)registerWithDelegate:(id <TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager managedObjectContext:(TICDSSynchronizedManagedObjectContext *)aContext documentIdentifier:(NSString *)aDocumentIdentifier description:(NSString *)aDocumentDescription userInfo:(NSDictionary *)someUserInfo
{
    // configure the document, if necessary
    NSError *anyError;
    BOOL shouldContinue = YES;
    
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidBeginRegistering:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidBeginRegistering:self];
        });
    }
    
    [self setDelegate:aDelegate];
    [self setDocumentIdentifier:aDocumentIdentifier];
    [self setShouldUseEncryption:[anAppSyncManager shouldUseEncryption]];
    NSString *userDefaultsIntegrityKey = [TICDSUtilities userDefaultsKeyForIntegrityKeyForDocumentWithIdentifier:aDocumentIdentifier];
    NSString *integrityKey = [[NSUserDefaults standardUserDefaults] valueForKey:userDefaultsIntegrityKey];
    [self setIntegrityKey:integrityKey];
    
    if( [self state] != TICDSApplicationSyncManagerStateConfigured ) {
        shouldContinue = [self startDocumentConfigurationProcess:&anyError];
    }
    
    if( !shouldContinue ) {
        [self bailFromRegistrationProcessWithError:anyError];
        return;
    }
    
    [self setState:TICDSDocumentSyncManagerStateRegistering];
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting to register document sync manager");
    
    [self setPrimaryDocumentMOC:aContext];
    [aContext setDocumentSyncManager:self];
    
    // setup the syncChangesMOC
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating SyncChangesMOC");
    
    [self addSyncChangesMocForDocumentMoc:[self primaryDocumentMOC]];
    if( ![self syncChangesMocForDocumentMoc:[self primaryDocumentMOC]] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create sync changes MOC");
        [self bailFromRegistrationProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFailedToCreateSyncChangesMOC classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    TICDSLog(TICDSLogVerbosityEveryStep, @"Finished creating SyncChangesMOC");
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Registration Information:\n   Delegate: %@,\n   App Sync Manager: %@,\n   Document ID: %@,\n   Description: %@,\n   User Info: %@", aDelegate, anAppSyncManager, aDocumentIdentifier, aDocumentDescription, someUserInfo);
    [self setApplicationSyncManager:anAppSyncManager];
    [self setDocumentDescription:aDocumentDescription];
    [self setClientIdentifier:[anAppSyncManager clientIdentifier]];
    [self setDocumentUserInfo:someUserInfo];
    
    if( [anAppSyncManager state] == TICDSApplicationSyncManagerStateAbleToSync ) {
        [[self registrationQueue] setSuspended:NO];
    } else { 
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appSyncManagerDidRegister:) name:TICDSApplicationSyncManagerDidFinishRegisteringNotification object:anAppSyncManager];
    }
    
    shouldContinue = [self startDocumentRegistrationProcess:&anyError];
    if( !shouldContinue ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error registering: %@", anyError);
        [self bailFromRegistrationProcessWithError:anyError];
        return;
    }
}

- (void)bailFromRegistrationProcessWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from registration process");
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToRegisterWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToRegisterWithError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

- (BOOL)startDocumentRegistrationProcess:(NSError **)outError
{
    TICDSDocumentRegistrationOperation *operation = [self documentRegistrationOperation];
    
    if( !operation ) {
        if( outError ) {
            *outError = [TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__];
        }
        
        return NO;
    }
    
    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    [operation setDocumentIdentifier:[self documentIdentifier]];
    [operation setIntegrityKey:[self integrityKey]];
    [operation setClientIdentifier:[self clientIdentifier]];
    [operation setClientDescription:[[self applicationSyncManager] clientDescription]];
    [operation setDocumentDescription:[self documentDescription]];
    [operation setDocumentUserInfo:[self documentUserInfo]];
    
    [[self registrationQueue] addOperation:operation];
    
    return YES;
}

#pragma mark Helper File Directory Deletion and Recreation
- (void)removeExistingHelperFileDirectory
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Removing existing helper file directory");
    
    NSError *anyError = nil;
    if( [[self fileManager] fileExistsAtPath:[[self helperFileDirectoryLocation] path]] && ![[self fileManager] removeItemAtPath:[[self helperFileDirectoryLocation] path] error:&anyError] ) {
        
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete existing local helper files for this document, but not absolutely catastrophic, so continuing. Error: %@", anyError);
    }
}

- (void)removeThenRecreateExistingHelperFileDirectory
{
    [self removeExistingHelperFileDirectory];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Recreating document helper file directory");
    NSError *anyError = nil;
    if( ![self createHelperFileDirectoryFileStructure:&anyError] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to recreate helper file directory structure for this document, but probably related to a previous error so continuing. Error: %@", anyError);
    }
}

#pragma mark Asking if Should Create Remote Document File Structure
- (void)registrationOperationPausedToFindOutWhetherToCreateRemoteDocumentStructure:(TICDSDocumentRegistrationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Registration operation paused to find out whether to create document structure");
    
    if( [anOperation documentWasDeleted] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Document was deleted, so deleting local helper files for this document");
        [self removeThenRecreateExistingHelperFileDirectory];
        if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didPauseRegistrationAsRemoteFileStructureWasDeletedForDocumentWithIdentifier:description:userInfo:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [(id)self.delegate documentSyncManager:self didPauseRegistrationAsRemoteFileStructureWasDeletedForDocumentWithIdentifier:[self documentIdentifier] description:[self documentDescription] userInfo:[self documentUserInfo]];
            });
        }
    } else {
        if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:description:userInfo:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [(id)self.delegate documentSyncManager:self didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:[self documentIdentifier] description:[self documentDescription] userInfo:[self documentUserInfo]];
            });
        }
    }
    
    [self postDecreaseActivityNotification];
}

- (void)registrationOperationResumedFollowingDocumentStructureCreationInstruction:(TICDSDocumentRegistrationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Registration operation resumed after finding out whether to create document structure");
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidContinueRegistering:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidContinueRegistering:self];
        });
    }
    [self postIncreaseActivityNotification];
}


- (void)continueRegistrationByCreatingRemoteFileStructure:(BOOL)shouldCreateFileStructure
{
    // Just start the registration operation again
    [(TICDSDocumentRegistrationOperation *)[[[self registrationQueue] operations] lastObject] setShouldCreateDocumentFileStructure:shouldCreateFileStructure];
    [(TICDSDocumentRegistrationOperation *)[[[self registrationQueue] operations] lastObject] setPaused:NO];
    
    [self setMustUploadStoreAfterRegistration:YES];
}

#pragma mark Alerting Delegate that Client Was Deleted From Document
- (void)registrationOperationDidDetermineThatClientHadPreviouslyBeenDeletedFromSynchronizingWithDocument:(TICDSDocumentRegistrationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Document was deleted, so deleting local helper files for this document");
    [self removeThenRecreateExistingHelperFileDirectory];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Alerting delegate that client was deleted from synchronizing document");
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidDetermineThatClientHadPreviouslyBeenDeletedFromSynchronizingWithDocument:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidDetermineThatClientHadPreviouslyBeenDeletedFromSynchronizingWithDocument:self];
        });
    }
}

#pragma mark Operation Generation
- (TICDSDocumentRegistrationOperation *)documentRegistrationOperation
{
    return SAFE_ARC_AUTORELEASE([[TICDSDocumentRegistrationOperation alloc] initWithDelegate:self]);
}

#pragma mark Operation Communications
- (void)documentRegistrationOperationCompleted:(TICDSDocumentRegistrationOperation *)anOperation
{
    // Primary Registration Complete from Operation
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Document Registration Operation Completed");
    
    [self setState:TICDSDocumentSyncManagerStateAbleToSync];
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Finished registering document sync manager");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TICDSDocumentSyncManagerDidRegisterSuccessfullyNotification object:self];
    
    // Set integrity key for delegate to store
    [self setIntegrityKey:[anOperation integrityKey]];
    
    NSString *userDefaultsIntegrityKey = [TICDSUtilities userDefaultsKeyForIntegrityKeyForDocumentWithIdentifier:[self documentIdentifier]];
    [[NSUserDefaults standardUserDefaults] setValue:[self integrityKey] forKey:userDefaultsIntegrityKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Registration Complete
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidFinishRegistering:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidFinishRegistering:self];
        });
    }
    [self postDecreaseActivityNotification];
    
    // Upload whole store if necessary
    TICDSLog(TICDSLogVerbosityEveryStep, @"Checking whether to upload whole store after registration");
    if( [self mustUploadStoreAfterRegistration] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Must upload store because this is the first time this document has been registered");
        [self startWholeStoreUploadProcess];
    } else if( [self ti_delegateRespondsToSelector:@selector(documentSyncManagerShouldUploadWholeStoreAfterDocumentRegistration:)] && [(id)self.delegate documentSyncManagerShouldUploadWholeStoreAfterDocumentRegistration:self] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Delegate allowed whole store upload after registration");
        [self startWholeStoreUploadProcess];
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Delegate denied whole store upload after registration");
    }
    
    [self setShouldUseEncryption:[[self applicationSyncManager] shouldUseEncryption]];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Resuming Operation Queues");
    for( TICDSOperation *eachOperation in [[self otherTasksQueue] operations] ) {
        [eachOperation setShouldUseEncryption:[self shouldUseEncryption]];
    }
    
    for( TICDSOperation *eachOperation in [[self synchronizationQueue] operations] ) {
        [eachOperation setShouldUseEncryption:[self shouldUseEncryption]];
    }
    
    [[self otherTasksQueue] setSuspended:NO];
    
    if( ![self mustUploadStoreAfterRegistration] ) {
        // Don't resume sync queue until after store was uploaded
        [[self synchronizationQueue] setSuspended:NO];
    } else {
        // Don't offer to clean-up if document was just created on remote
        return;
    }
    
    // Perform clean-up if necessary
    TICDSLog(TICDSLogVerbosityEveryStep, @"Asking delegate whether to vacuum unneeded files after registration");
    if( [self ti_delegateRespondsToSelector:@selector(documentSyncManagerShouldVacuumUnneededRemoteFilesAfterDocumentRegistration:)] && [(id)self.delegate documentSyncManagerShouldVacuumUnneededRemoteFilesAfterDocumentRegistration:self] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Delegate allowed vacuum after registration");
        [self startVacuumProcess];
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Delegate denied vacuum after registration");
    }
}

- (void)documentRegistrationOperationWasCancelled:(TICDSDocumentRegistrationOperation *)anOperation
{
    [self setState:TICDSDocumentSyncManagerStateConfigured];
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Document Registration Operation was Cancelled");
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToRegisterWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToRegisterWithError:[TICDSError errorWithCode:TICDSErrorCodeTaskWasCancelled classAndMethod:__PRETTY_FUNCTION__]];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)documentRegistrationOperation:(TICDSDocumentRegistrationOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    [self setState:TICDSDocumentSyncManagerStateNotYetRegistered];
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Document Registration Operation Failed to Complete with Error: %@", anError);
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToRegisterWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToRegisterWithError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

#pragma mark -
#pragma mark WHOLE STORE UPLOAD
- (void)initiateUploadOfWholeStore
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Manual initiation of whole store upload");
    
    [self startWholeStoreUploadProcess];
}

- (void)bailFromUploadProcessWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from whole store upload process");
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToUploadWholeStoreWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToUploadWholeStoreWithError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)startWholeStoreUploadProcess
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting whole store upload process");
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidBeginUploadingWholeStore:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidBeginUploadingWholeStore:self];
        });
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Checking to see if there are unsynchronized SyncChanges");
    NSError *anyError = nil;
    NSUInteger count = [TICDSSyncChange ti_numberOfObjectsInManagedObjectContext:[self syncChangesMocForDocumentMoc:[self primaryDocumentMOC]] error:&anyError];
    if( anyError ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to count number of SyncChange objects: %@", anyError);
        [self bailFromUploadProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataFetchError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    if( count > 0 ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"There are unsynchronized local Sync Changes so cannot upload whole store");
        [self bailFromUploadProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeWholeStoreCannotBeUploadedWhileThereAreUnsynchronizedSyncChanges classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Asking delegate for URL of whole store to upload");
    NSURL *storeURL = [self ti_objectFromDelegateWithSelector:@selector(documentSyncManager:URLForWholeStoreToUploadForDocumentWithIdentifier:description:userInfo:), [self documentIdentifier], [self documentDescription], [self documentUserInfo]];
    
    if( !storeURL || ![[self fileManager] fileExistsAtPath:[storeURL path]] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Store does not exist at provided path");
        [self bailFromUploadProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeUnexpectedOrIncompleteFileLocationOrDirectoryStructure classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    TICDSWholeStoreUploadOperation *operation = [self wholeStoreUploadOperation];
    
    if( !operation ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create whole store operation object");
        [self bailFromUploadProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    [operation setLocalWholeStoreFileLocation:storeURL];
    
    [operation configureBackgroundApplicationContextForPersistentStoreCoordinator:[[self primaryDocumentMOC] persistentStoreCoordinator]];
    
    NSString *appliedSyncChangeSetsFilePath = [[self helperFileDirectoryLocation] path];
    appliedSyncChangeSetsFilePath = [appliedSyncChangeSetsFilePath stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename];
    
    [operation setLocalAppliedSyncChangeSetsFileLocation:[NSURL fileURLWithPath:appliedSyncChangeSetsFilePath]];
    
    [[self otherTasksQueue] addOperation:operation];
}

#pragma mark Operation Generation
- (TICDSWholeStoreUploadOperation *)wholeStoreUploadOperation
{
    return SAFE_ARC_AUTORELEASE([[TICDSWholeStoreUploadOperation alloc] initWithDelegate:self]);
}

#pragma mark Operation Communications
- (void)wholeStoreUploadOperationCompleted:(TICDSWholeStoreUploadOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Whole Store Upload Operation Completed");
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidFinishUploadingWholeStore:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidFinishUploadingWholeStore:self];
        });
    }
    [self postDecreaseActivityNotification];
    
    // Unsuspend the sync queue in the case that this was a required upload for a newly-registered document
    if( [self mustUploadStoreAfterRegistration] ) {
        [[self synchronizationQueue] setSuspended:NO];
    }
}

- (void)wholeStoreUploadOperationWasCancelled:(TICDSWholeStoreUploadOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Whole Store Upload Operation was Cancelled");
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToUploadWholeStoreWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToUploadWholeStoreWithError:[TICDSError errorWithCode:TICDSErrorCodeTaskWasCancelled classAndMethod:__PRETTY_FUNCTION__]];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)wholeStoreUploadOperation:(TICDSDocumentRegistrationOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Whole Store Upload Operation Failed to Complete with Error: %@", anError);
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToUploadWholeStoreWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToUploadWholeStoreWithError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

#pragma mark -
#pragma mark WHOLE STORE DOWNLOAD
- (void)initiateDownloadOfWholeStore
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Manual initiation of whole store download");
    [self startWholeStoreDownloadProcess];
}

- (void)bailFromDownloadProcessWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from whole store download process");
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToDownloadWholeStoreWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToDownloadWholeStoreWithError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)bailFromDownloadPostProcessingWithFileManagerError:(NSError *)anError
{
    [self bailFromDownloadProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anError classAndMethod:__PRETTY_FUNCTION__]];
    [self postDecreaseActivityNotification];
}

- (void)startWholeStoreDownloadProcess
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting to download whole store");
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidBeginDownloadingWholeStore:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidBeginDownloadingWholeStore:self];
        });
    }
    
    // Set download to go to a temporary location
    NSString *temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:TICDSFrameworkName];
    temporaryPath = [temporaryPath stringByAppendingPathComponent:[self documentIdentifier]];
    
    NSError *anyError = nil;
    BOOL success = [[self fileManager] createDirectoryAtPath:temporaryPath withIntermediateDirectories:YES attributes:nil error:&anyError];
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create temporary directory for whole store download: %@", anyError);
        
        [self bailFromDownloadProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    TICDSWholeStoreDownloadOperation *operation = [self wholeStoreDownloadOperation];
    
    if( !operation ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create whole store download operation");
        [self bailFromDownloadProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    
    NSString *wholeStoreFilePath = [temporaryPath stringByAppendingPathComponent:TICDSWholeStoreFilename];
    NSString *appliedSyncChangesFilePath = [temporaryPath stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename];
    
    [operation setLocalWholeStoreFileLocation:[NSURL fileURLWithPath:wholeStoreFilePath]];
    [operation setLocalAppliedSyncChangeSetsFileLocation:[NSURL fileURLWithPath:appliedSyncChangesFilePath]];
    
    [operation setClientIdentifier:[self clientIdentifier]];
    
    [[self otherTasksQueue] addOperation:operation];
}

#pragma mark Operation Generation
- (TICDSWholeStoreDownloadOperation *)wholeStoreDownloadOperation
{
    return SAFE_ARC_AUTORELEASE([[TICDSWholeStoreDownloadOperation alloc] initWithDelegate:self]);
}

#pragma mark Operation Communications
- (void)wholeStoreDownloadOperationCompleted:(TICDSWholeStoreDownloadOperation *)anOperation
{
    NSError *anyError = nil;
    BOOL success = YES;
    
    NSURL *finalWholeStoreLocation = [self ti_objectFromDelegateWithSelector:@selector(documentSyncManagerURLForDownloadedStore:)];
    
    if( !finalWholeStoreLocation ) {
        NSPersistentStoreCoordinator *psc = [[self primaryDocumentMOC] persistentStoreCoordinator];
        
        finalWholeStoreLocation = [psc URLForPersistentStore:[[psc persistentStores] lastObject]];
    }
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:willReplaceStoreWithDownloadedStoreAtURL:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self willReplaceStoreWithDownloadedStoreAtURL:finalWholeStoreLocation];
        });
    }
    
    // Remove old WholeStore
    if( [[self fileManager] fileExistsAtPath:[finalWholeStoreLocation path]] && ![[self fileManager] removeItemAtPath:[finalWholeStoreLocation path] error:&anyError] ) {
        [self bailFromDownloadPostProcessingWithFileManagerError:anyError];
        return;
    }
    
    // Move downloaded WholeStore
    success = [[self fileManager] moveItemAtPath:[[anOperation localWholeStoreFileLocation] path] toPath:[finalWholeStoreLocation path] error:&anyError];
    if( !success ) {
        [self bailFromDownloadPostProcessingWithFileManagerError:anyError];
        return;
    }
    
    // Remove old AppliedSyncChanges
    if( [[self fileManager] fileExistsAtPath:[self localAppliedSyncChangesFilePath]] && ![[self fileManager] removeItemAtPath:[self localAppliedSyncChangesFilePath] error:&anyError] ) {
        [self bailFromDownloadPostProcessingWithFileManagerError:anyError];
        return;
    }
    
    // Move newly downloaded AppliedSyncChanges
    if( [[self fileManager] fileExistsAtPath:[[anOperation localAppliedSyncChangeSetsFileLocation] path]] && ![[self fileManager] moveItemAtPath:[[anOperation localAppliedSyncChangeSetsFileLocation] path] toPath:[self localAppliedSyncChangesFilePath] error:&anyError] ) {
        [self bailFromDownloadPostProcessingWithFileManagerError:anyError];
        return;
    }
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didReplaceStoreWithDownloadedStoreAtURL:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didReplaceStoreWithDownloadedStoreAtURL:finalWholeStoreLocation];
        });
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Updating local integrity key to match newly-downloaded store");
    [self setIntegrityKey:[anOperation integrityKey]];
    NSString *userDefaultsIntegrityKey = [TICDSUtilities userDefaultsKeyForIntegrityKeyForDocumentWithIdentifier:[self documentIdentifier]];
    [[NSUserDefaults standardUserDefaults] setValue:[self integrityKey] forKey:userDefaultsIntegrityKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Whole Store Download complete");
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidFinishDownloadingWholeStore:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidFinishDownloadingWholeStore:self];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)wholeStoreDownloadOperationWasCancelled:(TICDSWholeStoreDownloadOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Whole Store Download operation was cancelled");
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToDownloadWholeStoreWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToDownloadWholeStoreWithError:[TICDSError errorWithCode:TICDSErrorCodeTaskWasCancelled classAndMethod:__PRETTY_FUNCTION__]];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)wholeStoreDownloadOperation:(TICDSWholeStoreDownloadOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Whole Store Download operation failed to complete with error: %@", anError);
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToDownloadWholeStoreWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToDownloadWholeStoreWithError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

#pragma mark -
#pragma mark SYNCHRONIZATION
- (void)initiateSynchronization
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Manual initiation of synchronization");
    
    [self startSynchronizationProcess];
}

- (void)bailFromSynchronizationProcessWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from synchronization process");
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToSynchronizeWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToSynchronizeWithError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)startSynchronizationProcess
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting synchronization process");
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidBeginSynchronizing:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidBeginSynchronizing:self];
        });
    }
    
    [self moveUnsynchronizedSyncChangesToMergeLocation];
    
    TICDSSynchronizationOperation *operation = [self synchronizationOperation];
    
    if( !operation ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create synchronization operation object");
        [self bailFromSynchronizationProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    [operation setClientIdentifier:[self clientIdentifier]];
    [operation setIntegrityKey:[self integrityKey]];
    // Set location of sync changes to merge file
    NSURL *syncChangesToMergeLocation = nil;
    if( [[self fileManager] fileExistsAtPath:[self syncChangesBeingSynchronizedStorePath]] ) {
        syncChangesToMergeLocation = [NSURL fileURLWithPath:[self syncChangesBeingSynchronizedStorePath]];
    }
    [operation setLocalSyncChangesToMergeLocation:syncChangesToMergeLocation];
    
    // Set locations of files
    [operation setAppliedSyncChangeSetsFileLocation:[NSURL fileURLWithPath:[[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename]]];
    [operation setUnappliedSyncChangesDirectoryLocation:[NSURL fileURLWithPath:[[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:TICDSUnappliedSyncChangesDirectoryName]]];
    [operation setUnappliedSyncChangeSetsFileLocation:[NSURL fileURLWithPath:[[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:TICDSUnappliedChangeSetsFilename]]];
    [operation setLocalRecentSyncFileLocation:[NSURL fileURLWithPath:[[[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:[self clientIdentifier]] stringByAppendingPathExtension:TICDSRecentSyncFileExtension]]];
    
    // Set background context
    [operation configureBackgroundApplicationContextForPersistentStoreCoordinator:[[self primaryDocumentMOC] persistentStoreCoordinator]];
    
    [[self synchronizationQueue] addOperation:operation];
}

- (void)moveUnsynchronizedSyncChangesToMergeLocation
{
    // check whether there's an existing set of sync changes to merge left over from a previous error
    if( [[self fileManager] fileExistsAtPath:[self syncChangesBeingSynchronizedStorePath]] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"A SyncChangesBeingSynchronized.syncchg file already exists from a previous failed sync, so using it for this synchronization process. The most recent local sync changes won't be synchronized.");
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Checking if there are local sync changes to merge and push");
    NSError *anyError = nil;
    NSArray *syncChanges = [TICDSSyncChange ti_allObjectsInManagedObjectContext:[self syncChangesMocForDocumentMoc:[self primaryDocumentMOC]] error:&anyError];
    
    if( !syncChanges ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch local sync changes");
        [self bailFromSynchronizationProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataFetchError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    if( [syncChanges count] < 1 ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No local sync changes need to be pushed for this sync operation");
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Moving UnsynchronizedSyncChanges to SyncChangesBeingSynchronized");
    
    [self setCoreDataFactory:nil];
    [[self syncChangesMOCs] setValue:nil forKey:[self keyForContext:[self primaryDocumentMOC]]];
    
    // move UnsynchronizedSyncChanges file to SyncChangesBeingSynchronized
    BOOL success = [[self fileManager] moveItemAtPath:[self unsynchronizedSyncChangesStorePath] toPath:[self syncChangesBeingSynchronizedStorePath] error:&anyError];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to move UnsynchronizedSyncChanges.syncchg to SyncChangesBeingSynchronized.syncchg");
        [self bailFromSynchronizationProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    // setup the syncChangesMOC
    TICDSLog(TICDSLogVerbosityEveryStep, @"Re-Creating SyncChangesMOC");
    [self addSyncChangesMocForDocumentMoc:[self primaryDocumentMOC]];
    if( ![self syncChangesMocForDocumentMoc:[self primaryDocumentMOC]] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create sync changes MOC");
        [self bailFromSynchronizationProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFailedToCreateSyncChangesMOC classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    TICDSLog(TICDSLogVerbosityEveryStep, @"Finished creating SyncChangesMOC");
}

- (void)synchronizationOperation:(TICDSSynchronizationOperation *)anOperation processedChangeNumber:(NSNumber *)changeNumber outOfTotalChangeCount:(NSNumber *)totalChangeCount fromClientNamed:(NSString *)humanReadableClientName
{
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:processedChangeNumber:outOfTotalChangeCount:fromClientNamed:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self processedChangeNumber:changeNumber outOfTotalChangeCount:totalChangeCount fromClientNamed:humanReadableClientName];
        });
    }
}

#pragma mark Conflict Resolution
- (void)synchronizationOperation:(TICDSSynchronizationOperation *)anOperation pausedToDetermineResolutionOfConflict:(id)aConflict
{
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didPauseSynchronizationAwaitingResolutionOfSyncConflict:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didPauseSynchronizationAwaitingResolutionOfSyncConflict:aConflict];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)synchronizationOperationResumedFollowingResolutionOfConflict:(TICDSSynchronizationOperation *)anOperation
{
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidContinueSynchronizing:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidContinueSynchronizing:self];
        });
    }
    [self postIncreaseActivityNotification];
}

- (void)continueSynchronizationByResolvingConflictWithResolutionType:(TICDSSyncConflictResolutionType)aType
{
    TICDSSynchronizationOperation *operation = [[[self synchronizationQueue] operations] lastObject];
    
    [operation setMostRecentConflictResolutionType:aType];
    
    [operation setPaused:NO];
}

#pragma mark Operation Generation
- (TICDSSynchronizationOperation *)synchronizationOperation
{
    return SAFE_ARC_AUTORELEASE([[TICDSSynchronizationOperation alloc] initWithDelegate:self]);
}

#pragma mark Operation Communications
- (void)synchronizationOperationCompleted:(TICDSSynchronizationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Synchronization Operation Completed");
    
    if( [[anOperation synchronizationWarnings] count] > 0 ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Synchronization encountered warnings: \n%@", [anOperation synchronizationWarnings]);
        if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didEncounterWarningsWhileSynchronizing:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [(id)self.delegate documentSyncManager:self didEncounterWarningsWhileSynchronizing:[anOperation synchronizationWarnings]];
            });
        }
    }
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidFinishSynchronizing:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidFinishSynchronizing:self];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)synchronizationOperationWasCancelled:(TICDSSynchronizationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Synchronization Operation was Cancelled");
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToSynchronizeWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToSynchronizeWithError:[TICDSError errorWithCode:TICDSErrorCodeTaskWasCancelled classAndMethod:__PRETTY_FUNCTION__]];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)synchronizationOperation:(TICDSSynchronizationOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Synchronization Operation Failed to Complete with Error: %@", anError);
    
    if( [anError code] == TICDSErrorCodeSynchronizationFailedBecauseIntegrityKeysDoNotMatch ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Removing helper file directory because integrity keys do not match");
        [self removeThenRecreateExistingHelperFileDirectory];
    }
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToSynchronizeWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToSynchronizeWithError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

#pragma mark -
#pragma mark VACUUMING
- (void)initiateVacuumOfUnneededRemoteFiles
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Manual initiation of vacuum process");
    
    [self startVacuumProcess];
}

- (void)bailFromVacuumProcessWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from vacuum process");
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToVacuumUnneededRemoteFilesWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToVacuumUnneededRemoteFilesWithError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)startVacuumProcess
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting vacuum process to remove unneeded files from the remote");
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidBeginVacuumingUnneededRemoteFiles:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidBeginVacuumingUnneededRemoteFiles:self];
        });
    }
    
    TICDSVacuumOperation *operation = [self vacuumOperation];
    
    if( !operation ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create vacuum operation object");
        [self bailFromVacuumProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    
    [[self otherTasksQueue] addOperation:operation];
}

#pragma mark Operation Generation
- (TICDSVacuumOperation *)vacuumOperation
{
    return SAFE_ARC_AUTORELEASE([[TICDSVacuumOperation alloc] initWithDelegate:self]);
}

#pragma mark Operation Communications
- (void)vacuumOperationCompleted:(TICDSVacuumOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Vacuum Operation Completed");
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidFinishVacuumingUnneededRemoteFiles:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidFinishVacuumingUnneededRemoteFiles:self];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)vacuumOperationWasCancelled:(TICDSVacuumOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Vacuum Operation was Cancelled");
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToVacuumUnneededRemoteFilesWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToVacuumUnneededRemoteFilesWithError:[TICDSError errorWithCode:TICDSErrorCodeTaskWasCancelled classAndMethod:__PRETTY_FUNCTION__]];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)vacuumOperation:(TICDSVacuumOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Vacuum Operation Failed to Complete with Error: %@", anError);
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToVacuumUnneededRemoteFilesWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToVacuumUnneededRemoteFilesWithError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

#pragma mark -
#pragma mark REGISTERED CLIENT INFORMATION
- (void)requestInformationForAllRegisteredDevices
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Manual initiation of registered device information request");
    
    [self startRegisteredDevicesInformationProcess];
}

- (void)bailFromRegisteredDevicesInformationProcessWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from device information request");
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToFetchInformationForAllRegisteredDevicesWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToFetchInformationForAllRegisteredDevicesWithError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)startRegisteredDevicesInformationProcess
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting process to fetch information on all devices registered to synchronize this document");
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManagerDidBeginFetchingInformationForAllRegisteredDevices:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManagerDidBeginFetchingInformationForAllRegisteredDevices:self];
        });
    }
    
    TICDSListOfDocumentRegisteredClientsOperation *operation = [self listOfDocumentRegisteredClientsOperation];
    
    if( !operation ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create registered devices operation object");
        [self bailFromRegisteredDevicesInformationProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    
    [[self otherTasksQueue] addOperation:operation];
}

#pragma mark Operation Generation
- (TICDSListOfDocumentRegisteredClientsOperation *)listOfDocumentRegisteredClientsOperation
{
    return SAFE_ARC_AUTORELEASE([[TICDSListOfDocumentRegisteredClientsOperation alloc] initWithDelegate:self]);
}

#pragma mark Operation Communications
- (void)registeredClientsOperationCompleted:(TICDSListOfDocumentRegisteredClientsOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Registered Device Information Operation Completed");
    
    NSDictionary *information = [anOperation deviceInfoDictionaries];
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFinishFetchingInformationForAllRegisteredDevices:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFinishFetchingInformationForAllRegisteredDevices:information];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)registeredClientsOperationWasCancelled:(TICDSListOfDocumentRegisteredClientsOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Registered Device Information Operation was Cancelled");
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToFetchInformationForAllRegisteredDevicesWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToFetchInformationForAllRegisteredDevicesWithError:[TICDSError errorWithCode:TICDSErrorCodeTaskWasCancelled classAndMethod:__PRETTY_FUNCTION__]];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)registeredClientsOperation:(TICDSListOfDocumentRegisteredClientsOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Registered Device Information Operation Failed to Complete with Error: %@", anError);
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToFetchInformationForAllRegisteredDevicesWithError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToFetchInformationForAllRegisteredDevicesWithError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

#pragma mark -
#pragma mark DELETION OF CLIENT DATA FROM A DOCUMENT
- (void)deleteDocumentSynchronizationDataForClientWithIdentifier:(NSString *)anIdentifier
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Manual initiation of request to delete document synchronization data for client %@", anIdentifier);
    
    [self startClientDeletionProcessForClient:anIdentifier];
}

- (void)bailFromClientDeletionProcessForClient:(NSString *)anIdentifier withError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from client device deletion from document synchronization request");
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToDeleteSynchronizationDataFromDocumentForClientWithIdentifier:withError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToDeleteSynchronizationDataFromDocumentForClientWithIdentifier:anIdentifier withError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)startClientDeletionProcessForClient:(NSString *)anIdentifier
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting process to delete synchronization data from the document for client %@", anIdentifier);
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didBeginDeletingSynchronizationDataFromDocumentForClientWithIdentifier:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didBeginDeletingSynchronizationDataFromDocumentForClientWithIdentifier:anIdentifier];
        });
    }
    
    TICDSDocumentClientDeletionOperation *operation = [self documentClientDeletionOperation];
    
    if( !operation ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create document client deletion operation object");
        [self bailFromClientDeletionProcessForClient:anIdentifier withError:[TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    [operation setIdentifierOfClientToBeDeleted:anIdentifier];
    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    
    [[self otherTasksQueue] addOperation:operation];
}

#pragma mark Operation Generation
- (TICDSDocumentClientDeletionOperation *)documentClientDeletionOperation
{
    return SAFE_ARC_AUTORELEASE([[TICDSDocumentClientDeletionOperation alloc] initWithDelegate:self]);
}

#pragma mark Operation Communications
- (void)documentClientDeletionOperationCompleted:(TICDSDocumentClientDeletionOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Document Client Deletion Operation Completed");
    
    NSString *clientIdentifier = [anOperation identifierOfClientToBeDeleted];
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFinishDeletingSynchronizationDataFromDocumentForClientWithIdentifier:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFinishDeletingSynchronizationDataFromDocumentForClientWithIdentifier:clientIdentifier];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)documentClientDeletionOperationWasCancelled:(TICDSDocumentClientDeletionOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Document Client Deletion Operation was Cancelled");
    
    NSString *clientIdentifier = [anOperation identifierOfClientToBeDeleted];
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToDeleteSynchronizationDataFromDocumentForClientWithIdentifier:withError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToDeleteSynchronizationDataFromDocumentForClientWithIdentifier:clientIdentifier withError:[TICDSError errorWithCode:TICDSErrorCodeTaskWasCancelled classAndMethod:__PRETTY_FUNCTION__]];
        });
    }
    [self postDecreaseActivityNotification];
}

- (void)documentClientDeletionOperation:(TICDSDocumentClientDeletionOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Document Client Deletion Operation Failed to Complete with Error: %@", anError);
    NSString *clientIdentifier = [anOperation identifierOfClientToBeDeleted];
    
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToDeleteSynchronizationDataFromDocumentForClientWithIdentifier:withError:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFailToDeleteSynchronizationDataFromDocumentForClientWithIdentifier:clientIdentifier withError:anError];
        });
    }
    [self postDecreaseActivityNotification];
}

#pragma mark -
#pragma mark ADDITIONAL MANAGED OBJECT CONTEXTS
- (void)addManagedObjectContext:(TICDSSynchronizedManagedObjectContext *)aContext
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Adding SyncChanges MOC for document context: %@", aContext);
    [self addSyncChangesMocForDocumentMoc:aContext];
}

- (NSManagedObjectContext *)addSyncChangesMocForDocumentMoc:(TICDSSynchronizedManagedObjectContext *)aContext
{
    NSManagedObjectContext *context = [[self syncChangesMOCs] valueForKey:[self keyForContext:aContext]];
    
    if( context ) {
        return context;
    }
    
    [aContext setDocumentSyncManager:self];
    
    context = [[NSManagedObjectContext alloc] init];
    [context setPersistentStoreCoordinator:[[self coreDataFactory] persistentStoreCoordinator]];
    [[self syncChangesMOCs] setValue:context forKey:[self keyForContext:aContext]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncChangesMocDidSave:) name:NSManagedObjectContextDidSaveNotification object:context];
    
    return SAFE_ARC_AUTORELEASE(context);
}

- (NSManagedObjectContext *)syncChangesMocForDocumentMoc:(TICDSSynchronizedManagedObjectContext *)aContext
{
    NSManagedObjectContext *context = [[self syncChangesMOCs] valueForKey:[self keyForContext:aContext]];
    
    if( !context ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"SyncChanges MOC was requested for a managed object context that hasn't yet been added, so adding it before proceeding");
        
        context = [self addSyncChangesMocForDocumentMoc:aContext];
    }
    
    return context;
}

- (NSString *)keyForContext:(NSManagedObjectContext *)aContext
{
    return [NSString stringWithFormat:@"%p", aContext];
}

- (void)syncChangesMocDidSave:(NSNotification *)aNotification
{
    if ([aNotification object] != [self primaryDocumentMOC]) {
        return;
    }
    
    if( ![NSThread isMainThread] ) {
        [self performSelectorOnMainThread:@selector(syncChangesMocDidSave:) withObject:aNotification waitUntilDone:NO];
        return;
    }
    
    [[self syncChangesMocForDocumentMoc:[self primaryDocumentMOC]] mergeChangesFromContextDidSaveNotification:aNotification];
}

#pragma mark -
#pragma mark MANAGED OBJECT CONTEXT DID SAVE BEHAVIOR
- (void)synchronizedMOCWillSave:(TICDSSynchronizedManagedObjectContext *)aMoc
{
    // Do anything here that's needed before the application context is saved
}

- (void)synchronizedMOCDidSave:(TICDSSynchronizedManagedObjectContext *)aMoc
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"MOC saved, so beginning post-save processing");
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didBeginProcessingSyncChangesAfterManagedObjectContextDidSave:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didBeginProcessingSyncChangesAfterManagedObjectContextDidSave:aMoc];
        });
    }
    
    NSError *anyError = nil;
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Sync Manager will save Sync Changes context");
    
    BOOL success = [[self syncChangesMocForDocumentMoc:aMoc] save:&anyError];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Sync Manager failed to save Sync Changes context with error: %@", anyError);
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Sync Manager cannot continue processing any further, so bailing");
        if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToProcessSyncChangesAfterManagedObjectContextDidSave:withError:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [(id)self.delegate documentSyncManager:self didFailToProcessSyncChangesAfterManagedObjectContextDidSave:aMoc withError:[TICDSError errorWithCode:TICDSErrorCodeFailedToSaveSyncChangesMOC underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            });
        }
        
        return;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Sync Manager saved Sync Changes context successfully");
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFinishProcessingSyncChangesAfterManagedObjectContextDidSave:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didFinishProcessingSyncChangesAfterManagedObjectContextDidSave:aMoc];
        });
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Asking delegate if we should sync after saving");
    BOOL shouldSync = [self ti_delegateRespondsToSelector:@selector(documentSyncManager:shouldBeginSynchronizingAfterManagedObjectContextDidSave:)] && [(id)self.delegate documentSyncManager:self shouldBeginSynchronizingAfterManagedObjectContextDidSave:aMoc];
    if( !shouldSync ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Delegate denied synchronization after saving");
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Delegate allowed synchronization after saving");
    [self startSynchronizationProcess];
}

- (void)synchronizedMOCFailedToSave:(TICDSSynchronizedManagedObjectContext *)aMoc withError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Synchronized context failed to save with error: %@", anError);
}

#pragma mark -
#pragma mark NOTIFICATIONS
- (void)appSyncManagerDidRegister:(NSNotification *)aNotification
{
    [self setShouldUseEncryption:[[self applicationSyncManager] shouldUseEncryption]];
    
    for( TICDSOperation *eachOperation in [[self registrationQueue] operations] ) {
        [eachOperation setShouldUseEncryption:[self shouldUseEncryption]];
    }
    
    for( TICDSOperation *eachOperation in [[self synchronizationQueue] operations] ) {
        [eachOperation setShouldUseEncryption:[self shouldUseEncryption]];
    }
    
    for( TICDSOperation *eachOperation in [[self otherTasksQueue] operations] ) {
        [eachOperation setShouldUseEncryption:[self shouldUseEncryption]];
    }
    
    [[self registrationQueue] setSuspended:NO];
}

- (void)backgroundManagedObjectContextDidSave:(NSNotification *)aNotification
{
    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didMakeChangesToObjectsInBackgroundContextAndSaveWithNotification:)]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [(id)self.delegate documentSyncManager:self didMakeChangesToObjectsInBackgroundContextAndSaveWithNotification:aNotification];
        });
    }
}

- (void)applicationSyncManagerWillRemoveAllRemoteSyncData:(NSNotification *)aNotification
{
    
}

#pragma mark -
#pragma mark OPERATION COMMUNICATIONS
- (void)operationCompletedSuccessfully:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSDocumentRegistrationOperation class]] ) {
        [self documentRegistrationOperationCompleted:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreUploadOperation class]] ) {
        [self wholeStoreUploadOperationCompleted:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSSynchronizationOperation class]] ) {
        [self synchronizationOperationCompleted:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSVacuumOperation class]] ) {
        [self vacuumOperationCompleted:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreDownloadOperation class]] ) {
        [self wholeStoreDownloadOperationCompleted:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSListOfDocumentRegisteredClientsOperation class]] ) {
        [self registeredClientsOperationCompleted:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSDocumentClientDeletionOperation class]] ) {
        [self documentClientDeletionOperationCompleted:(id)anOperation];
    }
}

- (void)operationWasCancelled:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSDocumentRegistrationOperation class]] ) {
        [self documentRegistrationOperationWasCancelled:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreUploadOperation class]] ) {
        [self wholeStoreUploadOperationWasCancelled:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSSynchronizationOperation class]] ) {
        [self synchronizationOperationWasCancelled:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSVacuumOperation class]] ) {
        [self vacuumOperationWasCancelled:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreDownloadOperation class]] ) {
        [self wholeStoreDownloadOperationWasCancelled:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSListOfDocumentRegisteredClientsOperation class]] ) {
        [self registeredClientsOperationWasCancelled:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSDocumentClientDeletionOperation class]] ) {
        [self documentClientDeletionOperationWasCancelled:(id)anOperation];
    }
}

- (void)operationFailedToComplete:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSDocumentRegistrationOperation class]] ) {
        [self documentRegistrationOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreUploadOperation class]] ) {
        [self wholeStoreUploadOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    } else if( [anOperation isKindOfClass:[TICDSSynchronizationOperation class]] ) {
        [self synchronizationOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    } else if( [anOperation isKindOfClass:[TICDSVacuumOperation class]] ) {
        [self vacuumOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreDownloadOperation class]] ) {
        [self wholeStoreDownloadOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    } else if( [anOperation isKindOfClass:[TICDSListOfDocumentRegisteredClientsOperation class]] ) {
        [self registeredClientsOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    } else if( [anOperation isKindOfClass:[TICDSDocumentClientDeletionOperation class]] ) {
        [self documentClientDeletionOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    }
}

#pragma mark -
#pragma mark TICoreDataFactory Delegate
- (void)coreDataFactory:(TICoreDataFactory *)aFactory encounteredError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"TICoreDataFactory error: %@", anError);
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)init
{
    self = [super init];
    if( !self ) {
        return nil;
    }
    
    // Create the dictionary for the sync changes managed object contexts
    _syncChangesMOCs = [[NSMutableDictionary alloc] initWithCapacity:5];
    
    // Create Registration Queue (suspended, but unsuspended if App Sync Man is registered when registerWithDelegate:... is called)
    _registrationQueue = [[NSOperationQueue alloc] init];
    [_registrationQueue setSuspended:YES];
    
    // Create Other Queues (suspended until registration completes)
    _synchronizationQueue = [[NSOperationQueue alloc] init];
    [_synchronizationQueue setSuspended:YES];
    [_synchronizationQueue setMaxConcurrentOperationCount:1];
    
    _otherTasksQueue = [[NSOperationQueue alloc] init];
    [_otherTasksQueue setSuspended:YES];
    [_otherTasksQueue setMaxConcurrentOperationCount:1];
    
    return self;
}

#if !__has_feature(objc_arc)

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_applicationSyncManager release], _applicationSyncManager = nil;
    [_documentIdentifier release], _documentIdentifier = nil;
    [_clientIdentifier release], _clientIdentifier = nil;
    [_documentUserInfo release], _documentUserInfo = nil;
    [_fileManager release], _fileManager = nil;
    [_helperFileDirectoryLocation release], _helperFileDirectoryLocation = nil;
    [_primaryDocumentMOC release], _primaryDocumentMOC = nil;
    [_syncChangesMOCs release], _syncChangesMOCs = nil;
    [_coreDataFactory release], _coreDataFactory = nil;
    [_registrationQueue release], _registrationQueue = nil;
    [_synchronizationQueue release], _synchronizationQueue = nil;
    [_otherTasksQueue release], _otherTasksQueue = nil;
    [_integrityKey release], _integrityKey = nil;

    [super dealloc];
}
#endif

#pragma mark -
#pragma mark Lazy Accessors
- (NSFileManager *)fileManager
{
    if( _fileManager ) return _fileManager;
    
    _fileManager = [[NSFileManager alloc] init];
    
    return _fileManager;
}

- (TICoreDataFactory *)coreDataFactory
{
    if( _coreDataFactory ) return _coreDataFactory;
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _coreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeDataModelName];
    [_coreDataFactory setDelegate:self];
    [_coreDataFactory setPersistentStoreType:TICDSSyncChangesCoreDataPersistentStoreType];
    [_coreDataFactory setPersistentStoreDataPath:[self unsynchronizedSyncChangesStorePath]];
    
    return _coreDataFactory;
}

#pragma mark -
#pragma mark Paths
- (NSString *)relativePathToClientDevicesDirectory
{
    return TICDSClientDevicesDirectoryName;
}

- (NSString *)relativePathToInformationDirectory
{
    return TICDSInformationDirectoryName;
}

- (NSString *)relativePathToInformationDeletedDocumentsDirectory
{
    return [[self relativePathToInformationDirectory] stringByAppendingPathComponent:TICDSDeletedDocumentsDirectoryName];
}

- (NSString *)relativePathToDeletedDocumentsThisDocumentIdentifierPlistFile
{
    return [[self relativePathToInformationDeletedDocumentsDirectory] stringByAppendingPathComponent:[[self documentIdentifier] stringByAppendingPathExtension:TICDSDocumentInfoPlistExtension]];
}

- (NSString *)relativePathToDocumentsDirectory
{
    return TICDSDocumentsDirectoryName; 
}

- (NSString *)relativePathToThisDocumentDirectory
{
    return [[self relativePathToDocumentsDirectory] stringByAppendingPathComponent:[self documentIdentifier]];
}

- (NSString *)relativePathToThisDocumentDeletedClientsDirectory
{
    return [[self relativePathToThisDocumentDirectory] stringByAppendingPathComponent:TICDSDeletedClientsDirectoryName];
}

- (NSString *)relativePathToThisDocumentSyncChangesDirectory
{
    return [[self relativePathToThisDocumentDirectory] stringByAppendingPathComponent:TICDSSyncChangesDirectoryName];
}

- (NSString *)relativePathToThisDocumentSyncChangesThisClientDirectory
{
    return [[self relativePathToThisDocumentSyncChangesDirectory] stringByAppendingPathComponent:[self clientIdentifier]];
}

- (NSString *)relativePathToThisDocumentSyncCommandsDirectory
{
    return [[self relativePathToThisDocumentDirectory] stringByAppendingPathComponent:TICDSSyncCommandsDirectoryName];
}

- (NSString *)relativePathToThisDocumentSyncCommandsThisClientDirectory
{
    return [[self relativePathToThisDocumentSyncCommandsDirectory] stringByAppendingPathComponent:[self clientIdentifier]];
}

- (NSString *)relativePathToThisDocumentTemporaryFilesDirectory
{
    return [[self relativePathToThisDocumentDirectory] stringByAppendingPathComponent:TICDSTemporaryFilesDirectoryName];
}

- (NSString *)relativePathToThisDocumentTemporaryWholeStoreDirectory
{
    return [[self relativePathToThisDocumentTemporaryFilesDirectory] stringByAppendingPathComponent:TICDSWholeStoreDirectoryName];
}

- (NSString *)relativePathToThisDocumentTemporaryWholeStoreThisClientDirectory
{
    return [[self relativePathToThisDocumentTemporaryWholeStoreDirectory] stringByAppendingPathComponent:[self clientIdentifier]];
}

- (NSString *)relativePathToThisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFile
{
    return [[self relativePathToThisDocumentTemporaryWholeStoreThisClientDirectory] stringByAppendingPathComponent:TICDSWholeStoreFilename];
}

- (NSString *)relativePathToThisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFile
{
    return [[self relativePathToThisDocumentTemporaryWholeStoreThisClientDirectory] stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename];
}

- (NSString *)relativePathToThisDocumentWholeStoreDirectory
{
    return [[self relativePathToThisDocumentDirectory] stringByAppendingPathComponent:TICDSWholeStoreDirectoryName];
}

- (NSString *)relativePathToThisDocumentWholeStoreThisClientDirectory
{
    return [[self relativePathToThisDocumentWholeStoreDirectory] stringByAppendingPathComponent:[self clientIdentifier]];
}

- (NSString *)relativePathToThisDocumentWholeStoreThisClientDirectoryWholeStoreFile
{
    return [[self relativePathToThisDocumentWholeStoreThisClientDirectory] stringByAppendingPathComponent:TICDSWholeStoreFilename];
}

- (NSString *)relativePathToThisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFile
{
    return [[self relativePathToThisDocumentWholeStoreThisClientDirectory] stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename];
}

- (NSString *)relativePathToThisDocumentRecentSyncsDirectory
{
    return [[self relativePathToThisDocumentDirectory] stringByAppendingPathComponent:TICDSRecentSyncsDirectoryName];
}

- (NSString *)relativePathToThisDocumentRecentSyncsDirectoryThisClientFile
{
    return [[[self relativePathToThisDocumentRecentSyncsDirectory] stringByAppendingPathComponent:[self clientIdentifier]] stringByAppendingPathExtension:TICDSRecentSyncFileExtension];
}

- (NSString *)localAppliedSyncChangesFilePath
{
    return [[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename];
}

- (NSString *)syncChangesBeingSynchronizedStorePath
{
    return [[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:TICDSSyncChangesBeingSynchronizedStoreName];
}

- (NSString *)unsynchronizedSyncChangesStorePath
{
    return [[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:TICDSUnsynchronizedSyncChangesStoreName];
}

#pragma mark -
#pragma mark Properties
@synthesize delegate = _delegate;
@synthesize shouldUseEncryption = _shouldUseEncryption;
@synthesize mustUploadStoreAfterRegistration = _mustUploadStoreAfterRegistration;
@synthesize state = _state;
@synthesize applicationSyncManager = _applicationSyncManager;
@synthesize documentIdentifier = _documentIdentifier;
@synthesize documentDescription = _documentDescription;
@synthesize clientIdentifier = _clientIdentifier;
@synthesize documentUserInfo = _documentUserInfo;
@synthesize fileManager = _fileManager;
@synthesize helperFileDirectoryLocation = _helperFileDirectoryLocation;
@synthesize primaryDocumentMOC = _primaryDocumentMOC;
@synthesize coreDataFactory = _coreDataFactory;
@synthesize syncChangesMOCs = _syncChangesMOCs;
@synthesize registrationQueue = _registrationQueue;
@synthesize synchronizationQueue = _synchronizationQueue;
@synthesize otherTasksQueue = _otherTasksQueue;
@synthesize integrityKey = _integrityKey;

@end
