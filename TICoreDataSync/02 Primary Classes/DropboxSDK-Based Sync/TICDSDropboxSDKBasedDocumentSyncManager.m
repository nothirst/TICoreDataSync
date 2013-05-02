//
//  TICDSDropboxSDKBasedDocumentSyncManager.m
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICoreDataSync.h"

#if TARGET_OS_IPHONE
#import <DropboxSDK/DropboxSDK.h>
#else
#import <DropboxSDK/DropboxOSX.h>
#endif

@interface TICDSDropboxSDKBasedDocumentSyncManager () <DBRestClientDelegate>

@property NSTimer *remotePollingTimer;
@property (nonatomic) DBRestClient *restClient;
@property (copy) NSString *deltaCursor;
@property BOOL initialCallToDelta;

@end


@implementation TICDSDropboxSDKBasedDocumentSyncManager

#pragma mark - Registration
- (void)registerWithDelegate:(id<TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager managedObjectContext:(NSManagedObjectContext *)aContext documentIdentifier:(NSString *)aDocumentIdentifier description:(NSString *)aDocumentDescription userInfo:(NSDictionary *)someUserInfo
{
    if( [anAppSyncManager isKindOfClass:[TICDSDropboxSDKBasedApplicationSyncManager class]] ) {
        [self setApplicationDirectoryPath:[(TICDSDropboxSDKBasedApplicationSyncManager *)anAppSyncManager applicationDirectoryPath]];
    }
    
    [super registerWithDelegate:aDelegate appSyncManager:anAppSyncManager managedObjectContext:aContext documentIdentifier:aDocumentIdentifier description:aDocumentDescription userInfo:someUserInfo];
}

- (void)registerConfiguredDocumentSyncManager
{
    if( [[self applicationSyncManager] isKindOfClass:[TICDSDropboxSDKBasedApplicationSyncManager class]] ) {
        [self setApplicationDirectoryPath:[(TICDSDropboxSDKBasedApplicationSyncManager *)[self applicationSyncManager] applicationDirectoryPath]];
    }
    
    [super registerConfiguredDocumentSyncManager];
}

#pragma mark - Remote Polling Methods

- (void)beginPollingRemoteStorageForChanges
{
    [self pollRemoteStorage:nil];
}

- (void)stopPollingRemoteStorageForChanges
{
    [self.remotePollingTimer invalidate];
    self.remotePollingTimer = nil;
}

- (void)pollRemoteStorage:(NSTimer *)timer
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif

    [self.restClient loadDelta:self.deltaCursor];
}

#pragma mark - DBRestClientDelegate methods

- (void)restClient:(DBRestClient*)client loadedDeltaEntries:(NSArray *)entries reset:(BOOL)shouldReset cursor:(NSString *)cursor hasMore:(BOOL)hasMore
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Processing a response from the polling call. %ld changed files with %@ to load.", (long)[entries count], (hasMore? @"more":@"no more"));

#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    self.deltaCursor = cursor;

    if (shouldReset) {
        self.initialCallToDelta = YES;
    }
    
    if (hasMore && self.initialCallToDelta) {
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
        [self.restClient loadDelta:self.deltaCursor];
        return;
    }
    
    self.initialCallToDelta = NO;

    NSString *lowercaseDocumentDirectoryPath = [self.thisDocumentDirectoryPath lowercaseString];
    NSString *lowercaseClientIdentifier = [self.clientIdentifier lowercaseString];
    NSString *lowercaseRecentSyncsDirectoryName = [TICDSRecentSyncsDirectoryName lowercaseString];
    for (DBDeltaEntry *entry in entries) {
        if ([entry.lowercasePath hasPrefix:lowercaseDocumentDirectoryPath]) {
            if ([entry.lowercasePath rangeOfString:lowercaseClientIdentifier].location != NSNotFound) {
                TICDSLog(TICDSLogVerbosityEveryStep, @"Processing a response from the polling call, skipping changes made by this client.");
                continue;
            }
            
            if ([entry.lowercasePath rangeOfString:lowercaseRecentSyncsDirectoryName].location != NSNotFound) {
                TICDSLog(TICDSLogVerbosityEveryStep, @"Processing a response from the polling call, skipping changes to the recent syncs directory made by other clients.");
                continue;
            }
            
            TICDSLog(TICDSLogVerbosityEveryStep, @"Found changes to %@ during polling, kicking off a sync", entry.lowercasePath);
            self.remotePollingTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(pollRemoteStorage:) userInfo:nil repeats:NO];
            [self initiateSynchronization];
            return;
        }
    }
    
    if (hasMore) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"REST client indicated more changes available during polling call");
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
        [self.restClient loadDelta:self.deltaCursor];
    }

    self.remotePollingTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(pollRemoteStorage:) userInfo:nil repeats:NO];
}

