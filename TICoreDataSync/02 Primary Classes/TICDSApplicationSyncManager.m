//
//  TICDSApplicationSyncManager.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSApplicationSyncManager ()

- (BOOL)startRegistrationProcess:(NSError **)outError;
- (void)bailFromRegistrationProcessWithError:(NSError *)anError;
- (BOOL)getAvailablePreviouslySynchronizedDocuments:(NSError **)outError;
- (void)bailFromDocumentDownloadProcessForDocumentWithIdentifier:(NSString *)anIdentifier error:(NSError *)anError;
- (BOOL)startDocumentDownloadProcessForDocumentWithIdentifier:(NSString *)anIdentifier toLocation:(NSURL *)aLocation error:(NSError **)outError;
- (BOOL)startRegisteredDevicesInformationProcessByIncludingDocuments:(BOOL)includeDocuments error:(NSError **)outError;
- (void)bailFromRegisteredDevicesInformationProcessWithError:(NSError *)anError;
- (BOOL)startDocumentDeletionProcessForDocumentWithIdentifier:(NSString *)anIdentifier error:(NSError **)outError;
- (void)bailFromDocumentDeletionProcessForDocumentWithIdentifier:(NSString *)anIdentifier error:(NSError *)anError;
- (BOOL)startRemoveAllSyncDataProcess:(NSError **)outError;
- (void)bailFromRemoveAllSyncDataProcessWithError:(NSError *)anError;

@property (nonatomic, assign) TICDSApplicationSyncManagerState state;
@property (nonatomic, copy) NSString *appIdentifier;
@property (nonatomic, copy) NSString *clientIdentifier;
@property (nonatomic, copy) NSString *clientDescription;
@property (nonatomic, strong) NSDictionary *applicationUserInfo;
@property (nonatomic, strong) NSOperationQueue *otherTasksQueue;
@property (nonatomic, strong) NSOperationQueue *registrationQueue;

@end

@implementation TICDSApplicationSyncManager

#pragma mark - ACTIVITY
- (void)postIncreaseActivityNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TICDSApplicationSyncManagerDidIncreaseActivityNotification object:self];
}

- (void)postDecreaseActivityNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TICDSApplicationSyncManagerDidDecreaseActivityNotification object:self];
}

#pragma mark - ENCRYPTION UPDATING

- (void)clearSyncEncryptionPassword
{
    FZACryptor *cryptor = [[FZACryptor alloc] init];
    [cryptor clearPasswordAndSalt];
}

#pragma mark - CONFIGURATION
- (void)configureWithDelegate:(id <TICDSApplicationSyncManagerDelegate>)aDelegate globalAppIdentifier:(NSString *)anAppIdentifier uniqueClientIdentifier:(NSString *)aClientIdentifier description:(NSString *)aClientDescription userInfo:(NSDictionary *)someUserInfo
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Registration Information:\n   Delegate: %@,\n   Global App ID: %@,\n   Client ID: %@,\n   Description: %@\nUser Info: %@", aDelegate, anAppIdentifier, aClientIdentifier, aClientDescription, someUserInfo);
    
    [self setDelegate:aDelegate];
    [self setAppIdentifier:anAppIdentifier];
    [self setClientIdentifier:aClientIdentifier];
    [self setClientDescription:aClientDescription];
    [self setApplicationUserInfo:someUserInfo];
    
    BOOL shouldUseCompression = YES;
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerShouldUseCompressionForWholeStoreMoves:)]) {
        shouldUseCompression = [self.delegate applicationSyncManagerShouldUseCompressionForWholeStoreMoves:self];
    }
    [self setShouldUseCompressionForWholeStoreMoves:shouldUseCompression];

    BOOL shouldProcessInBackgroundState = YES;
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerShouldSupportProcessingInBackgroundState:)]) {
        shouldProcessInBackgroundState = [self.delegate applicationSyncManagerShouldSupportProcessingInBackgroundState:self];
    }
    [self setShouldContinueProcessingInBackgroundState:shouldProcessInBackgroundState];
    
    self.configured = YES;
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Application sync manager configured for future registration");
}

#pragma mark - REGISTRATION
- (void)registerWithDelegate:(id <TICDSApplicationSyncManagerDelegate>)aDelegate globalAppIdentifier:(NSString *)anAppIdentifier uniqueClientIdentifier:(NSString *)aClientIdentifier description:(NSString *)aClientDescription userInfo:(NSDictionary *)someUserInfo
{
    [self configureWithDelegate:aDelegate globalAppIdentifier:anAppIdentifier uniqueClientIdentifier:aClientIdentifier description:aClientDescription userInfo:someUserInfo];
    
    [self registerConfiguredApplicationSyncManager];
}

- (void)registerConfiguredApplicationSyncManager
{
    [self setState:TICDSApplicationSyncManagerStateRegistering];

    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting to register application sync manager");
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerDidBeginRegistering:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManagerDidBeginRegistering:self];
        }];
    }
    
    if (self.isConfigured == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Unable to register an application sync manager using registerPreConfiguredApplicationSyncManager - it hasn't already configured");
        self.state = TICDSApplicationSyncManagerStateNotYetRegistered;
        [self bailFromRegistrationProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeUnableToRegisterUnconfiguredSyncManager classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    NSError *anyError = nil;
    BOOL shouldContinue = [self startRegistrationProcess:&anyError];
    if( !shouldContinue ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error registering: %@", anyError);
        [self bailFromRegistrationProcessWithError:anyError];
        return;
    }
}

- (void)bailFromRegistrationProcessWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from application registration process");

    self.state = TICDSApplicationSyncManagerStateNotYetRegistered;
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToRegisterWithError:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToRegisterWithError:anError];
        }];
    }
    [self postDecreaseActivityNotification];
}

