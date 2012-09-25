//
//  TICDSDropboxSDKBasedDocumentSyncManager.m
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICoreDataSync.h"


@implementation TICDSDropboxSDKBasedDocumentSyncManager

#pragma mark -
#pragma mark Registration
- (void)registerWithDelegate:(id<TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager managedObjectContext:(TICDSSynchronizedManagedObjectContext *)aContext documentIdentifier:(NSString *)aDocumentIdentifier description:(NSString *)aDocumentDescription userInfo:(NSDictionary *)someUserInfo
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

#pragma mark -
#pragma mark Operation Classes
- (TICDSDocumentRegistrationOperation *)documentRegistrationOperation
{
    TICDSDropboxSDKBasedDocumentRegistrationOperation *operation = [[TICDSDropboxSDKBasedDocumentRegistrationOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setClientDevicesDirectoryPath:[self clientDevicesDirectoryPath]];
    [operation setThisDocumentDirectoryPath:[self thisDocumentDirectoryPath]];
    [operation setThisDocumentDeletedClientsDirectoryPath:[self thisDocumentDeletedClientsDirectoryPath]];
    [operation setDeletedDocumentsDirectoryIdentifierPlistFilePath:[self deletedDocumentsDirectoryIdentifierPlistFilePath]];
    [operation setThisDocumentSyncChangesThisClientDirectoryPath:[self thisDocumentSyncChangesThisClientDirectoryPath]];
    [operation setThisDocumentSyncCommandsThisClientDirectoryPath:[self thisDocumentSyncCommandsThisClientDirectoryPath]];
    
    return SAFE_ARC_AUTORELEASE(operation);
}

- (TICDSWholeStoreDownloadOperation *)wholeStoreDownloadOperation
{
    TICDSDropboxSDKBasedWholeStoreDownloadOperation *operation = [[TICDSDropboxSDKBasedWholeStoreDownloadOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setThisDocumentDirectoryPath:[self thisDocumentDirectoryPath]];
    [operation setThisDocumentWholeStoreDirectoryPath:[self thisDocumentWholeStoreDirectoryPath]];
    
    return SAFE_ARC_AUTORELEASE(operation);
}

- (TICDSWholeStoreUploadOperation *)wholeStoreUploadOperation
{
    TICDSDropboxSDKBasedWholeStoreUploadOperation *operation = [[TICDSDropboxSDKBasedWholeStoreUploadOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setThisDocumentTemporaryWholeStoreThisClientDirectoryPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]];
    [operation setThisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath:[self thisDocumentTemporaryWholeStoreFilePath]];
    [operation setThisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath:[self thisDocumentTemporaryAppliedSyncChangeSetsFilePath]];
    [operation setThisDocumentWholeStoreThisClientDirectoryPath:[self thisDocumentWholeStoreThisClientDirectoryPath]];
    
    return SAFE_ARC_AUTORELEASE(operation);
}

- (TICDSSynchronizationOperation *)synchronizationOperation
{
    TICDSDropboxSDKBasedSynchronizationOperation *operation = [[TICDSDropboxSDKBasedSynchronizationOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setThisDocumentDirectoryPath:[self thisDocumentDirectoryPath]];
    [operation setThisDocumentSyncChangesDirectoryPath:[self thisDocumentSyncChangesDirectoryPath]];
    [operation setThisDocumentSyncChangesThisClientDirectoryPath:[self thisDocumentSyncChangesThisClientDirectoryPath]];
    [operation setThisDocumentRecentSyncsThisClientFilePath:[self thisDocumentRecentSyncsThisClientFilePath]];
    
    return SAFE_ARC_AUTORELEASE(operation);
}

- (TICDSVacuumOperation *)vacuumOperation
{
    TICDSDropboxSDKBasedVacuumOperation *operation = [[TICDSDropboxSDKBasedVacuumOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setThisDocumentWholeStoreDirectoryPath:[self thisDocumentWholeStoreDirectoryPath]];
    [operation setThisDocumentRecentSyncsDirectoryPath:[self thisDocumentRecentSyncsDirectoryPath]];
    [operation setThisDocumentSyncChangesThisClientDirectoryPath:[self thisDocumentSyncChangesThisClientDirectoryPath]];
    
    return SAFE_ARC_AUTORELEASE(operation);
}

- (TICDSListOfDocumentRegisteredClientsOperation *)listOfDocumentRegisteredClientsOperation
{
    TICDSDropboxSDKBasedListOfDocumentRegisteredClientsOperation *operation = [[TICDSDropboxSDKBasedListOfDocumentRegisteredClientsOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setThisDocumentSyncChangesDirectoryPath:[self thisDocumentSyncChangesDirectoryPath]];
    [operation setClientDevicesDirectoryPath:[self clientDevicesDirectoryPath]];
    [operation setThisDocumentRecentSyncsDirectoryPath:[self thisDocumentRecentSyncsDirectoryPath]];
    [operation setThisDocumentWholeStoreDirectoryPath:[self thisDocumentWholeStoreDirectoryPath]];
    
    return SAFE_ARC_AUTORELEASE(operation);
}

- (TICDSDocumentClientDeletionOperation *)documentClientDeletionOperation
{
    TICDSDropboxSDKBasedDocumentClientDeletionOperation *operation = [[TICDSDropboxSDKBasedDocumentClientDeletionOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setClientDevicesDirectoryPath:[self clientDevicesDirectoryPath]];
    [operation setThisDocumentDeletedClientsDirectoryPath:[self thisDocumentDeletedClientsDirectoryPath]];
    [operation setThisDocumentSyncChangesDirectoryPath:[self thisDocumentSyncChangesDirectoryPath]];
    [operation setThisDocumentSyncCommandsDirectoryPath:[self thisDocumentSyncCommandsDirectoryPath]];
    [operation setThisDocumentRecentSyncsDirectoryPath:[self thisDocumentRecentSyncsDirectoryPath]];
    [operation setThisDocumentWholeStoreDirectoryPath:[self thisDocumentWholeStoreDirectoryPath]];
    
    return SAFE_ARC_AUTORELEASE(operation);
}

#pragma mark -
#pragma mark Paths
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

#pragma mark -
#pragma mark Initialization and Deallocation


#if !__has_feature(objc_arc)

 - (void)dealloc
{
    _dbSession = nil;
    _applicationDirectoryPath = nil;

}
#endif

#pragma mark -
#pragma mark Lazy Accessors
- (DBSession *)dbSession
{
    if( _dbSession ) {
        return _dbSession;
    }
    
    _dbSession = SAFE_ARC_RETAIN([DBSession sharedSession]);
    
    return _dbSession;
}

#pragma mark -
#pragma mark Properties
@synthesize dbSession = _dbSession;
@synthesize applicationDirectoryPath = _applicationDirectoryPath;

@end

#endif