- (void)restClient:(DBRestClient*)client loadDeltaFailedWithError:(NSError *)error
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error while polling: %@", error);

    if (error.code == 503) {
        NSNumber *retryAfterNumber = [error.userInfo valueForKey:@"Retry-After"];
        if (retryAfterNumber == nil) {
            self.remotePollingTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(pollRemoteStorage:) userInfo:nil repeats:NO];
            return;
        }

        self.remotePollingTimer = [NSTimer scheduledTimerWithTimeInterval:[retryAfterNumber doubleValue] target:self selector:@selector(pollRemoteStorage:) userInfo:nil repeats:NO];
    } else {
        self.remotePollingTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(pollRemoteStorage:) userInfo:nil repeats:NO];
    }
}

#pragma mark - Lazy Accessors

- (DBRestClient *)restClient
{
    if (_restClient == nil) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    
    return _restClient;
}

#pragma mark - Operation Classes
- (TICDSDocumentRegistrationOperation *)documentRegistrationOperation
{
    TICDSDropboxSDKBasedDocumentRegistrationOperation *operation = [[TICDSDropboxSDKBasedDocumentRegistrationOperation alloc] initWithDelegate:self];
    
    [operation setClientDevicesDirectoryPath:[self clientDevicesDirectoryPath]];
    [operation setThisDocumentDirectoryPath:[self thisDocumentDirectoryPath]];
    [operation setThisDocumentDeletedClientsDirectoryPath:[self thisDocumentDeletedClientsDirectoryPath]];
    [operation setDeletedDocumentsDirectoryIdentifierPlistFilePath:[self deletedDocumentsDirectoryIdentifierPlistFilePath]];
    [operation setThisDocumentSyncChangesThisClientDirectoryPath:[self thisDocumentSyncChangesThisClientDirectoryPath]];
    [operation setThisDocumentSyncCommandsThisClientDirectoryPath:[self thisDocumentSyncCommandsThisClientDirectoryPath]];
    
    return operation;
}

- (TICDSWholeStoreDownloadOperation *)wholeStoreDownloadOperation
{
    TICDSDropboxSDKBasedWholeStoreDownloadOperation *operation = [[TICDSDropboxSDKBasedWholeStoreDownloadOperation alloc] initWithDelegate:self];
    
    [operation setThisDocumentDirectoryPath:[self thisDocumentDirectoryPath]];
    [operation setThisDocumentWholeStoreDirectoryPath:[self thisDocumentWholeStoreDirectoryPath]];
    
    return operation;
}

- (TICDSWholeStoreUploadOperation *)wholeStoreUploadOperation
{
    TICDSDropboxSDKBasedWholeStoreUploadOperation *operation = [[TICDSDropboxSDKBasedWholeStoreUploadOperation alloc] initWithDelegate:self];
    
    [operation setThisDocumentTemporaryWholeStoreThisClientDirectoryPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]];
    [operation setThisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath:[self thisDocumentTemporaryWholeStoreFilePath]];
    [operation setThisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath:[self thisDocumentTemporaryAppliedSyncChangeSetsFilePath]];
    [operation setThisDocumentWholeStoreThisClientDirectoryPath:[self thisDocumentWholeStoreThisClientDirectoryPath]];
    
    return operation;
}

- (TICDSPreSynchronizationOperation *)preSynchronizationOperation
{
    TICDSDropboxSDKBasedPreSynchronizationOperation *operation = [[TICDSDropboxSDKBasedPreSynchronizationOperation alloc] initWithDelegate:self];
    
    [operation setThisDocumentDirectoryPath:[self thisDocumentDirectoryPath]];
    [operation setThisDocumentSyncChangesDirectoryPath:[self thisDocumentSyncChangesDirectoryPath]];
    
    return operation;
}

- (TICDSPostSynchronizationOperation *)postSynchronizationOperation
{
    TICDSDropboxSDKBasedPostSynchronizationOperation *operation = [[TICDSDropboxSDKBasedPostSynchronizationOperation alloc] initWithDelegate:self];
    
    [operation setThisDocumentSyncChangesDirectoryPath:[self thisDocumentSyncChangesDirectoryPath]];
    [operation setThisDocumentSyncChangesThisClientDirectoryPath:[self thisDocumentSyncChangesThisClientDirectoryPath]];
    [operation setThisDocumentRecentSyncsThisClientFilePath:[self thisDocumentRecentSyncsThisClientFilePath]];
    
    return operation;
}