- (BOOL)startRegistrationProcess:(NSError **)outError
{
    TICDSApplicationRegistrationOperation *operation = [self applicationRegistrationOperation];

    if (operation == nil) {
        if (outError != nil) {
            *outError = [TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__];
        }

        return NO;
    }

    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    [operation setAppIdentifier:[self appIdentifier]];
    [operation setClientDescription:[self clientDescription]];
    [operation setClientIdentifier:[self clientIdentifier]];
    [operation setApplicationUserInfo:[self applicationUserInfo]];

    [[self registrationQueue] addOperation:operation];

    return YES;
}

#pragma mark Asking Whether to Use Encryption on First Registration
- (void)registrationOperationPausedToFindOutWhetherToEnableEncryption:(TICDSApplicationRegistrationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"First-time Application Registration paused to find out whether to use encryption for this application");
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerDidPauseRegistrationToAskWhetherToUseEncryptionForFirstTimeRegistration:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManagerDidPauseRegistrationToAskWhetherToUseEncryptionForFirstTimeRegistration:self];
        }];
    }
[self postDecreaseActivityNotification];
}

- (void)registrationOperationResumedFollowingEncryptionInstruction:(TICDSApplicationRegistrationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"First-time Application Registration resumed after finding out whether to use encryption");
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerDidContinueRegistering:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManagerDidContinueRegistering:self];
        }];
    }
}

#pragma mark Asking for the Encryption Password on Subsequent Registrations
- (void)registrationOperationPausedToRequestEncryptionPassword:(TICDSApplicationRegistrationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Encrypted application registration paused to ask for a password");
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerDidPauseRegistrationToRequestPasswordForEncryptedApplicationSyncData:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManagerDidPauseRegistrationToRequestPasswordForEncryptedApplicationSyncData:self];
        }];
    }
    [self postDecreaseActivityNotification];
}

- (void)registrationOperationResumedFollowingPasswordProvision:(TICDSApplicationRegistrationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Encrypted application registration resumed after being given a password");
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerDidContinueRegistering:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManagerDidContinueRegistering:self];
        }];
    }
}

#pragma mark Continuing after Gaining an Encryption Password
- (void)continueRegisteringWithEncryptionPassword:(NSString *)aPassword
{
    aPassword = [aPassword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if( [aPassword length] < 1 ) {
        aPassword = nil;
    }
    
    // Just start the registration operation again
    [(TICDSApplicationRegistrationOperation *)[[[self registrationQueue] operations] lastObject] setShouldUseEncryption:(aPassword != nil)];
    [(TICDSApplicationRegistrationOperation *)[[[self registrationQueue] operations] lastObject] setPassword:aPassword];
    
    [(TICDSApplicationRegistrationOperation *)[[[self registrationQueue] operations] lastObject] setPaused:NO];
}

#pragma mark Cancel Registration
- (void)cancelRegistrationWithoutProvidingEncryptionPassword
{
    [(TICDSApplicationRegistrationOperation *)[[[self registrationQueue] operations] lastObject] cancel];
    
    [(TICDSApplicationRegistrationOperation *)[[[self registrationQueue] operations] lastObject] setPaused:NO];
}

#pragma mark Operation Generation
- (TICDSApplicationRegistrationOperation *)applicationRegistrationOperation
{
    return [[TICDSApplicationRegistrationOperation alloc] initWithDelegate:self];
}

#pragma mark Operation Communications
- (void)applicationRegistrationOperationCompleted:(TICDSApplicationRegistrationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Application Registration Operation Completed");
    
    [self setShouldUseEncryption:[anOperation shouldUseEncryption]];
    
    [self setState:TICDSApplicationSyncManagerStateAbleToSync];
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Finished registering application sync manager");
    
    // Registration Complete
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerDidFinishRegistering:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManagerDidFinishRegistering:self];
        }];
    }
    [self postDecreaseActivityNotification];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Resuming Operation Queues");
    for( TICDSOperation *eachOperation in [[self otherTasksQueue] operations] ) {
        [eachOperation setShouldUseEncryption:[self shouldUseEncryption]];
    }
    
    [[self otherTasksQueue] setSuspended:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TICDSApplicationSyncManagerDidFinishRegisteringNotification object:self];
}

- (void)applicationRegistrationOperationWasCancelled:(TICDSApplicationRegistrationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Application Registration Operation was Cancelled");
    [self setState:TICDSApplicationSyncManagerStateNotYetRegistered];
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToRegisterWithError:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToRegisterWithError:[TICDSError errorWithCode:TICDSErrorCodeTaskWasCancelled classAndMethod:__PRETTY_FUNCTION__]];
        }];
    }
    [self postDecreaseActivityNotification];
}

- (void)applicationRegistrationOperation:(TICDSApplicationRegistrationOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    [self setState:TICDSApplicationSyncManagerStateNotYetRegistered];
    [self postDecreaseActivityNotification];

    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Application Registration Operation Failed to Complete with Error: %@", anError);
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToRegisterWithError:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
             [(id)self.delegate applicationSyncManager:self didFailToRegisterWithError:anError];
         }];
    }
}

#pragma mark - Other Tasks Process

-(void)cancelOtherTasks;
{
    [self.otherTasksQueue cancelAllOperations];
}

