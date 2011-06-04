//
//  TICDSDropboxSDKBasedDocumentClientDeletionOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 04/06/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSDropboxSDKBasedDocumentClientDeletionOperation

- (BOOL)needsMainThread
{
    return YES;
}

- (void)checkWhetherClientDirectoryExistsInDocumentSyncChangesDirectory
{
    
}

- (void)checkWhetherClientIdentifierFileAlreadyExistsInDocumentDeletedClientsDirectory
{
    
}

- (void)deleteClientIdentifierFileFromDeletedClientsDirectory
{
    
}

- (void)copyClientDeviceInfoPlistToDeletedClientsDirectory
{
    
}

- (void)deleteClientDirectoryFromDocumentSyncChangesDirectory
{
    
}

- (void)deleteClientDirectoryFromDocumentSyncCommandsDirectory
{
    
}

- (void)checkWhetherClientDirectoryExistsInDocumentWholeStoreDirectory
{
    
}

- (void)deleteClientDirectoryFromDocumentWholeStoreDirectory
{
    
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_dbSession release], _dbSession = nil;
    [_restClient release], _restClient = nil;
    
    [_clientDevicesDirectoryPath release], _clientDevicesDirectoryPath = nil;
    [_thisDocumentDeletedClientsDirectoryPath release], _thisDocumentDeletedClientsDirectoryPath = nil;
    [_thisDocumentSyncChangesDirectoryPath release], _thisDocumentSyncChangesDirectoryPath = nil;
    [_thisDocumentSyncCommandsDirectoryPath release], _thisDocumentSyncCommandsDirectoryPath = nil;
    [_thisDocumentWholeStoreDirectoryPath release], _thisDocumentWholeStoreDirectoryPath = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Lazy Accessors
- (DBRestClient *)restClient
{
    if( _restClient ) return _restClient;
    
    _restClient = [[DBRestClient alloc] initWithSession:[self dbSession]];
    [_restClient setDelegate:self];
    
    return _restClient;
}

#pragma mark -
#pragma mark Properties
@synthesize dbSession = _dbSession;
@synthesize restClient = _restClient;
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize thisDocumentDeletedClientsDirectoryPath = _thisDocumentDeletedClientsDirectoryPath;
@synthesize thisDocumentSyncChangesDirectoryPath = _thisDocumentSyncChangesDirectoryPath;
@synthesize thisDocumentSyncCommandsDirectoryPath = _thisDocumentSyncCommandsDirectoryPath;
@synthesize thisDocumentWholeStoreDirectoryPath = _thisDocumentWholeStoreDirectoryPath;

@end
