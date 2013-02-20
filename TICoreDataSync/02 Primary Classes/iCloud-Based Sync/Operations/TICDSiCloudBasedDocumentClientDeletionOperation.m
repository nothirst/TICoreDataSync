//
//  TICDSiCloudBasedDocumentClientDeletionOperation.m
//  Notebook
//
//  Created by Tim Isted on 04/06/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSiCloudBasedDocumentClientDeletionOperation

- (void)checkWhetherClientDirectoryExistsInDocumentSyncChangesDirectory
{
    NSString *path = [[self thisDocumentSyncChangesDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]];
    
    if( [self fileExistsAtPath:path] ) {
        [self discoveredStatusOfClientDirectoryInDocumentSyncChangesDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfClientDirectoryInDocumentSyncChangesDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)checkWhetherClientIdentifierFileAlreadyExistsInDocumentDeletedClientsDirectory
{
    NSString *path = [[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension];
    
    if( [self fileExistsAtPath:path] ) {
        [self discoveredStatusOfClientIdentifierFileInDocumentDeletedClientsDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfClientIdentifierFileInDocumentDeletedClientsDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)deleteClientIdentifierFileFromDeletedClientsDirectory
{
    NSString *filePath = [[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension];
    
    NSError *anyError = nil;
    BOOL success = [self removeItemAtPath:filePath error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:success];
}

- (void)copyClientDeviceInfoPlistToDeletedClientsDirectory
{
    NSString *deviceInfoFilePath = [[[self clientDevicesDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension];
    
    NSString *finalFilePath = [[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension];
    
    NSError *anyError = nil;
    BOOL success = [self copyItemAtPath:deviceInfoFilePath toPath:finalFilePath error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self copiedClientDeviceInfoPlistToDeletedClientsDirectoryWithSuccess:success];
}

- (void)deleteClientDirectoryFromDocumentSyncChangesDirectory
{
    NSString *directoryPath = [[self thisDocumentSyncChangesDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]];
    
    NSError *anyError = nil;
    BOOL success = [self removeItemAtPath:directoryPath error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedClientDirectoryFromDocumentSyncChangesDirectoryWithSuccess:success];
}

- (void)deleteClientDirectoryFromDocumentSyncCommandsDirectory
{
    NSString *directoryPath = [[self thisDocumentSyncCommandsDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]];
    
    NSError *anyError = nil;
    BOOL success = [self removeItemAtPath:directoryPath error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedClientDirectoryFromDocumentSyncCommandsDirectoryWithSuccess:success];
}

- (void)checkWhetherClientIdentifierFileExistsInRecentSyncsDirectory
{
    NSString *filePath = [[[self thisDocumentRecentSyncsDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]] stringByAppendingPathExtension:TICDSRecentSyncFileExtension];
    
    if( [self fileExistsAtPath:filePath] ) {
        [self discoveredStatusOfClientIdentifierFileInDocumentRecentSyncsDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfClientIdentifierFileInDocumentRecentSyncsDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)deleteClientIdentifierFileFromRecentSyncsDirectory
{
    NSString *filePath = [[[self thisDocumentRecentSyncsDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]] stringByAppendingPathExtension:TICDSRecentSyncFileExtension];
    
    NSError *anyError = nil;
    BOOL success = [self removeItemAtPath:filePath error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedClientIdentifierFileFromRecentSyncsDirectoryWithSuccess:success];
}

- (void)checkWhetherClientDirectoryExistsInDocumentWholeStoreDirectory
{
    NSString *directoryPath = [[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]];
    
    if( [self fileExistsAtPath:directoryPath] ) {
        [self discoveredStatusOfClientDirectoryInDocumentWholeStoreDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfClientDirectoryInDocumentWholeStoreDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)deleteClientDirectoryFromDocumentWholeStoreDirectory
{
    NSString *directoryPath = [[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]];
    
    NSError *anyError = nil;
    BOOL success = [self removeItemAtPath:directoryPath error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedClientDirectoryFromDocumentWholeStoreDirectoryWithSuccess:success];
}

#pragma mark -
#pragma mark Properties
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize thisDocumentDeletedClientsDirectoryPath = _thisDocumentDeletedClientsDirectoryPath;
@synthesize thisDocumentSyncChangesDirectoryPath = _thisDocumentSyncChangesDirectoryPath;
@synthesize thisDocumentSyncCommandsDirectoryPath = _thisDocumentSyncCommandsDirectoryPath;
@synthesize thisDocumentRecentSyncsDirectoryPath = _thisDocumentRecentSyncsDirectoryPath;
@synthesize thisDocumentWholeStoreDirectoryPath = _thisDocumentWholeStoreDirectoryPath;

@end