#pragma mark - LIST OF PREVIOUSLY SYNCHRONIZED DOCUMENTS
- (void)requestListOfPreviouslySynchronizedDocuments
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting to check for remote documents that have been previously synchronized");
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerDidBeginCheckingForPreviouslySynchronizedDocuments:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManagerDidBeginCheckingForPreviouslySynchronizedDocuments:self];
        }];
    }
    [self postIncreaseActivityNotification];
    
    NSError *anyError = nil;
    BOOL success = [self getAvailablePreviouslySynchronizedDocuments:&anyError];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Request for list of previously-synchronized documents failed with error: %@", anyError);
        if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToCheckForPreviouslySynchronizedDocumentsWithError:)]) {
            [self runOnMainQueueWithoutDeadlocking:^{
                [(id)self.delegate applicationSyncManager:self didFailToCheckForPreviouslySynchronizedDocumentsWithError:anyError];
            }];
        }
        [self postDecreaseActivityNotification];
    }
}

- (BOOL)getAvailablePreviouslySynchronizedDocuments:(NSError **)outError
{
    TICDSListOfPreviouslySynchronizedDocumentsOperation *operation = [self listOfPreviouslySynchronizedDocumentsOperation];
    
    if( !operation ) {
        if( outError ) {
            *outError = [TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__];
        }
        
        return NO;
    }
    
    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    
    [[self otherTasksQueue] addOperation:operation];
    
    return YES;
}

- (void)gotNoPreviouslySynchronizedDocuments
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Didn't get any available documents");
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerDidFinishCheckingAndFoundNoPreviouslySynchronizedDocuments:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManagerDidFinishCheckingAndFoundNoPreviouslySynchronizedDocuments:self];
        }];
    }
    [self postDecreaseActivityNotification];
}

- (void)gotAvailablePreviouslySynchronizedDocuments:(NSArray *)anArray
{
    if( [anArray count] < 1 ) {
        [self gotNoPreviouslySynchronizedDocuments];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Found previously-synchronized remote documents: %@", anArray);
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFinishCheckingAndFoundPreviouslySynchronizedDocuments:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFinishCheckingAndFoundPreviouslySynchronizedDocuments:anArray];
        }];
    }
    [self postDecreaseActivityNotification];
}

#pragma mark Operation Generation
- (TICDSListOfPreviouslySynchronizedDocumentsOperation *)listOfPreviouslySynchronizedDocumentsOperation
{
    return [[TICDSListOfPreviouslySynchronizedDocumentsOperation alloc] initWithDelegate:self];
}

#pragma mark Operation Communications
- (void)listOfDocumentsOperationCompleted:(TICDSListOfPreviouslySynchronizedDocumentsOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"List of Previously-Synchronized Documents Operation Completed");
    [self gotAvailablePreviouslySynchronizedDocuments:[anOperation availableDocuments]];
}

- (void)listOfDocumentsOperationWasCancelled:(TICDSListOfPreviouslySynchronizedDocumentsOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"List of Previously-Synchronized Documents Operation was Cancelled");
    [self gotNoPreviouslySynchronizedDocuments];
}

- (void)listOfDocumentsOperation:(TICDSListOfPreviouslySynchronizedDocumentsOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"List of Previously-Synchronized Documents Operation Failed to Complete with Error: %@", anError);
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToCheckForPreviouslySynchronizedDocumentsWithError:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToCheckForPreviouslySynchronizedDocumentsWithError:anError];
        }];
    }
    [self postDecreaseActivityNotification];
}

#pragma mark - DOCUMENT DOWNLOAD
- (void)requestDownloadOfDocumentWithIdentifier:(NSString *)anIdentifier toLocation:(NSURL *)aLocation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting to download a previously synchronized document %@ to %@", anIdentifier, aLocation);
    
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didBeginDownloadingDocumentWithIdentifier:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didBeginDownloadingDocumentWithIdentifier:anIdentifier];
        }];
    }
    
    NSError *anyError = nil;
    BOOL success = [self startDocumentDownloadProcessForDocumentWithIdentifier:anIdentifier toLocation:aLocation error:&anyError];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Download of previously-synchronized document failed with error: %@", anyError);
        [self bailFromDocumentDownloadProcessForDocumentWithIdentifier:anIdentifier error:anyError];
    }
}

- (void)bailFromDocumentDownloadProcessForDocumentWithIdentifier:(NSString *)anIdentifier error:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from document download process");
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToDownloadDocumentWithIdentifier:error:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToDownloadDocumentWithIdentifier:anIdentifier error:anError];
        }];
    }
    [self postDecreaseActivityNotification];
}

- (BOOL)startDocumentDownloadProcessForDocumentWithIdentifier:(NSString *)anIdentifier toLocation:(NSURL *)aLocation error:(NSError **)outError
{
    [self beginBackgroundTask];
    
    // Set download to go to a temporary location
    NSString *temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:TICDSFrameworkName];
    temporaryPath = [temporaryPath stringByAppendingPathComponent:anIdentifier];
    
    NSError *anyError = nil;
    BOOL success = [[self fileManager] createDirectoryAtPath:temporaryPath withIntermediateDirectories:YES attributes:nil error:&anyError];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create temporary directory for document download: %@", anyError);
        
        if( outError ) {
            *outError = [TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__];
        }
        
        return NO;
    }
    
    TICDSWholeStoreDownloadOperation *operation = [self wholeStoreDownloadOperationForDocumentWithIdentifier:(NSString *)anIdentifier];
    
    if( !operation ) {
        if( outError ) {
            *outError = [TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__];
        }
        
        return NO;
    }
    
    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    [operation setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:aLocation, kTICDSDocumentDownloadFinalWholeStoreLocation, anIdentifier, kTICDSDocumentIdentifier, nil]];
    
    NSString *wholeStoreFilePath = [temporaryPath stringByAppendingPathComponent:TICDSWholeStoreFilename];
    NSString *appliedSyncChangesFilePath = [temporaryPath stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename];
    
    [operation setLocalWholeStoreFileLocation:[NSURL fileURLWithPath:wholeStoreFilePath]];
    [operation setLocalAppliedSyncChangeSetsFileLocation:[NSURL fileURLWithPath:appliedSyncChangesFilePath]];
    
    [operation setClientIdentifier:[self clientIdentifier]];
    
    [[self otherTasksQueue] addOperation:operation];
    
    return YES;
}

