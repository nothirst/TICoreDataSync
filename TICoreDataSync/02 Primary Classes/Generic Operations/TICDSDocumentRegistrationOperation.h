//
//  TICDSDocumentRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"
#import "TICDSClassesAndProtocols.h"

/** The `TICDSDocumentRegistrationOperation` class describes a generic operation used by the `TICoreDataSync` framework to register a document for future synchronization.
 
 The operation carries out the following tasks:
 
 1. Subclass checks whether the `documentIdentifier` directory exists on the remote.
    1. If not, ask the document sync manager whether to continue registering this document, and if not, bail, otherwise:
        1. Subclass creates the `documentIdentifier` directory on the remote, along with the general directory hierarchy.
        2. Subclass saves the `documentInfo.plist` file at the root of the document hierarchy, encrypting it if necessary.
        3. Continue by creating hierarchy for this client to synchronize this document.
    2. If document has been registered before, subclass checks whether this client has synchronized this document before.
        1. If so, registration is complete.
        2. If not, continue by creating client's directories for this document.
 2. Subclass checks whether the client's directory exists inside `SyncChanges`.
    1. If so, registration is complete.
    2. If not, continue by creating client's directories for this document.
 3. Subclass creates a directory for this client in this document's `SyncChanges` and `SyncCommands` directories.
  
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSDocumentRegistrationOperation`.
 */

@interface TICDSDocumentRegistrationOperation : TICDSOperation {
@private
    BOOL _paused;
    BOOL _documentWasDeleted;
    BOOL _shouldCreateDocumentFileStructure;
    BOOL _clientHasPreviouslySynchronizedThisDocument;
    
    NSString *_documentIdentifier;
    NSString *_documentDescription;
    NSString *_clientDescription;
    NSDictionary *_documentUserInfo;
    
    NSUInteger _numberOfDeletedClientIdentifiersToAdd;
    NSUInteger _numberOfDeletedClientIdentifiersAdded;
    NSUInteger _numberOfDeletedClientIdentifiersThatFailedToBeAdded;
    
    NSString *_integrityKey;
}

#pragma mark Designated Initializer
/** @name Designated Initializer */

/** Initialize a document registration operation using a delegate that supports the `TICDSDocumentRegistrationOperationDelegate` protocol.
 
 @param aDelegate The delegate to use for this operation.
 
 @return An initialized document registration operation. */
- (id)initWithDelegate:(NSObject<TICDSDocumentRegistrationOperationDelegate> *)aDelegate;

#pragma mark Methods Overridden by Subclasses
/** @name Methods Overridden by Subclasses */

/** Check whether a remote directory exists for this document.
 
 This method must call `discoveredStatusOfRemoteDocumentDirectory:` to indicate the status. */
- (void)checkWhetherRemoteDocumentDirectoryExists;

/** Check whether the document was previously deleted (i.e., whether an `identifier.plist` file exists in the `DeletedDocuments` directory.
 
 This method must call `discoveredDeletionStatusOfRemoteDocument:` to indicate the status. */
- (void)checkWhetherRemoteDocumentWasDeleted;

/** Create remote document directory structure.
 
 This method must call `createdRemoteDocumentDirectoryStructureWithSuccess:` to indicate whether the creation was successful. */
- (void)createRemoteDocumentDirectoryStructure;

/** Save the dictionary to a `documentInfo.plist` file in this document's directory.
 
 This method must call `savedRemoteDocumentInfoPlistWithSuccess:` to indicate whether the save was successful.
 
 @param aDictionary The dictionary to save as the `documentInfo.plist`. */
- (void)saveRemoteDocumentInfoPlistFromDictionary:(NSDictionary *)aDictionary;

/** Save a file with the integrity key as its name to this document's `IntegrityKey` directory.
 
 This method must call `savedIntegrityKeyWithSuccess:` to indicate whether the save was successful.
 
 @param aKey The integrity key to save. */
- (void)saveIntegrityKey:(NSString *)aKey;

/** Fetch a list of all clients registered to synchronize with this **application**.
 
 This list is used to add identifiers to this document's `DeletedClients` directory so that if those clients try to sync, they'll realize the document has previously been deleted.
 
 This method must call `` when finished. */
- (void)fetchListOfIdentifiersOfAllRegisteredClientsForThisApplication;

/** Copy the specified client's `deviceInfo.plist` file into the `DeletedClients` directory for this document, but name the copied file using the client's identifier (`identifier.plist`).
 
 This method must call `` to indicate whether the file was copied successfully.
 
 @param anIdentifier The identifier of the client. */
- (void)addDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:(NSString *)anIdentifier;

/** Delete the `identifier.plist` file for this document from the `DeletedDocuments` directory.
 
 This method must call `deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:` to indicate whether the deletion was successful. */
- (void)deleteDocumentInfoPlistFromDeletedDocumentsDirectory;

