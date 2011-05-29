//
//  TICDSDocumentDeletionOperation.h
//  Notebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"


@interface TICDSDocumentDeletionOperation : TICDSOperation {
@private
    NSString *_documentIdentifier;
    BOOL _documentWasFoundAndDeleted;
}

#pragma mark Overridden Methods
/** @name Overridden Methods */

/** Check whether the document directory with specified identifier exists.
  
 This method must call `discoveredStatusOfTemporaryWholeStoreDirectory:` to indicate the status. */
- (void)checkWhetherIdentifiedDocumentDirectoryExists;

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

/** Indicate whether the `documentInfo.plist` file was copied successfully to the `DeletedDocuments` directory.
 
 If an error occurred, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the file was copied. */
- (void)copiedDocumentInfoPlistToDeletedDocumentsDirectoryWithSuccess:(BOOL)success;

/** Indicate whether the document directory was deleted successfully.
 
 If an error occurred, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the directory was deleted. */
- (void)deletedDocumentDirectoryWithSuccess:(BOOL)success;

#pragma mark Properties
/** @name Properties */

/** The identifier of the document to delete. */
@property (retain) NSString *documentIdentifier;

/** Used to indicate (once the operation completes) whether the document was found and deleted successfully. */
@property (assign) BOOL documentWasFoundAndDeleted;

@end