#pragma mark Overridden Methods
- (TICDSWholeStoreDownloadOperation *)wholeStoreDownloadOperationForDocumentWithIdentifier:(NSString *)anIdentifier
{
    return [[TICDSWholeStoreDownloadOperation alloc] initWithDelegate:self];
}

#pragma mark Post-Operation Work
- (void)bailFromDocumentDownloadPostProcessingForOperation:(TICDSWholeStoreDownloadOperation *)anOperation withError:(NSError *)anError
{
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToDownloadDocumentWithIdentifier:error:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToDownloadDocumentWithIdentifier:[[anOperation userInfo] valueForKey:kTICDSDocumentIdentifier] error:anError];
        }];
    }
    [self postDecreaseActivityNotification];
}

#pragma mark Operation Communications

-(void)wholeStoreDownloadOperationReportedProgress:(TICDSWholeStoreDownloadOperation *)anOperation;
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Whole Store Download Operation Progress Reported: %.2f",[anOperation progress]);
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:whileDownloadingDocumentWithIdentifier:didReportProgress:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self whileDownloadingDocumentWithIdentifier:[[anOperation userInfo] valueForKey:kTICDSDocumentIdentifier] didReportProgress:[anOperation progress]];
        }];
    }
}

- (void)documentDownloadOperationCompleted:(TICDSWholeStoreDownloadOperation *)anOperation
{
    NSError *anyError = nil;
    BOOL success = YES;
    
    NSURL *finalWholeStoreLocation = [[anOperation userInfo] valueForKey:kTICDSDocumentDownloadFinalWholeStoreLocation];
    if (finalWholeStoreLocation == nil || [finalWholeStoreLocation path] == nil) {
        [self bailFromDocumentDownloadPostProcessingForOperation:anOperation withError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    // Remove existing WholeStore, if necessary
    if( [[self fileManager] fileExistsAtPath:[finalWholeStoreLocation path]] ) {
        if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:willReplaceWholeStoreFileForDocumentWithIdentifier:atURL:)]) {
            [self runOnMainQueueWithoutDeadlocking:^{
                [(id)self.delegate applicationSyncManager:self willReplaceWholeStoreFileForDocumentWithIdentifier:[[anOperation userInfo] valueForKey:kTICDSDocumentIdentifier] atURL:finalWholeStoreLocation];
            }];
        }
        success = [[self fileManager] removeItemAtPath:[finalWholeStoreLocation path] error:&anyError];
        
        if( !success ) {
            [self bailFromDocumentDownloadPostProcessingForOperation:anOperation withError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            return;
        }
    }
    
    // Move downloaded WholeStore
    success = [[self fileManager] moveItemAtPath:[[anOperation localWholeStoreFileLocation] path] toPath:[finalWholeStoreLocation path] error:&anyError];
    if( !success ) {
        [self bailFromDocumentDownloadPostProcessingForOperation:anOperation withError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    // Get document sync manager from delegate
    TICDSDocumentSyncManager *documentSyncManager = nil;
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:preConfiguredDocumentSyncManagerForDownloadedDocumentWithIdentifier:atURL:)]) {
        documentSyncManager = [(id)self.delegate applicationSyncManager:self preConfiguredDocumentSyncManagerForDownloadedDocumentWithIdentifier:[[anOperation userInfo] valueForKey:kTICDSDocumentIdentifier] atURL:finalWholeStoreLocation];
    }
    
    if( !documentSyncManager ) {
        // TODO: ALERT DELEGATE AND BAIL
    }
    
    NSString *finalAppliedSyncChangeSetsPath = [documentSyncManager localAppliedSyncChangesFilePath];
    
    // Remove existing applied sync changes, if necessary
    if( [[self fileManager] fileExistsAtPath:finalAppliedSyncChangeSetsPath] && ![[self fileManager] removeItemAtPath:finalAppliedSyncChangeSetsPath error:&anyError] ) {
        [self bailFromDocumentDownloadPostProcessingForOperation:anOperation withError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    // Move new applied sync changes, if necessary
    if( [[self fileManager] fileExistsAtPath:[[anOperation localAppliedSyncChangeSetsFileLocation] path]] && ![[self fileManager] moveItemAtPath:[[anOperation localAppliedSyncChangeSetsFileLocation] path] toPath:finalAppliedSyncChangeSetsPath error:&anyError] ) {
        [self bailFromDocumentDownloadPostProcessingForOperation:anOperation withError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Document Download Operation Completed");

    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFinishDownloadingDocumentWithIdentifier:atURL:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFinishDownloadingDocumentWithIdentifier:[[anOperation userInfo] valueForKey:kTICDSDocumentIdentifier] atURL:finalWholeStoreLocation];
        }];
    }
    
    [self endBackgroundTask];
    
    [self postDecreaseActivityNotification];
}

- (void)documentDownloadOperationWasCancelled:(TICDSWholeStoreDownloadOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Document Download Operation was Cancelled");
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToDownloadDocumentWithIdentifier:error:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToDownloadDocumentWithIdentifier:[[anOperation userInfo] valueForKey:kTICDSDocumentIdentifier] error:[TICDSError errorWithCode:TICDSErrorCodeTaskWasCancelled classAndMethod:__PRETTY_FUNCTION__]];
        }];
    }
    [self endBackgroundTask];
    [self postDecreaseActivityNotification];
}

