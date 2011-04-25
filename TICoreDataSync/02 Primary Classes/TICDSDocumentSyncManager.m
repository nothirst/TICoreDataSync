//
//  TICDSDocumentSyncManager.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSDocumentSyncManager ()

- (BOOL)startDocumentRegistrationProcess:(NSError **)outError;
- (void)bailFromRegistrationProcess;
- (BOOL)checkForHelperFileDirectoryOrCreateIfNecessary:(NSError **)outError;
- (void)startWholeStoreUploadProcess;
- (void)bailFromUploadProcess;

@property (nonatomic, retain) NSString *documentIdentifier;
@property (nonatomic, retain) NSString *documentDescription;
@property (nonatomic, retain) NSString *clientIdentifier;
@property (nonatomic, retain) NSDictionary *userInfo;
@property (retain) NSURL *helperFileDirectoryLocation;

@end

@implementation TICDSDocumentSyncManager

#pragma mark -
#pragma mark REGISTRATION
- (void)registerWithDelegate:(id <TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager managedObjectContext:(TICDSSynchronizedManagedObjectContext *)aContext documentIdentifier:(NSString *)aDocumentIdentifier description:(NSString *)aDocumentDescription userInfo:(NSDictionary *)someUserInfo
{
    [self setState:TICDSDocumentSyncManagerStateRegistering];
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting to register document sync manager");
    
    [self setPrimaryDocumentMOC:aContext];
    [aContext setDocumentSyncManager:self];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Registration Information:\n   Delegate: %@,\n   App Sync Manager: %@,\n   Document ID: %@,\n   Description: %@,\n   User Info: %@", aDelegate, anAppSyncManager, aDocumentIdentifier, aDocumentDescription, someUserInfo);
    [self setDelegate:aDelegate];
    [self setApplicationSyncManager:anAppSyncManager];
    [self setDocumentIdentifier:aDocumentIdentifier];
    [self setDocumentDescription:aDocumentDescription];
    [self setClientIdentifier:[anAppSyncManager clientIdentifier]];
    [self setUserInfo:someUserInfo];
    
    if( [anAppSyncManager state] == TICDSApplicationSyncManagerStateAbleToSync ) {
        [[self registrationQueue] setSuspended:NO];
    } else { 
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appSyncManagerDidRegister:) name:TICDSApplicationSyncManagerDidRegisterSuccessfullyNotification object:anAppSyncManager];
    }
    
    // get the location of the helper file directory from the delegate, or create default location if necessary
    NSError *anyError;
    BOOL shouldContinue = [self checkForHelperFileDirectoryOrCreateIfNecessary:&anyError];
    
    if( !shouldContinue ) {
        [self ti_alertDelegateWithSelector:@selector(syncManager:encounteredDocumentRegistrationError:), anyError];
        [self bailFromRegistrationProcess];
        return;
    }
    
    shouldContinue = [self startDocumentRegistrationProcess:&anyError];
    if( !shouldContinue ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error registering: %@", anyError);
        [self ti_alertDelegateWithSelector:@selector(syncManager:encounteredDocumentRegistrationError:), anyError];
        [self bailFromRegistrationProcess];
        return;
    }
    
    [self ti_alertDelegateWithSelector:@selector(syncManagerDidStartDocumentRegistration:)];
}

- (void)bailFromRegistrationProcess
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from registration process");
    [self ti_alertDelegateWithSelector:@selector(syncManagerFailedToRegisterDocument:)];
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
    
    [operation setDocumentIdentifier:[self documentIdentifier]];
    [operation setClientIdentifier:[self clientIdentifier]];
    [operation setClientDescription:[[self applicationSyncManager] clientDescription]];
    [operation setDocumentDescription:[self documentDescription]];
    [operation setUserInfo:[self userInfo]];
    
    [[self registrationQueue] addOperation:operation];
    
    return YES;
}

#pragma mark Asking if Should Create Remote Document File Structure
- (void)registrationOperationPausedToFindOutWhetherToCreateRemoteDocumentStructure:(TICDSDocumentRegistrationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Registration operation paused to find out whether to create document structure");
    [self ti_alertDelegateWithSelector:@selector(syncManager:didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:description:userInfo:), [self documentIdentifier], [self documentDescription], [self userInfo]];
}

- (void)registrationOperationResumedFollowingDocumentStructureCreationInstruction:(TICDSDocumentRegistrationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Registration operation resumed after finding out whether to create document structure");
    [self ti_alertDelegateWithSelector:@selector(syncManagerDidResumeRegistration:)];
}


