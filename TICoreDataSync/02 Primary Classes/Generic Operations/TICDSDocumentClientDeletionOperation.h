//
//  TICDSDocumentClientDeletionOperation.h
//  Notebook
//
//  Created by Tim Isted on 04/06/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSDocumentClientDeletionOperation` class describes a generic operation used by the `TICoreDataSync` framework to delete the remote synchronization data used by a client to synchronize a document.
 
 The operation carries out the following tasks:
 
 1. Check whether the specified client has synchronized the document.
 2. Copy the `deviceInfo.plist` file to an `identifier.plist` file inside the document's `DeletedClients` directory.
 3. Delete the client's `SyncChanges`, `SyncCommands` and `WholeStore` directories for the document.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSDocumentDeletionOperation`. */

@interface TICDSDocumentClientDeletionOperation : TICDSOperation {
@private
    NSString *_identifierOfClientToBeDeleted;
    BOOL _clientWasFoundAndDeleted;
}

#pragma mark Overridden Methods
/** @name Overridden Methods */

/** Check whether a directory exists for the client inside the document's `SyncChanges` directory.
 
 This method must call `discoveredStatusOfClientDirectoryInDocumentSyncChangesDirectory:` to indicate the status. */
- (void)checkWhetherClientDirectoryExistsInDocumentSyncChangesDirectory;

/** Check whether an `identifier.plist` file already exists for the client in the document's `DeletedClients` directory.
 
 This method must call `discoveredStatusOfClientIdentifierFileInDocumentDeletedClientsDirectory:` to indicate the status. */
- (void)checkWhetherClientIdentifierFileAlreadyExistsInDocumentDeletedClientsDirectory;

/** Delete the client's `identifier.plist` file from the document's `DeletedClients` directory. 
 
 This method must call `deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:` to indicate the status. */
- (void)deleteClientIdentifierFileFromDeletedClientsDirectory;

/** Copy the client's `deviceInfo.plist` file to an `identifier.plist` file in the document's `DeletedClients` directory. 
 
 This method must call `copiedClientDeviceInfoPlistToDeletedClientsDirectoryWithSuccess:` when finished. */
- (void)copyClientDeviceInfoPlistToDeletedClientsDirectory;

/** Delete the client's directory from the document's `SyncChanges` directory.
 
 This method must call `deletedClientDirectoryFromDocumentSyncChangesDirectoryWithSuccess:` when finished. */
- (void)deleteClientDirectoryFromDocumentSyncChangesDirectory;

/** Delete the client's directory from the document's `SyncCommands` directory.
 
 This method must call `deletedClientDirectoryFromDocumentSyncCommandsDirectoryWithSuccess:` when finished. */
- (void)deleteClientDirectoryFromDocumentSyncCommandsDirectory;

/** Checks whether a file exists for the client in the document's `RecentSyncs` directory. 
 
 This method must call `discoveredStatusOfClientIdentifierFileInDocumentRecentSyncsDirectory:` when finished. */
- (void)checkWhetherClientIdentifierFileExistsInRecentSyncsDirectory;

/** Delete the client's file from the document's `RecentSyncs` directory.
 
 This method must call `blah:` when finished. */
- (void)deleteClientIdentifierFileFromRecentSyncsDirectory;

/** Check whether a directory exists for the client in the document's `WholeStore` directory.
 
 This method must call `discoveredStatusOfClientDirectoryInDocumentWholeStoreDirectory:` to indicate the status. */
- (void)checkWhetherClientDirectoryExistsInDocumentWholeStoreDirectory;

/** Delete the client's directory from the document's `WholeStore` directory.
 
 This method must call `deletedClientDirectoryFromDocumentWholeStoreDirectoryWithSuccess:` when finished. */
- (void)deleteClientDirectoryFromDocumentWholeStoreDirectory;

#pragma mark Callbacks
/** @name Callbacks */

/** Indicate the status of the client's directory inside the document's `SyncChanges` directory.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfClientDirectoryInDocumentSyncChangesDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate the status of the client's identifier.plist inside the document's `DeletedClients` directory.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the file: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfClientIdentifierFileInDocumentDeletedClientsDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the `identifier.plist` file was deleted successfully from the document's `DeletedClients` directory.
 
 If an error occurred, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the file was deleted successfully, or `NO` if an error occurred. */
- (void)deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:(BOOL)success;

/** Indicate whether the client's `deviceInfo.plist` file was copied to an `identifier.plist` file in the document's `DeletedClients` directory.
 
 If an error occurred, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the file was copied successfully, or `NO` if an error occurred. */
- (void)copiedClientDeviceInfoPlistToDeletedClientsDirectoryWithSuccess:(BOOL)success;

/** Indicate whether the client's directory was deleted successfully from the document's `SyncChanges` directory.
 
 If an error occurred, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory was deleted successfully, or `NO` if an error occurred. */
- (void)deletedClientDirectoryFromDocumentSyncChangesDirectoryWithSuccess:(BOOL)success;

/** Indicate whether the client's directory was deleted successfully from the document's `SyncCommands` directory.
 
 If an error occurred, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory was deleted successfully, or `NO` if an error occurred. */
- (void)deletedClientDirectoryFromDocumentSyncCommandsDirectoryWithSuccess:(BOOL)success;

/** Indicate the status of the client's file inside the document's `RecentSyncs` directory.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfClientIdentifierFileInDocumentRecentSyncsDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the client's file was deleted successfully from the document's `RecentSyncs` directory.
 
 If an error occurred, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory was deleted successfully, or `NO` if an error occurred. */
- (void)deletedClientIdentifierFileFromRecentSyncsDirectoryWithSuccess:(BOOL)success;

/** Indicate the status of the client's directory inside the document's `WholeStore` directory.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfClientDirectoryInDocumentWholeStoreDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the client's directory was deleted successfully from the document's `WholeStore` directory.
 
 If an error occurred, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory was deleted successfully, or `NO` if an error occurred. */
- (void)deletedClientDirectoryFromDocumentWholeStoreDirectoryWithSuccess:(BOOL)success;

#pragma mark Properties
/** @name Properties */

/** The identifier of the client to be deleted. */
@property (copy) NSString *identifierOfClientToBeDeleted;

/** Used to indicate (once the operation completes) whether the client was found and deleted successfully. */
@property (assign) BOOL clientWasFoundAndDeleted;

@end