- (void)documentDownloadOperation:(TICDSWholeStoreDownloadOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Document Download Operation Failed to Complete with Error: %@", anError);
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToDownloadDocumentWithIdentifier:error:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToDownloadDocumentWithIdentifier:[[anOperation userInfo] valueForKey:kTICDSDocumentIdentifier] error:anError];
        }];
    }
    [self endBackgroundTask];
    [self postDecreaseActivityNotification];
}

#pragma mark - LIST OF CLIENT DEVICES
- (void)requestListOfSynchronizedClientsIncludingDocuments:(BOOL)includeDocuments
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Beginning request for device information");
    
    NSError *anyError = nil;
    BOOL success = [self startRegisteredDevicesInformationProcessByIncludingDocuments:includeDocuments error:&anyError];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Registered device information request failed with error: %@", anyError);
        [self bailFromRegisteredDevicesInformationProcessWithError:anyError];
    }
}

- (void)bailFromRegisteredDevicesInformationProcessWithError:(NSError *)anError;
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from device information request");
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToFetchInformationForAllRegisteredDevicesWithError:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToFetchInformationForAllRegisteredDevicesWithError:anError];
        }];
    }
    [self postDecreaseActivityNotification];
}

- (BOOL)startRegisteredDevicesInformationProcessByIncludingDocuments:(BOOL)includeDocuments error:(NSError **)outError;
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting process to fetch information on all devices registered to synchronize this application");
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerDidBeginToFetchInformationForAllRegisteredDevices:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManagerDidBeginToFetchInformationForAllRegisteredDevices:self];
        }];
    }

    TICDSListOfApplicationRegisteredClientsOperation *operation = [self listOfApplicationRegisteredClientsOperation];
    
    if( !operation ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create registered clients operation object");
        [self bailFromRegisteredDevicesInformationProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__]];
        return NO;
    }
    
    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    [operation setShouldIncludeRegisteredDocuments:includeDocuments];
    
    [[self otherTasksQueue] addOperation:operation];
    
    return YES;
}

#pragma mark Operation Generation
- (TICDSListOfApplicationRegisteredClientsOperation *)listOfApplicationRegisteredClientsOperation
{
    return [[TICDSListOfApplicationRegisteredClientsOperation alloc] initWithDelegate:self];
}

#pragma mark Operation Communications
- (void)registeredClientsOperationCompleted:(TICDSListOfApplicationRegisteredClientsOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Registered Device Information Operation Completed");
    
    NSDictionary *information = [anOperation deviceInfoDictionaries];
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFinishFetchingInformationForAllRegisteredDevices:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFinishFetchingInformationForAllRegisteredDevices:information];
        }];
    }
    [self postDecreaseActivityNotification];
}

- (void)registeredClientsOperationWasCancelled:(TICDSListOfApplicationRegisteredClientsOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Registered Device Information Operation was Cancelled");
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToFetchInformationForAllRegisteredDevicesWithError:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToFetchInformationForAllRegisteredDevicesWithError:[TICDSError errorWithCode:TICDSErrorCodeTaskWasCancelled classAndMethod:__PRETTY_FUNCTION__]];
        }];
    }
    [self postDecreaseActivityNotification];
}

- (void)registeredClientsOperation:(TICDSListOfApplicationRegisteredClientsOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Registered Device Information Operation Failed to Complete with Error: %@", anError);
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToFetchInformationForAllRegisteredDevicesWithError:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToFetchInformationForAllRegisteredDevicesWithError:anError];
        }];
    }
    [self postDecreaseActivityNotification];
}

#pragma mark - DOCUMENT DELETION
- (void)deleteDocumentWithIdentifier:(NSString *)anIdentifier
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Initiating deletion process for document %@", anIdentifier);
    
    NSError *anyError = nil;
    BOOL success = [self startDocumentDeletionProcessForDocumentWithIdentifier:anIdentifier error:&anyError];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Document deletion request failed with error: %@", anyError);
        [self bailFromDocumentDeletionProcessForDocumentWithIdentifier:anIdentifier error:anyError];
    }
}

- (BOOL)startDocumentDeletionProcessForDocumentWithIdentifier:(NSString *)anIdentifier error:(NSError **)outError
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting process to delete document %@", anIdentifier);
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didBeginDeletionProcessForDocumentWithIdentifier:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didBeginDeletionProcessForDocumentWithIdentifier:anIdentifier];
        }];
    }

    TICDSDocumentDeletionOperation *operation = [self documentDeletionOperationForDocumentWithIdentifier:anIdentifier];
    
    if( !operation ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create document deletion operation object");
        [self bailFromDocumentDeletionProcessForDocumentWithIdentifier:anIdentifier error:[TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__]];
        return NO;
    }
    
    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    [operation setDocumentIdentifier:anIdentifier];
    
    [[self otherTasksQueue] addOperation:operation];
    
    return YES;
}

- (void)bailFromDocumentDeletionProcessForDocumentWithIdentifier:(NSString *)anIdentifier error:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from document deletion request");
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToDeleteDocumentWithIdentifier:error:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToDeleteDocumentWithIdentifier:anIdentifier error:anError];
        }];
    }
    [self postDecreaseActivityNotification];
}

#pragma mark Operation Generation
- (TICDSDocumentDeletionOperation *)documentDeletionOperationForDocumentWithIdentifier:(NSString *)anIdentifier
{
    return [[TICDSDocumentDeletionOperation alloc] initWithDelegate:self];
}

