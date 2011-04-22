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
- (void)bailFromRegistrationProcess;

@property (nonatomic, retain) NSString *appIdentifier;
@property (nonatomic, retain) NSString *clientIdentifier;
@property (nonatomic, retain) NSString *clientDescription;
@property (nonatomic, retain) NSDictionary *userInfo;

@end

@implementation TICDSApplicationSyncManager

#pragma mark -
#pragma mark REGISTRATION
- (void)registerWithDelegate:(id <TICDSApplicationSyncManagerDelegate>)aDelegate globalAppIdentifier:(NSString *)anAppIdentifier uniqueClientIdentifier:(NSString *)aClientIdentifier description:(NSString *)aClientDescription userInfo:(NSDictionary *)userInfo
{
    [self setState:TICDSApplicationSyncManagerStateRegistering];
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Starting to register application sync manager");
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Registration Information:\n   Delegate: %@,\n   Global App ID: %@,\n   Client ID: %@,\n   Description: %@\nUser Info: %@", aDelegate, anAppIdentifier, aClientIdentifier, aClientDescription, userInfo);
    
    [self setDelegate:aDelegate];
    [self setAppIdentifier:anAppIdentifier];
    [self setClientIdentifier:aClientIdentifier];
    [self setClientDescription:aClientDescription];
    [self setUserInfo:userInfo];
    
    NSError *anyError = nil;
    BOOL shouldContinue = [self startRegistrationProcess:&anyError];
    if( !shouldContinue ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error registering: %@", anyError);
        [self ti_alertDelegateWithSelector:@selector(syncManager:encounteredRegistrationError:), anyError];
        [self bailFromRegistrationProcess];
        return;
    }
    
    [self ti_alertDelegateWithSelector:@selector(syncManagerDidStartRegistration:)];
}

- (void)bailFromRegistrationProcess
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Bailing from application registration process");
    [self ti_alertDelegateWithSelector:@selector(syncManagerFailedToRegister:)];
}

- (BOOL)startRegistrationProcess:(NSError **)outError
{
    TICDSApplicationRegistrationOperation *operation = [self applicationRegistrationOperation];
    
    if( !operation ) {
        if( outError ) {
            *outError = [TICDSError errorWithCode:TICDSErrorCodeFailedToCreateOperationObject classAndMethod:__PRETTY_FUNCTION__];
        }
        
        return NO;
    }
    
    [operation setAppIdentifier:[self appIdentifier]];
    [operation setClientDescription:[self clientDescription]];
    [operation setClientIdentifier:[self clientIdentifier]];
    [operation setUserInfo:[self userInfo]];
    
    [[self registrationQueue] addOperation:operation];
    
    return YES;
}

#pragma mark Operation Generation
- (TICDSApplicationRegistrationOperation *)applicationRegistrationOperation
{
    return [[[TICDSApplicationRegistrationOperation alloc] initWithDelegate:self] autorelease];
}

#pragma mark Operation Communications
- (void)applicationRegistrationOperationCompleted:(TICDSApplicationRegistrationOperation *)anOperation
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Application Registration Operation Completed");
    
    [self setState:TICDSApplicationSyncManagerStateAbleToSync];
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainPhase, @"Finished registering application sync manager");
    
    // Registration Complete
    [self ti_alertDelegateWithSelector:@selector(syncManagerDidRegisterSuccessfully:)];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Resuming Operation Queues");
    [[self otherTasksQueue] setSuspended:NO];
}

- (void)applicationRegistrationOperationWasCancelled:(TICDSApplicationRegistrationOperation *)anOperation
{
    [self setState:TICDSApplicationSyncManagerStateNotYetRegistered];
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Application Registration Operation was Cancelled");
    
    [self ti_alertDelegateWithSelector:@selector(syncManagerFailedToRegister:)];
}

- (void)applicationRegistrationOperation:(TICDSApplicationRegistrationOperation *)anOperation failedToCompleteWithError:(NSError *)anError
{
    [self setState:TICDSApplicationSyncManagerStateNotYetRegistered];
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Application Registration Operation Failed to Complete with Error: %@", anError);
    [self ti_alertDelegateWithSelector:@selector(syncManager:encounteredRegistrationError:), anError];
    [self ti_alertDelegateWithSelector:@selector(syncManagerFailedToRegister:)];
}

#pragma mark -
#pragma mark OPERATION COMMUNICATIONS
- (void)operationCompletedSuccessfully:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSApplicationRegistrationOperation class]] ) {
        [self applicationRegistrationOperationCompleted:(id)anOperation];
    }
}

- (void)operationWasCancelled:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSApplicationRegistrationOperation class]] ) {
        [self applicationRegistrationOperationWasCancelled:(id)anOperation];
    }
}

- (void)operationFailedToComplete:(TICDSOperation *)anOperation
{
    if( [anOperation isKindOfClass:[TICDSApplicationRegistrationOperation class]] ) {
        [self applicationRegistrationOperation:(id)anOperation failedToCompleteWithError:[anOperation error]];
    }
}

#pragma mark -
#pragma mark Default Sync Manager
id gTICDSDefaultApplicationSyncManager = nil;

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
    
    [gTICDSDefaultApplicationSyncManager release];
    gTICDSDefaultApplicationSyncManager = [aSyncManager retain];
}

#pragma mark -
#pragma mark Relative Paths
- (NSString *)relativePathToClientDevicesDirectory
{
    return @"ClientDevices";
}

- (NSString *)relativePathToDocumentsDirectory
{
    return @"Documents";
}

- (NSString *)relativePathToThisClientDeviceDirectory
{
    return [[self relativePathToClientDevicesDirectory] stringByAppendingPathComponent:[self clientIdentifier]];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)init
{
    self = [super init];
    if( !self ) {
        return nil;
    }
    
    // Create Registration Queue (ready to roll)
    _registrationQueue = [[NSOperationQueue alloc] init];
    
    // Create Synchronization Queue (suspended until registration completes)
    _otherTasksQueue = [[NSOperationQueue alloc] init];
    [_otherTasksQueue setSuspended:YES];
    
    return self;
}

- (void)dealloc
{
    [_appIdentifier release], _appIdentifier = nil;
    [_clientIdentifier release], _clientIdentifier = nil;
    [_clientDescription release], _clientDescription = nil;
    [_userInfo release], _userInfo = nil;
    [_registrationQueue release], _registrationQueue = nil;
    [_otherTasksQueue release], _otherTasksQueue = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize state = _state;
@synthesize delegate = _delegate;
@synthesize appIdentifier = _appIdentifier;
@synthesize clientIdentifier = _clientIdentifier;
@synthesize clientDescription = _clientDescription;
@synthesize userInfo = _userInfo;
@synthesize registrationQueue = _registrationQueue;
@synthesize otherTasksQueue = _otherTasksQueue;

@end