- (void)continueRegistrationByCreatingRemoteFileStructure:(BOOL)shouldCreateFileStructure
{
    // Just start the sync operation again
    [(TICDSDocumentRegistrationOperation *)[[[self registrationQueue] operations] lastObject] setShouldCreateDocumentFileStructure:shouldCreateFileStructure];
    [(TICDSDocumentRegistrationOperation *)[[[self registrationQueue] operations] lastObject] setPaused:NO];
}

#pragma mark Operation Generation
- (TICDSDocumentRegistrationOperation *)documentRegistrationOperation
{
    return [[[TICDSDocumentRegistrationOperation alloc] initWithDelegate:self] autorelease];
}

#pragma mark Operation Communications
- (void)documentRegistrationOperationCompleted:(TICDSDocumentRegistrationOperation *)anOperation
{
    // Primary Registration Complete from Operation
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Document Registration Operation Completed");
    
    // setup the syncChangesMOC
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating SyncChangesMOC");
    [self setSyncChangesMOC:[[self coreDataFactory] managedObjectContext]];
    if( ![self syncChangesMOC] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create sync changes MOC");
        [self bailFromRegistrationProcess];
        return;
    }
    TICDSLog(TICDSLogVerbosityEveryStep, @"Finished creating SyncChangesMOC");
    
    [self setState:TICDSDocumentSyncManagerStateAbleToSync];
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Finished registering document sync manager");
    
    // Registration Complete
    [self ti_alertDelegateWithSelector:@selector(syncManagerDidRegisterDocumentSuccessfully:)];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Resuming Operation Queues");
    [[self synchronizationQueue] setSuspended:NO];
    [[self otherTasksQueue] setSuspended:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TICDSDocumentSyncManagerDidRegisterSuccessfullyNotification object:self];
    
    // Upload whole store if necessary
    TICDSLog(TICDSLogVerbosityEveryStep, @"Asking delegate whether to upload whole store after registration");
    if( [self ti_boolFromDelegateWithSelector:@selector(syncManagerShouldUploadWholeStoreAfterDocumentRegistration:)] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Delegate allowed whole store upload after registration");
        [self startWholeStoreUploadProcess];
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Delegate denied whole store upload after registration");
    }
}

- (void)documentRegistrationOperationWasCancelled:(TICDSDocumentRegistrationOperation *)anOperation
{
    [self setState:TICDSDocumentSyncManagerStateNotYetRegistered];
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Document Registration Operation was Cancelled");
    
    [self ti_alertDelegateWithSelector:@selector(syncManagerFailedToRegisterDocument:)];
}

- (void)documentRegistrationOperation:(TICDSDocumentRegistrationOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    [self setState:TICDSDocumentSyncManagerStateNotYetRegistered];
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Document Registration Operation Failed to Complete with Error: %@", anError);
    [self ti_alertDelegateWithSelector:@selector(syncManager:encounteredDocumentRegistrationError:), anError];
    [self ti_alertDelegateWithSelector:@selector(syncManagerFailedToRegisterDocument:)];
}