#pragma mark Operation Communication
- (void)documentDeletionOperationWillDeleteDocument:(TICDSDocumentDeletionOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Document Deletion Operation will delete document");
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:willDeleteDirectoryForDocumentWithIdentifier:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self willDeleteDirectoryForDocumentWithIdentifier:[anOperation documentIdentifier]];
        }];
    }
}

- (void)documentDeletionOperationDidDeleteDocument:(TICDSDocumentDeletionOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Document Deletion Operation did delete document");
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didDeleteDirectoryForDocumentWithIdentifier:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didDeleteDirectoryForDocumentWithIdentifier:[anOperation documentIdentifier]];
        }];
    }

}

- (void)documentDeletionOperationCompleted:(TICDSDocumentDeletionOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Document Deletion Operation Completed");
    
    NSString *identifier = [anOperation documentIdentifier];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Removing integrity key from user defaults");
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[TICDSUtilities userDefaultsKeyForIntegrityKeyForDocumentWithIdentifier:identifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFinishDeletingDocumentWithIdentifier:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFinishDeletingDocumentWithIdentifier:identifier];
        }];
    }
    [self postDecreaseActivityNotification];
}

- (void)documentDeletionOperationWasCancelled:(TICDSDocumentDeletionOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Document Deletion Operation was Cancelled");
    
    NSString *identifier = [anOperation documentIdentifier];
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToDeleteDocumentWithIdentifier:error:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToDeleteDocumentWithIdentifier:identifier error:[TICDSError errorWithCode:TICDSErrorCodeTaskWasCancelled classAndMethod:__PRETTY_FUNCTION__]];
        }];
    }
    [self postDecreaseActivityNotification];
}

- (void)documentDeletionOperation:(TICDSDocumentDeletionOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Document Deletion Operation Failed to Complete with Error: %@", anError);
    
    NSString *identifier = [anOperation documentIdentifier];
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToDeleteDocumentWithIdentifier:error:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToDeleteDocumentWithIdentifier:identifier error:anError];
        }];
    }
    [self postDecreaseActivityNotification];
}

#pragma mark - REMOVING ALL SYNC DATA
- (void)removeAllSyncDataFromRemote
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Initiating removal process for all remote sync data");
    
    [self setState:TICDSApplicationSyncManagerStateNotYetRegistered];
    
    NSError *anyError = nil;
    BOOL success = [self startRemoveAllSyncDataProcess:&anyError];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Request to remove all remote sync data failed with error: %@", anyError);
        [self bailFromRemoveAllSyncDataProcessWithError:anyError];
    }
}

- (BOOL)startRemoveAllSyncDataProcess:(NSError **)outError
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting process to remove all remote sync data");
    [self postIncreaseActivityNotification];
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerWillRemoveAllSyncData:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManagerWillRemoveAllSyncData:self];
        }];
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Cancelling any existing operations");
    [[self otherTasksQueue] cancelAllOperations];
    [[self registrationQueue] cancelAllOperations];
    TICDSLog(TICDSLogVerbosityEveryStep, @"Cancelled existing operations");
    
    TICDSRemoveAllRemoteSyncDataOperation *operation = [self removeAllSyncDataOperation];
    
    if( !operation ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create 'remove all remote sync data' operation object");
        [self bailFromRemoveAllSyncDataProcessWithError:[TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__]];
        return NO;
    }
    
    [self setOtherTasksQueue:[[NSOperationQueue alloc] init]];
    [self setRegistrationQueue:[[NSOperationQueue alloc] init]];
    
    [operation setShouldUseEncryption:[self shouldUseEncryption]];
    [operation setShouldUseCompressionForWholeStoreMoves:[self shouldUseCompressionForWholeStoreMoves]];
    [[self otherTasksQueue] addOperation:operation];
    
    return YES;
}

- (void)bailFromRemoveAllSyncDataProcessWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from remove all remote sync data request");
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToRemoveAllSyncDataWithError:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToRemoveAllSyncDataWithError:anError];
        }];
    }
    [self postDecreaseActivityNotification];
}

#pragma mark Operation Generation
- (TICDSRemoveAllRemoteSyncDataOperation *)removeAllSyncDataOperation
{
    return [[TICDSRemoveAllRemoteSyncDataOperation alloc] initWithDelegate:self];
}

#pragma mark Operation Communication
- (void)removeAllSyncDataOperationWillRemoveAllSyncData:(TICDSRemoveAllRemoteSyncDataOperation *)anOperation
{
    // suspend other tasks queue now that this task has started
    // this matches default initial AppSyncManager behavior of suspending all queues except registration
    [[self otherTasksQueue] setSuspended:YES];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Remove all sync data operation will remove all sync data");
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerWillRemoveAllSyncData:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManagerWillRemoveAllSyncData:self];
        }];
    }
}

- (void)removeAllSyncDataOperationDidRemoveAllSyncData:(TICDSRemoveAllRemoteSyncDataOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Remove all sync data operation did remove all sync data");
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManagerDidFinishRemovingAllSyncData:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManagerDidFinishRemovingAllSyncData:self];
        }];
    }
}

- (void)removeAllSyncDataOperationCompleted:(TICDSRemoveAllRemoteSyncDataOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Remove All Sync Data Operation Completed");
    
    [self postDecreaseActivityNotification];
}

- (void)removeAllSyncDataOperationWasCancelled:(TICDSRemoveAllRemoteSyncDataOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Remove All Sync Data Operation was Cancelled");
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToRemoveAllSyncDataWithError:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToRemoveAllSyncDataWithError:[TICDSError errorWithCode:TICDSErrorCodeTaskWasCancelled classAndMethod:__PRETTY_FUNCTION__]];
        }];
    }
    [self postDecreaseActivityNotification];
}

