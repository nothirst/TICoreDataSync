//
//  TICDSDocumentSyncManager.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentSyncManager.h"
#import "TICoreDataSync.h"

@interface TICDSDocumentSyncManager ()

- (BOOL)startDocumentRegistrationProcess:(NSError **)outError;
- (void)bailFromRegistrationProcess;
- (BOOL)checkForHelperFileDirectoryOrCreateIfNecessary:(NSError **)outError;

@property (nonatomic, retain) NSString *documentIdentifier;
@property (nonatomic, retain) NSString *documentDescription;
@property (nonatomic, retain) NSString *clientIdentifier;
@property (nonatomic, retain) NSDictionary *userInfo;
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
    [self setClientIdentifier:[anAppSyncManager clientDescription]];
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
    
    /*// setup the syncChangesMOC
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating SyncChangesMOC");
    [self setSyncChangesMOC:[[self coreDataFactory] managedObjectContext]];
    if( ![self syncChangesMOC] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create sync changes MOC");
        [self ti_alertDelegateWithSelector:@selector(syncManagerFailedToRegisterDocument:)];
        
        [self bailFromRegistrationProcess];
        return;
    }
    TICDSLog(TICDSLogVerbosityEveryStep, @"Finished creating SyncChangesMOC");
    */
    [self setState:TICDSDocumentSyncManagerStateAbleToSync];
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Finished registering document sync manager");
    
    // Registration Complete
    [self ti_alertDelegateWithSelector:@selector(syncManagerDidRegisterDocumentSuccessfully:)];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Resuming Operation Queues");
    [[self synchronizationQueue] setSuspended:NO];
    [[self otherTasksQueue] setSuspended:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TICDSDocumentSyncManagerDidRegisterSuccessfullyNotification object:self];
    
    /*
    // Upload whole store if necessary
    if( [anOperation documentHasBeenSynchronizedByThisClient] ) {
        [self uploadWholeStoreIfDelegateRequiresForPhase:TICDSShouldUploadEntireStorePhaseTypeRegistrationOfExistingDocument];
    } else if( [anOperation documentHasBeenSynchronizedByAnyClient] ) {
        [self uploadWholeStoreIfDelegateRequiresForPhase:TICDSShouldUploadEntireStorePhaseTypeInitialRegistrationOfThisDocumentByThisClientDevice];
    } else {
        [self uploadWholeStoreIfDelegateRequiresForPhase:TICDSShouldUploadEntireStorePhaseTypeInitialRegistrationOfThisDocumentByAnyClientDevice];
    }*/
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
    NSString *location = [[self applicationSupportDirectory] stringByAppendingPathComponent:@"Documents"];
    location = [location stringByAppendingPathComponent:[self documentIdentifier]];
    
    return [NSURL fileURLWithPath:location];
}

- (BOOL)createHelperFileDirectoryFileStructure:(NSError **)outError
{
    NSError *anyError = nil;
    
    NSString *unappliedSyncChangesPath = [[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:kTICDSUnappliedChangesDirectoryName];
    if( ![[self fileManager] fileExistsAtPath:unappliedSyncChangesPath] ) {
        BOOL success = [[self fileManager] createDirectoryAtPath:unappliedSyncChangesPath withIntermediateDirectories:YES attributes:nil error:&anyError];
        if( !success ) {
            if( outError ) {
                *outError = [TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__];
            }
            return NO;
        }
    }
    
    NSString *syncChangesToPushPath = [[[self helperFileDirectoryLocation] path] stringByAppendingPathComponent:kTICDSSyncChangesToPushDirectoryName];
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
    NSURL *finalURL = [self ti_objectFromDelegateWithSelector:@selector(syncManagerURLForDocumentHelperFileDirectory:)];
    
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
        TICDSLog(TICDSLogVerbosityEveryStep, @"Default helper file location exists, so using it: %@", [self helperFileDirectoryLocation]);
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
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Created default helper file directory: %@", [self helperFileDirectoryLocation]);
    
    return YES;
}

#pragma mark -
#pragma mark Notifications
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
    }
}

- (void)operationWasCancelled:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSDocumentRegistrationOperation class]] ) {
        [self documentRegistrationOperationWasCancelled:(id)anOperation];
    }
}

- (void)operationFailedToComplete:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSDocumentRegistrationOperation class]] ) {
        [self documentRegistrationOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    }
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
@synthesize syncChangesMOC = _syncChangesMOC;
@synthesize registrationQueue = _registrationQueue;
@synthesize synchronizationQueue = _synchronizationQueue;
@synthesize otherTasksQueue = _otherTasksQueue;

@end