#pragma mark -
#pragma mark HELPER FILE DIRECTORY
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
    
    NSString *unappliedSyncChangesPath = [[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:TICDSUnappliedChangesDirectoryName];
    if( ![[self fileManager] fileExistsAtPath:unappliedSyncChangesPath] ) {
        BOOL success = [[self fileManager] createDirectoryAtPath:unappliedSyncChangesPath withIntermediateDirectories:YES attributes:nil error:&anyError];
        if( !success ) {
            if( outError ) {
                *outError = [TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__];
            }
            return NO;
        }
    }
    
    NSString *syncChangesToPushPath = [[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:TICDSSyncChangesToPushDirectoryName];
    if( ![[self fileManager] fileExistsAtPath:syncChangesToPushPath] ) {
        BOOL success = [[self fileManager] createDirectoryAtPath:syncChangesToPushPath withIntermediateDirectories:YES attributes:nil error:&anyError];
        if( !success ) {
            if( outError ) {
                *outError = [TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__];
            }
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)checkForHelperFileDirectoryOrCreateIfNecessary:(NSError **)outError
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Asking delegate for location of helper file directory");
    NSURL *finalURL = [self ti_objectFromDelegateWithSelector:@selector(syncManager:helperFileDirectoryLocationForDocumentWithIdentifier:description:userInfo:), [self documentIdentifier], [self documentDescription], [self userInfo]];
    
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
#pragma mark WHOLE STORE UPLOAD
- (void)initiateUploadOfWholeStore
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Manual initiation of whole store upload");
    
    [self startWholeStoreUploadProcess];
}

- (void)bailFromUploadProcess
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from whole store upload process");
    [self ti_alertDelegateWithSelector:@selector(syncManagerFailedToUploadWholeStore:)];
}

- (void)startWholeStoreUploadProcess
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting whole store upload process");
    [self ti_alertDelegateWithSelector:@selector(syncManagerDidBeginToUploadWholeStore:)];
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Asking delegate for URL of whole store to upload");
    NSURL *storeURL = [self ti_objectFromDelegateWithSelector:@selector(syncManager:URLForWholeStoreToUploadForDocumentWithIdentifier:description:userInfo:), [self documentIdentifier], [self documentDescription], [self userInfo]];
    
    if( !storeURL || ![[self fileManager] fileExistsAtPath:[storeURL path]] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Store does not exist at provided path");
        [self ti_alertDelegateWithSelector:@selector(syncManager:encounteredWholeStoreUploadError:), [TICDSError errorWithCode:TICDSErrorCodeUnexpectedOrIncompleteFileLocationOrDirectoryStructure classAndMethod:__PRETTY_FUNCTION__]];

        [self bailFromUploadProcess];
        return;
    }
    
    TICDSWholeStoreUploadOperation *operation = [self wholeStoreUploadOperation];
    
    if( !operation ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create whole store operation object");
        [self ti_alertDelegateWithSelector:@selector(syncManager:encounteredWholeStoreUploadError:), [TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__]];
        
        [self bailFromUploadProcess];
        return;
    }
    
    
    
    [[self otherTasksQueue] addOperation:operation];
}

#pragma mark Operation Generation
- (TICDSWholeStoreUploadOperation *)wholeStoreUploadOperation
{
    return [[[TICDSWholeStoreUploadOperation alloc] initWithDelegate:self] autorelease];
}

#pragma mark Operation Communications
- (void)wholeStoreUploadOperationCompleted:(TICDSWholeStoreUploadOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Whole Store Upload Operation Completed");
    
    [self ti_alertDelegateWithSelector:@selector(syncManagerDidUploadWholeStoreSuccessfully:)];
}

- (void)wholeStoreUploadOperationWasCancelled:(TICDSWholeStoreUploadOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Whole Store Upload Operation was Cancelled");
    
    [self ti_alertDelegateWithSelector:@selector(syncManagerFailedToUploadWholeStore:)];
}

- (void)wholeStoreUploadOperation:(TICDSDocumentRegistrationOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Whole Store Upload Operation Failed to Complete with Error: %@", anError);
    [self ti_alertDelegateWithSelector:@selector(syncManager:encounteredWholeStoreUploadError:), anError];
    [self ti_alertDelegateWithSelector:@selector(syncManagerFailedToUploadWholeStore:)];
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
    [self ti_alertDelegateWithSelector:@selector(syncManager:didBeginProcessingAfterMOCDidSave:), aMoc];
    
    NSError *anyError = nil;
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Sync Manager will save Sync Changes context");
    
    BOOL success = [[self syncChangesMOC] save:&anyError];
    
    if( !success ) {
        NSError *ticdsError = [TICDSError errorWithCode:TICDSErrorCodeFailedToSaveSyncChangesMOC underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__];
        [self ti_alertDelegateWithSelector:@selector(syncManager:encounteredSynchronizationError:), ticdsError];
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Sync Manager failed to save Sync Changes context with error: %@", anyError);
        
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Sync Manager cannot continue processing any further, so bailing");
        [self ti_alertDelegateWithSelector:@selector(syncManager:failedToProcessAfterMOCDidSave:), aMoc];
        
        return;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Sync Manager saved Sync Changes context successfully");
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Asking delegate if we should sync after saving");
    BOOL shouldSync = [self ti_boolFromDelegateWithSelector:@selector(syncManagerShouldInitiateSynchronizationAfterSave:)];
    if( !shouldSync ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Delegate denied synchronization after saving");
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Delegate allowed synchronization after saving");
    [self initiateSynchronization];
}

- (void)synchronizedMOCFailedToSave:(TICDSSynchronizedManagedObjectContext *)aMoc withError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Synchronized context failed to save with error: %@", anError);
}

#pragma mark -
#pragma mark NOTIFICATIONS
- (void)appSyncManagerDidRegister:(NSNotification *)aNotification
{
    [[self registrationQueue] setSuspended:NO];
}

#pragma mark -
#pragma mark OPERATION COMMUNICATIONS
- (void)operationCompletedSuccessfully:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSDocumentRegistrationOperation class]] ) {
        [self documentRegistrationOperationCompleted:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreUploadOperation class]] ) {
        [self wholeStoreUploadOperationCompleted:(id)anOperation];
    }
}