- (void)removeAllSyncDataOperation:(TICDSRemoveAllRemoteSyncDataOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Remove All Sync Data Operation Failed to Complete with Error: %@", anError);
    
    if ([self ti_delegateRespondsToSelector:@selector(applicationSyncManager:didFailToRemoveAllSyncDataWithError:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
            [(id)self.delegate applicationSyncManager:self didFailToRemoveAllSyncDataWithError:anError];
        }];
    }
    [self postDecreaseActivityNotification];
}

#pragma mark - OPERATION COMMUNICATIONS
- (void)operationCompletedSuccessfully:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSApplicationRegistrationOperation class]] ) {
        [self applicationRegistrationOperationCompleted:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSListOfPreviouslySynchronizedDocumentsOperation class]] ) {
        [self listOfDocumentsOperationCompleted:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreDownloadOperation class]] ) {
        [self documentDownloadOperationCompleted:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSListOfApplicationRegisteredClientsOperation class]] ) {
        [self registeredClientsOperationCompleted:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSDocumentDeletionOperation class]] ) {
        [self documentDeletionOperationCompleted:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSRemoveAllRemoteSyncDataOperation class]] ) {
        [self removeAllSyncDataOperationCompleted:(id)anOperation];
    }
}

- (void)operationWasCancelled:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSApplicationRegistrationOperation class]] ) {
        [self applicationRegistrationOperationWasCancelled:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSListOfPreviouslySynchronizedDocumentsOperation class]] ) {
        [self listOfDocumentsOperationWasCancelled:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreDownloadOperation class]] ) {
        [self documentDownloadOperationWasCancelled:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSListOfApplicationRegisteredClientsOperation class]] ) {
        [self registeredClientsOperationWasCancelled:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSDocumentDeletionOperation class]] ) {
        [self documentDeletionOperationWasCancelled:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSRemoveAllRemoteSyncDataOperation class]] ) {
        [self removeAllSyncDataOperationWasCancelled:(id)anOperation];
    }
}

- (void)operationFailedToComplete:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSApplicationRegistrationOperation class]] ) {
        [self applicationRegistrationOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    } else if( [anOperation isKindOfClass:[TICDSListOfPreviouslySynchronizedDocumentsOperation class]] ) {
        [self listOfDocumentsOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreDownloadOperation class]] ) {
        [self documentDownloadOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    } else if( [anOperation isKindOfClass:[TICDSListOfApplicationRegisteredClientsOperation class]] ) {
        [self registeredClientsOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    } else if( [anOperation isKindOfClass:[TICDSDocumentDeletionOperation class]] ) {
        [self documentDeletionOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    } else if( [anOperation isKindOfClass:[TICDSRemoveAllRemoteSyncDataOperation class]] ) {
        [self removeAllSyncDataOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    }
}

- (void)operationReportedProgress:(TICDSOperation *)anOperation
{
    // For now, only supporting progress reports on whole store movements, but could be extended to any operation
    if( [anOperation isKindOfClass:[TICDSWholeStoreDownloadOperation class]] ) {
        [self wholeStoreDownloadOperationReportedProgress:(id)anOperation];
    }
}

-(BOOL)operationShouldSupportProcessingInBackgroundState:(TICDSOperation *)anOperation;
{
    BOOL allowProcessInBackgroundState = NO;
    
    if (!self.shouldContinueProcessingInBackgroundState) {
        return allowProcessInBackgroundState;
    }
    
    if( [anOperation isKindOfClass:[TICDSApplicationRegistrationOperation class]] ) {
        allowProcessInBackgroundState = NO;
    } else if( [anOperation isKindOfClass:[TICDSListOfPreviouslySynchronizedDocumentsOperation class]] ) {
        allowProcessInBackgroundState = NO;
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreDownloadOperation class]] ) {
        allowProcessInBackgroundState = YES;
    } else if( [anOperation isKindOfClass:[TICDSListOfApplicationRegisteredClientsOperation class]] ) {
        allowProcessInBackgroundState = NO;
    } else if( [anOperation isKindOfClass:[TICDSDocumentDeletionOperation class]] ) {
        allowProcessInBackgroundState = NO;
    } else if( [anOperation isKindOfClass:[TICDSRemoveAllRemoteSyncDataOperation class]] ) {
        allowProcessInBackgroundState = NO;
    }
    return allowProcessInBackgroundState;
}

#pragma mark - Default Sync Manager
id __strong gTICDSDefaultApplicationSyncManager = nil;

+ (id)defaultApplicationSyncManager
{
    if( gTICDSDefaultApplicationSyncManager ) {
        return gTICDSDefaultApplicationSyncManager;
    }
    
    gTICDSDefaultApplicationSyncManager = [[self alloc] init];
    
    return gTICDSDefaultApplicationSyncManager;
}

+ (void)setDefaultApplicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager
{
    if( gTICDSDefaultApplicationSyncManager == aSyncManager ) {
        return;
    }
    
    gTICDSDefaultApplicationSyncManager = aSyncManager;
}

#pragma mark - Paths
- (NSString *)relativePathToEncryptionDirectory
{
    return TICDSEncryptionDirectoryName;
}

- (NSString *)relativePathToEncryptionDirectorySaltDataFilePath
{
    return [[self relativePathToEncryptionDirectory] stringByAppendingPathComponent:TICDSSaltFilenameWithExtension];
}

- (NSString *)relativePathToEncryptionDirectoryTestDataFilePath
{
    return [[self relativePathToEncryptionDirectory] stringByAppendingPathComponent:TICDSEncryptionTestFilenameWithExtension];
}

- (NSString *)relativePathToInformationDirectory
{
    return TICDSInformationDirectoryName;
}

- (NSString *)relativePathToInformationDeletedDocumentsDirectory
{
    return [[self relativePathToInformationDirectory] stringByAppendingPathComponent:TICDSDeletedDocumentsDirectoryName];
}

- (NSString *)relativePathToDocumentsDirectory
{
    return TICDSDocumentsDirectoryName;
}

- (NSString *)relativePathToClientDevicesDirectory
{
    return TICDSClientDevicesDirectoryName;
}

- (NSString *)relativePathToClientDevicesThisClientDeviceDirectory
{
    return [[self relativePathToClientDevicesDirectory] stringByAppendingPathComponent:[self clientIdentifier]];
}

- (NSString *)relativePathToDocumentDirectoryForDocumentWithIdentifier:(NSString *)anIdentifier
{
    return [[self relativePathToDocumentsDirectory] stringByAppendingPathComponent:anIdentifier];
}

- (NSString *)relativePathToWholeStoreDirectoryForDocumentWithIdentifier:(NSString *)anIdentifier
{
    return [[self relativePathToDocumentDirectoryForDocumentWithIdentifier:anIdentifier] stringByAppendingPathComponent:TICDSWholeStoreDirectoryName];
}

#pragma mark - Initialization and Deallocation
- (id)init
{
    self = [super init];
    if( !self ) {
        return nil;
    }
    
    // Create Registration Queue (ready to roll)
    _registrationQueue = [[NSOperationQueue alloc] init];
    
    // Create Other Tasks Queue (suspended until registration completes)
    _otherTasksQueue = [[NSOperationQueue alloc] init];
    [_otherTasksQueue setSuspended:YES];
    
    return self;
}

- (void)dealloc
{
    _appIdentifier = nil;
    _clientIdentifier = nil;
    _clientDescription = nil;
    _applicationUserInfo = nil;
    _registrationQueue = nil;
    _otherTasksQueue = nil;
    _fileManager = nil;

}

#pragma mark - Background State Support

- (void)beginBackgroundTask
{
#if TARGET_OS_IPHONE
    self.backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                                 [self endBackgroundTask];
                             }];
    TICDSLog(TICDSLogVerbosityEveryStep, @"App Sync Manager (%@), Task ID (%i) is begining.", [self class], self.backgroundTaskID);