- (TICDSVacuumOperation *)vacuumOperation
{
    TICDSDropboxSDKBasedVacuumOperation *operation = [[TICDSDropboxSDKBasedVacuumOperation alloc] initWithDelegate:self];
    
    [operation setThisDocumentWholeStoreDirectoryPath:[self thisDocumentWholeStoreDirectoryPath]];
    [operation setThisDocumentRecentSyncsDirectoryPath:[self thisDocumentRecentSyncsDirectoryPath]];
    [operation setThisDocumentSyncChangesThisClientDirectoryPath:[self thisDocumentSyncChangesThisClientDirectoryPath]];
    
    return operation;
}

- (TICDSListOfDocumentRegisteredClientsOperation *)listOfDocumentRegisteredClientsOperation
{
    TICDSDropboxSDKBasedListOfDocumentRegisteredClientsOperation *operation = [[TICDSDropboxSDKBasedListOfDocumentRegisteredClientsOperation alloc] initWithDelegate:self];
    
    [operation setThisDocumentSyncChangesDirectoryPath:[self thisDocumentSyncChangesDirectoryPath]];
    [operation setClientDevicesDirectoryPath:[self clientDevicesDirectoryPath]];
    [operation setThisDocumentRecentSyncsDirectoryPath:[self thisDocumentRecentSyncsDirectoryPath]];
    [operation setThisDocumentWholeStoreDirectoryPath:[self thisDocumentWholeStoreDirectoryPath]];
    
    return operation;
}

- (TICDSDocumentClientDeletionOperation *)documentClientDeletionOperation
{
    TICDSDropboxSDKBasedDocumentClientDeletionOperation *operation = [[TICDSDropboxSDKBasedDocumentClientDeletionOperation alloc] initWithDelegate:self];
    
    [operation setClientDevicesDirectoryPath:[self clientDevicesDirectoryPath]];
    [operation setThisDocumentDeletedClientsDirectoryPath:[self thisDocumentDeletedClientsDirectoryPath]];
    [operation setThisDocumentSyncChangesDirectoryPath:[self thisDocumentSyncChangesDirectoryPath]];
    [operation setThisDocumentSyncCommandsDirectoryPath:[self thisDocumentSyncCommandsDirectoryPath]];
    [operation setThisDocumentRecentSyncsDirectoryPath:[self thisDocumentRecentSyncsDirectoryPath]];
    [operation setThisDocumentWholeStoreDirectoryPath:[self thisDocumentWholeStoreDirectoryPath]];
    
    return operation;
}

#pragma mark - Paths
- (NSString *)clientDevicesDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToClientDevicesDirectory]];
}

- (NSString *)deletedDocumentsDirectoryIdentifierPlistFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToDeletedDocumentsThisDocumentIdentifierPlistFile]];
}

- (NSString *)documentsDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToDocumentsDirectory]];
}

- (NSString *)thisDocumentDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentDirectory]];
}

- (NSString *)thisDocumentDeletedClientsDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentDeletedClientsDirectory]];
}

- (NSString *)thisDocumentSyncChangesDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentSyncChangesDirectory]];
}

- (NSString *)thisDocumentSyncChangesThisClientDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentSyncChangesThisClientDirectory]];
}

- (NSString *)thisDocumentSyncCommandsDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentSyncCommandsDirectory]];
}

- (NSString *)thisDocumentSyncCommandsThisClientDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentSyncCommandsThisClientDirectory]];
}

- (NSString *)thisDocumentTemporaryWholeStoreThisClientDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentTemporaryWholeStoreThisClientDirectory]];
}

- (NSString *)thisDocumentTemporaryWholeStoreFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFile]];
}

- (NSString *)thisDocumentTemporaryAppliedSyncChangeSetsFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFile]];
}

- (NSString *)thisDocumentWholeStoreDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentWholeStoreDirectory]];
}

- (NSString *)thisDocumentWholeStoreThisClientDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentWholeStoreThisClientDirectory]];
}

- (NSString *)thisDocumentWholeStoreFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentWholeStoreThisClientDirectoryWholeStoreFile]];
}

- (NSString *)thisDocumentAppliedSyncChangeSetsFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFile]];
}

- (NSString *)thisDocumentRecentSyncsDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentRecentSyncsDirectory]];
}

- (NSString *)thisDocumentRecentSyncsThisClientFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToThisDocumentRecentSyncsDirectoryThisClientFile]];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _applicationDirectoryPath = nil;

}

#pragma mark - Lazy Accessors

#pragma mark - Properties
@synthesize applicationDirectoryPath = _applicationDirectoryPath;

@end