/** Check whether a directory exists for this client inside the document's `SyncChanges` directory.
 
 This method must call `discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:` to indicate the status. */
- (void)checkWhetherClientDirectoryExistsInRemoteDocumentSyncChangesDirectory;

/** Fetch the integrity key for this document.
 
 This method must call `fetchedRemoteIntegrityKey:` to provide the key. */
- (void)fetchRemoteIntegrityKey;

/** Check whether this client has previously been deleted from synchronizing with this document.
 
 This method must call `discoveredDeletionStatusOfClient:` to indicate the status. */
- (void)checkWhetherClientWasDeletedFromRemoteDocument;

/** Delete the client's file from the document's `DeletedClients` directory.
 
 This method must call `blah:` when finished. */
- (void)deleteClientIdentifierFileFromDeletedClientsDirectory;

/** Create directories for this client inside the `SyncChanges` and `SyncCommands` directories for this client.
 
 This method must call `createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:` to indicate whether the creation was successful. */
- (void)createClientDirectoriesInRemoteDocumentDirectories;

#pragma mark Callbacks
/** @name Callbacks */

/** Indicate the status of the remote document directory.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfRemoteDocumentDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the document was previously deleted.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureDeletionResponseTypeError` for `status`.
 
 @param status The status of the directory: was not deleted, was deleted, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredDeletionStatusOfRemoteDocument:(TICDSRemoteFileStructureDeletionResponseType)status;

/** Indicate whether the creation of the remote document directory structure was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory structure was created, otherwise `NO`. */
- (void)createdRemoteDocumentDirectoryStructureWithSuccess:(BOOL)success;

/** Indicate whether the `documentInfo.plist` file was saved successfully.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the `documentInfo.plist` file was saved, otherwise `NO`. */
- (void)savedRemoteDocumentInfoPlistWithSuccess:(BOOL)success;

/** Indicate whether the integrity key file was saved successfully.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the integrity key file was saved, otherwise `NO`. */
- (void)savedIntegrityKeyWithSuccess:(BOOL)success;

/** Pass back the assembled `NSArray` of client identifiers registered to synchronize with the **application**.
 
 If an error occurred, call `setError:` first, then specify `nil` for `anArray`.
 
 @param anArray The array of client identifiers, or `nil` if an error occurred. */
- (void)fetchedListOfIdentifiersOfAllRegisteredClientsForThisApplication:(NSArray *)anArray;

/** Indicate whether the `deviceInfo.plist` file was copied as `identifier.plist` to the `DeletedClients` directory for this document.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the file was copied, otherwise `NO`. */
- (void)addedDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:(NSString *)anIdentifier withSuccess:(BOOL)success;

/** Indicate whether the `identifier.plist` file for this document was removed from the `DeletedDocuments` directory.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the `identifier.plist` file was deleted, otherwise `NO`. */
- (void)deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:(BOOL)success;

/** Indicate the status of this client's directory inside the remote document `SyncChanges` directory.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Pass back the remote integrity key for this document.
 
 If an error occurred, call `setError:` first, then specify `nil` for `aKey`.
 
 @param aKey The remote integrity key, or `nil` if an error occurred. */
- (void)fetchedRemoteIntegrityKey:(NSString *)aKey;

/** Indicate whether the client has been deleted from synchronizing with this document.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureDeletionResponseTypeError` for `status`.
 
 @param status The deletion status: deleted, not deleted, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredDeletionStatusOfClient:(TICDSRemoteFileStructureDeletionResponseType)status;

/** Indicate whether the client's file in the document's `RecentSyncs` directory was deleted successfully.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the `identifier.plist` file was deleted, otherwise `NO`. */
- (void)deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:(BOOL)success;

/** Indicate whether the creation of the client directories was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory structure was created, otherwise `NO`. */
- (void)createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:(BOOL)success;

#pragma mark Properties
/** @name Properties */

/** Used to indicate whether the operation is currently paused awaiting input from the operation delegate, or in turn the document sync manager delegate. */
@property (assign, getter = isPaused) BOOL paused;

/** Used to indicate whether the reason a document doesn't exist is because it was deleted. */
@property (assign) BOOL documentWasDeleted;

/** Used by the `TICDSDocumentSyncManager` to indicate whether to create the remote document file structure after finding out it doesn't exist. */
@property (assign) BOOL shouldCreateDocumentFileStructure;

/** Used to keep track of whether the document has previously been synchronized by this client. */
@property (assign) BOOL clientHasPreviouslySynchronizedThisDocument;

/** The document identifier. */
@property (copy) NSString *documentIdentifier;

/** The document description (typically a filename). */
@property (copy) NSString *documentDescription;

/** The client description. */
@property (copy) NSString *clientDescription;

/** The user info. */
@property (strong) NSDictionary *documentUserInfo;

/** The integrity key provided either by the client to check existing data matches integrity, or set during registration for new documents. */
@property (copy) NSString *integrityKey;

@end
