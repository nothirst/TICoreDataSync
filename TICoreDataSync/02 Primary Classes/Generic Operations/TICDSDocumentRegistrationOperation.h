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
  
 Previous Tasks:
 
 1. Check whether the document has been previously registered with the remote (i.e., whether the file structure exists).
 2. If not, register the document and create the file structure.
 3. Check whether this client has previously been registered for this document (i.e., whether client-specific file structures exist).
 4. If not, create the necessary file structure for this client for this document.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSDocumentRegistrationOperation`.
 */

@interface TICDSDocumentRegistrationOperation : TICDSOperation {
@private
    BOOL _paused;
    BOOL _shouldCreateDocumentFileStructure;
    
    NSString *_documentIdentifier;
    NSString *_documentDescription;
    NSString *_clientDescription;
    NSDictionary *_documentUserInfo;
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

/** Create remote document directory structure.
 
 This method must call `createdRemoteDocumentDirectoryStructureWithSuccess:` to indicate whether the creation was successful. */
- (void)createRemoteDocumentDirectoryStructure;

/** Save the dictionary to a `documentInfo.plist` file in this document's directory.
 
 This method must call `savedRemoteDocumentInfoPlistWithSuccess:` to indicate whether the save was successful.
 
 @param aDictionary The dictionary to save as the `documentInfo.plist`. */
- (void)saveRemoteDocumentInfoPlistFromDictionary:(NSDictionary *)aDictionary;

/** Check whether a directory exists for this client inside the document's `SyncChanges` directory.
 
 This method must call `discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:` to indicate the status. */
- (void)checkWhetherClientDirectoryExistsInRemoteDocumentSyncChangesDirectory;

/** Create directories for this client inside the `SyncChanges` and `SyncCommands` directories for this client.
 
 This method must call `createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:` to indicate whether the creation was successful. */
- (void)createClientDirectoriesInRemoteDocumentDirectories;

#pragma mark Callbacks
/** @name Callbacks */

/** Indicate the status of the remote document directory.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfRemoteDocumentDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the creation of the remote document directory structure was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the directory structure was created or not */
- (void)createdRemoteDocumentDirectoryStructureWithSuccess:(BOOL)success;

/** Indicate whether the `documentInfo.plist` file was saved successfully.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the `documentInfo.plist` file was saved or not. */
- (void)savedRemoteDocumentInfoPlistWithSuccess:(BOOL)success;

/** Indicate the status of this client's directory inside the remote document `SyncChanges` directory.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the creation of the client directories was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the directory structure was created or not */
- (void)createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:(BOOL)success;

#pragma mark Properties
/** @name Properties */

/** Used to indicate whether the operation is currently paused awaiting input from the operation delegate, or in turn the document sync manager delegate. */
@property (assign, getter = isPaused) BOOL paused;

/** Used by the `TICDSDocumentSyncManager` to indicate whether to create the remote document file structure after finding out it doesn't exist. */
@property (assign) BOOL shouldCreateDocumentFileStructure;

/** The document identifier. */
@property (retain) NSString *documentIdentifier;

/** The document description (typically a filename). */
@property (retain) NSString *documentDescription;

/** The client description. */
@property (retain) NSString *clientDescription;

/** The user info. */
@property (retain) NSDictionary *documentUserInfo;

@end