- (void)operationWasCancelled:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSDocumentRegistrationOperation class]] ) {
        [self documentRegistrationOperationWasCancelled:(id)anOperation];
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreUploadOperation class]] ) {
        [self wholeStoreUploadOperationWasCancelled:(id)anOperation];
    }
}

- (void)operationFailedToComplete:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSDocumentRegistrationOperation class]] ) {
        [self documentRegistrationOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    } else if( [anOperation isKindOfClass:[TICDSWholeStoreUploadOperation class]] ) {
        [self wholeStoreUploadOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
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
    
    // Create Registration Queue (suspended, but unsuspended if App Sync Man is registered when registerWithDelegate:... is called)
    _registrationQueue = [[NSOperationQueue alloc] init];
    [_registrationQueue setSuspended:YES];
    
    // Create Other Queues (suspended until registration completes)
    _synchronizationQueue = [[NSOperationQueue alloc] init];
    [_synchronizationQueue setSuspended:YES];
    [_synchronizationQueue setMaxConcurrentOperationCount:1];
    
    _otherTasksQueue = [[NSOperationQueue alloc] init];
    [_otherTasksQueue setSuspended:YES];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_applicationSyncManager release], _applicationSyncManager = nil;
    [_documentIdentifier release], _documentIdentifier = nil;
    [_clientIdentifier release], _clientIdentifier = nil;
    [_userInfo release], _userInfo = nil;
    [_fileManager release], _fileManager = nil;
    [_helperFileDirectoryLocation release], _helperFileDirectoryLocation = nil;
    [_primaryDocumentMOC release], _primaryDocumentMOC = nil;
    [_syncChangesMOC release], _syncChangesMOC = nil;
    [_coreDataFactory release], _coreDataFactory = nil;
    [_registrationQueue release], _registrationQueue = nil;
    [_synchronizationQueue release], _synchronizationQueue = nil;
    [_otherTasksQueue release], _otherTasksQueue = nil;
    
    [super dealloc];
}

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
    [_coreDataFactory setPersistentStoreDataPath:[self unsynchronizedSyncChangesStorePath]];
    
    return _coreDataFactory;
}

#pragma mark -
#pragma mark Paths

- (NSString *)relativePathToDocumentsDirectory
{
    return TICDSDocumentsDirectoryName; 
}

- (NSString *)relativePathToThisDocumentDirectory
{
    return [[self relativePathToDocumentsDirectory] stringByAppendingPathComponent:[self documentIdentifier]];
}

- (NSString *)relativePathToThisDocumentSyncChangesDirectory
{
    return [[self relativePathToThisDocumentDirectory] stringByAppendingPathComponent:TICDSSyncChangesDirectoryName];
}

- (NSString *)relativePathToThisDocumentSyncChangesThisClientDirectory
{
    return [[self relativePathToThisDocumentSyncChangesDirectory] stringByAppendingPathComponent:[self clientIdentifier]];
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

- (NSString *)unsynchronizedSyncChangesStorePath
{
    return [[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:TICDSUnsynchronizedSyncChangesStoreName];
}

#pragma mark -
#pragma mark Properties
@synthesize delegate = _delegate;
@synthesize state = _state;
@synthesize applicationSyncManager = _applicationSyncManager;
@synthesize documentIdentifier = _documentIdentifier;
@synthesize documentDescription = _documentDescription;
@synthesize clientIdentifier = _clientIdentifier;
@synthesize userInfo = _userInfo;
@synthesize fileManager = _fileManager;
@synthesize helperFileDirectoryLocation = _helperFileDirectoryLocation;
@synthesize primaryDocumentMOC = _primaryDocumentMOC;
@synthesize coreDataFactory = _coreDataFactory;
@synthesize syncChangesMOC = _syncChangesMOC;
@synthesize registrationQueue = _registrationQueue;
@synthesize synchronizationQueue = _synchronizationQueue;
@synthesize otherTasksQueue = _otherTasksQueue;

@end
