//
//  TICDSDropboxSDKBasedApplicationSyncManager.m
//  iOSNotebook
//
//  Created by Tim Isted on 13/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICoreDataSync.h"

#import <DropboxSDK/DropboxSDK.h>

@implementation TICDSDropboxSDKBasedApplicationSyncManager

#pragma mark -
#pragma mark Overridden Methods
- (TICDSApplicationRegistrationOperation *)applicationRegistrationOperation
{
    TICDSDropboxSDKBasedApplicationRegistrationOperation *operation = [[TICDSDropboxSDKBasedApplicationRegistrationOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setApplicationDirectoryPath:[self applicationDirectoryPath]];
    [operation setEncryptionDirectorySaltDataFilePath:[self encryptionDirectorySaltDataFilePath]];
    [operation setEncryptionDirectoryTestDataFilePath:[self encryptionDirectoryTestDataFilePath]];
    [operation setClientDevicesThisClientDeviceDirectoryPath:[self clientDevicesThisClientDeviceDirectoryPath]];
    
    return [operation autorelease];
}

- (TICDSListOfPreviouslySynchronizedDocumentsOperation *)listOfPreviouslySynchronizedDocumentsOperation
{
    TICDSDropboxSDKBasedListOfPreviouslySynchronizedDocumentsOperation *operation = [[TICDSDropboxSDKBasedListOfPreviouslySynchronizedDocumentsOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setDocumentsDirectoryPath:[self documentsDirectoryPath]];
    
    return [operation autorelease];
}

- (TICDSWholeStoreDownloadOperation *)wholeStoreDownloadOperationForDocumentWithIdentifier:(NSString *)anIdentifier
{
    TICDSDropboxSDKBasedWholeStoreDownloadOperation *operation = [[TICDSDropboxSDKBasedWholeStoreDownloadOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setThisDocumentDirectoryPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier]];
    [operation setThisDocumentWholeStoreDirectoryPath:[self pathToWholeStoreDirectoryForDocumentWithIdentifier:anIdentifier]];
    
    return [operation autorelease];
}

- (TICDSListOfApplicationRegisteredClientsOperation *)listOfApplicationRegisteredClientsOperation
{
    TICDSDropboxSDKBasedListOfApplicationRegisteredClientsOperation *operation = [[TICDSDropboxSDKBasedListOfApplicationRegisteredClientsOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setClientDevicesDirectoryPath:[self clientDevicesDirectoryPath]];
    [operation setDocumentsDirectoryPath:[self documentsDirectoryPath]];
    
    return [operation autorelease];
}

- (TICDSDocumentDeletionOperation *)documentDeletionOperationForDocumentWithIdentifier:(NSString *)anIdentifier
{
    TICDSDropboxSDKBasedDocumentDeletionOperation *operation = [[TICDSDropboxSDKBasedDocumentDeletionOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setDeletedDocumentsDirectoryIdentifierPlistFilePath:[[self deletedDocumentsDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", anIdentifier, TICDSDocumentInfoPlistExtension]]];
    [operation setDocumentDirectoryPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier]];
    [operation setDocumentInfoPlistFilePath:[[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSDocumentInfoPlistFilenameWithExtension]];
    
    return [operation autorelease];
}

- (TICDSRemoveAllRemoteSyncDataOperation *)removeAllSyncDataOperation
{
    TICDSDropboxSDKBasedRemoveAllRemoteSyncDataOperation *operation = [[TICDSDropboxSDKBasedRemoveAllRemoteSyncDataOperation alloc] initWithDelegate:self];
    
    [operation setDbSession:[self dbSession]];
    [operation setApplicationDirectoryPath:[self applicationDirectoryPath]];
    
    return [operation autorelease];
}

#pragma mark -
#pragma mark Paths
- (NSString *)applicationDirectoryPath
{
    return [NSString stringWithFormat:@"/%@", [self appIdentifier]];
}

- (NSString *)deletedDocumentsDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToInformationDeletedDocumentsDirectory]];
}

- (NSString *)encryptionDirectorySaltDataFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToEncryptionDirectorySaltDataFilePath]];
}

- (NSString *)encryptionDirectoryTestDataFilePath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToEncryptionDirectoryTestDataFilePath]];
}

- (NSString *)clientDevicesDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToClientDevicesDirectory]];
}

- (NSString *)clientDevicesThisClientDeviceDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToClientDevicesThisClientDeviceDirectory]];
}

- (NSString *)documentsDirectoryPath
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToDocumentsDirectory]];
}

- (NSString *)pathToWholeStoreDirectoryForDocumentWithIdentifier:(NSString *)anIdentifier
{
    return [[self applicationDirectoryPath] stringByAppendingPathComponent:[self relativePathToWholeStoreDirectoryForDocumentWithIdentifier:anIdentifier]];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_dbSession release], _dbSession = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Lazy Accessors
- (DBSession *)dbSession
{
    if( _dbSession ) {
        return _dbSession;
    }
    
    _dbSession = [[DBSession sharedSession] retain];
    
    return _dbSession;
}

#pragma mark -
#pragma mark Properties
@synthesize dbSession = _dbSession;

@end

#endif