//
//  TICDSDocumentClientDeletionOperation.m
//  Notebook
//
//  Created by Tim Isted on 04/06/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSDocumentClientDeletionOperation ()

- (void)beginCheckingWhetherClientDirectoryExistsInDocumentSyncChangesDirectory;
- (void)beginCheckingWhetherClientIdentifierFileAlreadyExistsInDeletedClientsDirectory;
- (void)beginDeletingClientIdentifierFileFromDeletedClientsDirectory;
- (void)beginCopyingClientDeviceInfoPlistToDeletedClientsDirectory;
- (void)beginDeletingClientDirectoryFromDocumentSyncChangesDirectory;
- (void)beginDeletingClientDirectoryFromDocumentSyncCommandsDirectory;
- (void)beginCheckingWhetherClientIdentifierFileExistsInRecentSyncsDirectory;
- (void)beginDeletingClientIdentifierFileFromRecentSyncsDirectory;
- (void)beginCheckingWhetherClientDirectoryExistsInDocumentWholeStoreDirectory;
- (void)beginDeletingClientDirectoryFromDocumentWholeStoreDirectory;

@end

@implementation TICDSDocumentClientDeletionOperation

- (void)main
{
    [self beginCheckingWhetherClientDirectoryExistsInDocumentSyncChangesDirectory];
}

#pragma mark - Check Whether Client Has Synchronized Document
- (void)beginCheckingWhetherClientDirectoryExistsInDocumentSyncChangesDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Checking whether client %@ has previously synchronized the document", [self identifierOfClientToBeDeleted]);
    
    [self checkWhetherClientDirectoryExistsInDocumentSyncChangesDirectory];
}

- (void)discoveredStatusOfClientDirectoryInDocumentSyncChangesDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking whether client directory exists in document's SyncChanges directory");
            [self operationDidFailToComplete];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Client has not previously synchronized this document, so operation complete");
            [self setClientWasFoundAndDeleted:NO];
            [self operationDidCompleteSuccessfully];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client's directory does exist in document's `SyncChanges` directory");
            
            [self beginCheckingWhetherClientIdentifierFileAlreadyExistsInDeletedClientsDirectory];
            return;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherClientDirectoryExistsInDocumentSyncChangesDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfClientDirectoryInDocumentSyncChangesDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Check If identifier.plist File Exists in DeletedClients
- (void)beginCheckingWhetherClientIdentifierFileAlreadyExistsInDeletedClientsDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking whether client's identifier.plist file already exists in document's DeletedClients directory");
    
    [self checkWhetherClientIdentifierFileAlreadyExistsInDocumentDeletedClientsDirectory];
}

- (void)discoveredStatusOfClientIdentifierFileInDocumentDeletedClientsDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking whether client's identifier.plist file already exists in document's DeletedClients directory");
            [self operationDidFailToComplete];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client's identifer.plist file does not already exist in DeletedClients directory");
            [self beginCopyingClientDeviceInfoPlistToDeletedClientsDirectory];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client's identifier.plist file already exists in DeletedClients directory");
            [self beginDeletingClientIdentifierFileFromDeletedClientsDirectory];
            return;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherClientIdentifierFileAlreadyExistsInDocumentDeletedClientsDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfClientIdentifierFileInDocumentDeletedClientsDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Deleting Existing identifier.plist File
- (void)beginDeletingClientIdentifierFileFromDeletedClientsDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Deleting client's existing identifier.plist file from the document's DeletedClients directory");
    
    [self deleteClientIdentifierFileFromDeletedClientsDirectory];
}

- (void)deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete client's identifier.plist file from the DeletedClients directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Deleted client's identifier.plist file from the DeletedClients directory");
    
    [self beginCopyingClientDeviceInfoPlistToDeletedClientsDirectory];
}

#pragma mark Overridden Method
- (void)deleteClientIdentifierFileFromDeletedClientsDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:NO];
}

#pragma mark - Copy deviceInfo.plist to Deleted Clients Directory
- (void)beginCopyingClientDeviceInfoPlistToDeletedClientsDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Copying deviceInfo.plist to identifier.plist in document's DeletedClients directory");
    
    [self copyClientDeviceInfoPlistToDeletedClientsDirectory];
}

- (void)copiedClientDeviceInfoPlistToDeletedClientsDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to copy client's deviceInfo.plist file to the document's DeletedClients directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Copied client's deviceInfo.plist to document's DeletedClients directory");
    
    [self beginDeletingClientDirectoryFromDocumentSyncChangesDirectory];
}

#pragma mark Overridden Method
- (void)copyClientDeviceInfoPlistToDeletedClientsDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self copiedClientDeviceInfoPlistToDeletedClientsDirectoryWithSuccess:NO];
}

#pragma mark - Deleting Client Directory from SyncChanges
- (void)beginDeletingClientDirectoryFromDocumentSyncChangesDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Deleting client's directory from document's SyncChanges directory");
    
    [self deleteClientDirectoryFromDocumentSyncChangesDirectory];
}

