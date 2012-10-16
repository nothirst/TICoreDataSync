//
//  TICDSDocumentDeletionOperation.h
//  Notebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSDocumentDeletionOperation` class describes a generic operation used by the `TICoreDataSync` framework to delete the remote synchronization data used to synchronize a document.
 
 The operation carries out the following tasks:
 
 1. Check whether the specified document exists.
 2. Copy the `documentInfo.plist` file to an `identifier.plist` file inside the `DeletedDocuments` directory.
 3. Delete the document's directory.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSDocumentDeletionOperation`. */

@interface TICDSDocumentDeletionOperation : TICDSOperation {
@private
    NSString *_documentIdentifier;
    BOOL _documentWasFoundAndDeleted;
}

#pragma mark Designated Initializer
/** @name Designated Initializer */

/** Initialize a document deletion operation using a delegate that supports the `TICDSDocumentDeletionOperationDelegate` protocol.
 
 @param aDelegate The delegate to use for this operation.
 
 @return An initialized document registration operation. */
- (id)initWithDelegate:(NSObject<TICDSDocumentDeletionOperationDelegate> *)aDelegate;

#pragma mark Overridden Methods
/** @name Overridden Methods */

/** Check whether the document directory with specified identifier exists.
  
 This method must call `discoveredStatusOfTemporaryWholeStoreDirectory:` to indicate the status. */
- (void)checkWhetherIdentifiedDocumentDirectoryExists;

/** Check whether the `identifier.plist` file for the specified document identifier exists.
 
 This method must call `discoveredStatusOfIdentifierPlistInDeletedDocumentsDirectory:` to indicate the status. */
- (void)checkForExistingIdentifierPlistInDeletedDocumentsDirectory;

/** Delete the identified document's `identifier.plist` file from the `DeletedDocuments` directory.
 
 This method must call `deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:` when finished. */
- (void)deleteDocumentInfoPlistFromDeletedDocumentsDirectory;

/** Copy the identified document's `documentInfo.plist` file to the `DeletedDocuments` directory.
 
 This method must call `copiedDocumentInfoPlistToDeletedDocumentsDirectoryWithSuccess:` when finished. */
- (void)copyDocumentInfoPlistToDeletedDocumentsDirectory;

/** Delete the identified document's directory.
 
 This method must call `deletedDocumentDirectoryWithSuccess:` when finished. */
- (void)deleteDocumentDirectory;

#pragma mark Callbacks
/** @name Callbacks */

/** Indicate the status of the document's directory.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfIdentifiedDocumentDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate the status of an existing `identifier.plist` file in the `DeletedDocuments` directory.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the file: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfIdentifierPlistInDeletedDocumentsDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the `identifier.plist` file was deleted successfully from the `DeletedDocuments` directory.
 
 If an error occurred, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the file was deleted successfully, or `NO` if an error occurred. */
- (void)deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:(BOOL)success;

/** Indicate whether the `documentInfo.plist` file was copied successfully to the `DeletedDocuments` directory.
 
 If an error occurred, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the file was copied successfully, or `NO` if an error occurred.  */
- (void)copiedDocumentInfoPlistToDeletedDocumentsDirectoryWithSuccess:(BOOL)success;

/** Indicate whether the document directory was deleted successfully.
 
 If an error occurred, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory was deleted successfully, or `NO` if an error occurred.  */
- (void)deletedDocumentDirectoryWithSuccess:(BOOL)success;

#pragma mark Properties
/** @name Properties */

/** The identifier of the document to delete. */
@property (copy) NSString *documentIdentifier;

/** Used to indicate (once the operation completes) whether the document was found and deleted successfully. */
@property (assign) BOOL documentWasFoundAndDeleted;

@end