#endif
}

- (void)endBackgroundTask
{
#if TARGET_OS_IPHONE
    if (self.backgroundTaskID == UIBackgroundTaskInvalid) {
        return;
    }

    switch ([[UIApplication sharedApplication] applicationState]) {
        case UIApplicationStateActive:  {
            TICDSLog(TICDSLogVerbosityEveryStep, @"App Sync Manager (%@), Task ID (%i) is ending while app state is Active", [self class], self.backgroundTaskID);
        }   break;
        case UIApplicationStateInactive:  {
            TICDSLog(TICDSLogVerbosityEveryStep, @"App Sync Manager (%@), Task ID (%i) is ending while app state is Inactive", [self class], self.backgroundTaskID);
        }   break;
        case UIApplicationStateBackground:  {
            TICDSLog(TICDSLogVerbosityEveryStep, @"App Sync Manager (%@), Task ID (%i) is ending while app state is Background with %.0f seconds remaining", [self class], self.backgroundTaskID, [[UIApplication sharedApplication] backgroundTimeRemaining]);
        }   break;
        default:
            break;
    }

    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskID];
    self.backgroundTaskID = UIBackgroundTaskInvalid;
#endif
}

- (void)cancelNonBackgroundStateOperations;
{
#if TARGET_OS_IPHONE
    @synchronized(self) {
        for (TICDSOperation *op in [self.registrationQueue operations]) {
            if (!op.shouldContinueProcessingInBackgroundState) {
                TICDSLog(TICDSLogVerbosityEveryStep,@"App Sync Manager is cancelling operation %@ (id:%i) because app has gone to background state.",[self class],self.backgroundTaskID);
                [op cancel];
            }
        }
        
        for (TICDSOperation *op in [self.otherTasksQueue operations]) {
            if (!op.shouldContinueProcessingInBackgroundState) {
                TICDSLog(TICDSLogVerbosityEveryStep,@"App Sync Manager is cancelling operation %@ (id:%i) because app has gone to background state.",[self class],self.backgroundTaskID);
                [op cancel];
            }
        }
    }
#endif
}

#pragma mark - Lazy Accessors
- (NSFileManager *)fileManager
{
    if( _fileManager ) return _fileManager;
    
    _fileManager = [[NSFileManager alloc] init];
    
    return _fileManager;
}

#pragma mark - Properties
@synthesize state = _state;
@synthesize shouldUseEncryption = _shouldUseEncryption;
@synthesize shouldUseCompressionForWholeStoreMoves = _shouldUseCompressionForWholeStoreMoves;
@synthesize delegate = _delegate;
@synthesize appIdentifier = _appIdentifier;
@synthesize clientIdentifier = _clientIdentifier;
@synthesize clientDescription = _clientDescription;
@synthesize applicationUserInfo = _applicationUserInfo;
@synthesize registrationQueue = _registrationQueue;
@synthesize otherTasksQueue = _otherTasksQueue;
@synthesize fileManager = _fileManager;
#if TARGET_OS_IPHONE
@synthesize backgroundTaskID = _backgroundTaskID;
#endif
@synthesize shouldContinueProcessingInBackgroundState = _shouldContinueProcessingInBackgroundState;

@end