- (void)deletedClientDirectoryFromDocumentSyncChangesDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete client's directory from the document's SyncChanges directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Deleted client's directory from the document's SyncChanges directory");
    
    [self beginDeletingClientDirectoryFromDocumentSyncCommandsDirectory];
}

#pragma mark Overridden Method
- (void)deleteClientDirectoryFromDocumentSyncChangesDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self deletedClientDirectoryFromDocumentSyncChangesDirectoryWithSuccess:NO];
}

#pragma mark - Deleting Client Directory from SyncCommands
- (void)beginDeletingClientDirectoryFromDocumentSyncCommandsDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Deleting client's directory from document's SyncCommands directory");
    
    [self deleteClientDirectoryFromDocumentSyncCommandsDirectory];
}

- (void)deletedClientDirectoryFromDocumentSyncCommandsDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete client's directory from document's SyncCommands directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Deleted client's directory from document's SyncCommands directory");
    [self beginCheckingWhetherClientIdentifierFileExistsInRecentSyncsDirectory];
}

#pragma mark Overridden Method
- (void)deleteClientDirectoryFromDocumentSyncCommandsDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self deletedClientDirectoryFromDocumentSyncCommandsDirectoryWithSuccess:NO];
}

#pragma mark - Check Whether File Exists in RecentSyncs Directory
- (void)beginCheckingWhetherClientIdentifierFileExistsInRecentSyncsDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking whether a file exists for this client in the document's RecentSyncs directory");
    
    [self checkWhetherClientIdentifierFileExistsInRecentSyncsDirectory];
}

- (void)discoveredStatusOfClientIdentifierFileInDocumentRecentSyncsDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Error checking whether client's file exists in document's RecentSyncs directory");
            [self operationDidFailToComplete];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client's file does exist in RecentSyncs directory");
            [self beginDeletingClientIdentifierFileFromRecentSyncsDirectory];
            break;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client's file does not exist in RecentSyncs directory");
            [self beginCheckingWhetherClientDirectoryExistsInDocumentWholeStoreDirectory];
            break;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherClientIdentifierFileExistsInRecentSyncsDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfClientIdentifierFileInDocumentRecentSyncsDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Delete Client's File from RecentSyncs Directory
- (void)beginDeletingClientIdentifierFileFromRecentSyncsDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Deleting client's file from document's RecentSyncs directory");
    
    [self deleteClientIdentifierFileFromRecentSyncsDirectory];
}

- (void)deletedClientIdentifierFileFromRecentSyncsDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error deleting client's file from the document's RecentSyncs directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Deleted cilent's file from the document's RecentSyncs directory");
    [self beginCheckingWhetherClientDirectoryExistsInDocumentWholeStoreDirectory];
}

#pragma mark Overridden Method
- (void)deleteClientIdentifierFileFromRecentSyncsDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self deletedClientIdentifierFileFromRecentSyncsDirectoryWithSuccess:NO];
}

#pragma mark - Check Whether Client has a WholeStore Directory for this Document
- (void)beginCheckingWhetherClientDirectoryExistsInDocumentWholeStoreDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking whether client has previously uploaded a WholeStore for this document");
    [self checkWhetherClientDirectoryExistsInDocumentWholeStoreDirectory];
}

- (void)discoveredStatusOfClientDirectoryInDocumentWholeStoreDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking whether client directory exists inside document's WholeStore directory");
            [self operationDidFailToComplete];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Client directory does not exist inside document's WholeStore directory, so operation is complete");
            [self setClientWasFoundAndDeleted:YES];
            [self operationDidCompleteSuccessfully];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client's directory does exist inside document's WholeStore directory");
            
            [self beginDeletingClientDirectoryFromDocumentWholeStoreDirectory];
            return;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherClientDirectoryExistsInDocumentWholeStoreDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfClientDirectoryInDocumentWholeStoreDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Deleting Client Directory from WholeStore
- (void)beginDeletingClientDirectoryFromDocumentWholeStoreDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Deleting client's directory from document's WholeStore directory");
    
    [self deleteClientDirectoryFromDocumentWholeStoreDirectory];
}

- (void)deletedClientDirectoryFromDocumentWholeStoreDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete client's directory from document's WholeStore directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Deleted client's directory from the document's WholeStore directory");
    [self setClientWasFoundAndDeleted:YES];
    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Method
- (void)deleteClientDirectoryFromDocumentWholeStoreDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self deletedClientDirectoryFromDocumentWholeStoreDirectoryWithSuccess:NO];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _identifierOfClientToBeDeleted = nil;

}

#pragma mark - Properties
@synthesize identifierOfClientToBeDeleted = _identifierOfClientToBeDeleted;
@synthesize clientWasFoundAndDeleted = _clientWasFoundAndDeleted;

@end
