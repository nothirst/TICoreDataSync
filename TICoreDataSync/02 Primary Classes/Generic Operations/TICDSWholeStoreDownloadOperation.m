//
//  TICDSWholeStoreDownloadOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSWholeStoreDownloadOperation ()

- (void)beginCheckForMostRecentClientWholeStore;
- (void)beginDownloadOfWholeStoreFile;
- (void)beginDownloadOfAppliedSyncChangeSetsFile;
- (void)beginDownloadOfIntegrityKey;

@end


@implementation TICDSWholeStoreDownloadOperation

- (void)main
{
    if( [self requestedWholeStoreClientIdentifier] ) {
        [self beginDownloadOfWholeStoreFile];
    } else {
        [self beginCheckForMostRecentClientWholeStore];
    }
}

#pragma mark - Checking Most Recent Client Upload
- (void)beginCheckForMostRecentClientWholeStore
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking which client uploaded a store most recently");
    
    [self checkForMostRecentClientWholeStore];
}

- (void)determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:(NSString *)anIdentifier
{
    if( !anIdentifier ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to determine which client uploaded store most recently");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Client %@ uploaded store most recently", anIdentifier);
    [self setRequestedWholeStoreClientIdentifier:anIdentifier];
    
    [self beginDownloadOfWholeStoreFile];
}

#pragma mark Overriden Method
- (void)checkForMostRecentClientWholeStore
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:nil];
}

#pragma mark - Whole Store File Download
- (void)beginDownloadOfWholeStoreFile
{
    NSError *anyError = nil;
    if( [[self fileManager] fileExistsAtPath:[[self localWholeStoreFileLocation] path]] && ![[self fileManager] removeItemAtPath:[[self localWholeStoreFileLocation] path] error:&anyError] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete existing whole store");
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        
        [self downloadedWholeStoreFileWithSuccess:NO];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Downloading whole store file to %@", [self localWholeStoreFileLocation]);
    
    [self downloadWholeStoreFile];
}

-(void)downloadingWholeStoreFileMadeProgress;
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Downloading the WholeStore file to this client made progress %.2f",[self progress]);
    
    [self operationDidMakeProgress];
}

- (void)downloadedWholeStoreFileWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to download whole store file");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Successfully downloaded whole store file");
    
    [self beginDownloadOfAppliedSyncChangeSetsFile];
}

#pragma mark Overridden Method
- (void)downloadWholeStoreFile
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self downloadedWholeStoreFileWithSuccess:NO];
}

#pragma mark - Applied Sync Change Sets File Download
- (void)beginDownloadOfAppliedSyncChangeSetsFile
{
    NSError *anyError = nil;
    if( [[self fileManager] fileExistsAtPath:[[self localAppliedSyncChangeSetsFileLocation] path]] && ![[self fileManager] removeItemAtPath:[[self localAppliedSyncChangeSetsFileLocation] path] error:&anyError] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete existing applied sync changes");
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        
        [self downloadedAppliedSyncChangeSetsFileWithSuccess:NO];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Downloading applied sync change sets file to %@", [self localAppliedSyncChangeSetsFileLocation]);
    
    [self downloadAppliedSyncChangeSetsFile];
}

- (void)downloadingAppliedSyncChangeSetsFileMadeProgress;
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Downloading the AppliedSyncChanges file to this client made progress %.2f",[self progress]);
    
    [self operationDidMakeProgress];
}

- (void)downloadedAppliedSyncChangeSetsFileWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to download applied sync change sets file");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Successfully downloaded applied sync change sets file");
    [self beginDownloadOfIntegrityKey];
}

#pragma mark Overridden Method
- (void)downloadAppliedSyncChangeSetsFile
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self downloadedAppliedSyncChangeSetsFileWithSuccess:NO];
}

#pragma mark - Integrity Key
- (void)beginDownloadOfIntegrityKey
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Fetching remote integrity key for this store");
    
    [self fetchRemoteIntegrityKey];
}

- (void)fetchedRemoteIntegrityKey:(NSString *)aKey
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Fetched remote integrity key");
    [self setIntegrityKey:aKey];
    
    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Method
- (void)fetchRemoteIntegrityKey
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedRemoteIntegrityKey:nil];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _requestedWholeStoreClientIdentifier = nil;
    _localWholeStoreFileLocation = nil;
    _localAppliedSyncChangeSetsFileLocation = nil;
    _integrityKey = nil;

}

#pragma mark - Properties
@synthesize requestedWholeStoreClientIdentifier = _requestedWholeStoreClientIdentifier;
@synthesize localWholeStoreFileLocation = _localWholeStoreFileLocation;
@synthesize localAppliedSyncChangeSetsFileLocation = _localAppliedSyncChangeSetsFileLocation;
@synthesize integrityKey = _integrityKey;

@end
