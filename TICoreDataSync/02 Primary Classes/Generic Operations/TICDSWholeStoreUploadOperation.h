//
//  TICDSWholeStoreUploadOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSWholeStoreUploadOperation` class describes a generic operation used by the `TICoreDataSync` framework to upload the whole store for a document.
 
 The operation carries out the following tasks:
 
 1. Check whether a directory exists for this client inside the document's `WholeStore` directory.
 2. If not, create one.
 3. Upload the whole store file.
 4. Upload the applied sync change sets file that goes with this whole store.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSWholeStoreUploadOperation`. */

@interface TICDSWholeStoreUploadOperation : TICDSOperation {
@private
    NSURL *_localWholeStoreFileLocation;
    NSURL *_localAppliedSyncChangeSetsFileLocation;
    
    BOOL _completionInProgress;
    TICDSOperationPhaseStatus _wholeStoreDirectoryStatus;
    TICDSOperationPhaseStatus _wholeStoreFileUploadStatus;
    TICDSOperationPhaseStatus _appliedSyncChangeSetsUploadStatus;
}

/** @name Methods Overridden by Subclasses */

/** Check whether a directory exists for this client inside the document's `WholeStore` directory.
 
 This method must call `discoveredStatusOfWholeStoreDirectory:` to indicate the status.
 */
- (void)checkWhetherThisClientWholeStoreDirectoryExists;

/** Create this client's directory inside this document's `WholeStore` directory; this method will be called automatically if the directory doesn't already exist.
 
 This method must call `createdThisClientWholeStoreDirectorySuccessfully:` to indicate whether the creation was successful.
 */
- (void)createThisClientWholeStoreDirectory;

/** Upload the store at `localWholeStoreFileLocation` to the remote path 
 
    This method must call `uploadedWholeStoreFileWithSuccess:` when finished. */
- (void)uploadWholeStoreFile;

/** Upload the applied sync change sets file at `localAppliedSyncChangeSetsFileLocation` to the remote path `/Documents/documentIdentifier/WholeStore/clientIdentifier/AppliedSyncChangeSets.sqlite`. 
 
 This method must call `uploadedWholeStoreFileWithSuccess:` when finished. */
- (void)uploadAppliedSyncChangeSetsFile;

/** @name Callbacks */

/** Indicate the status of this client's directory inside the `WholeStore` directory for this document.
 
 If an error occurred, call `setError:` and pass `TICDSRemoteFileStructureExistsResponseTypeError`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfWholeStoreDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the upload of the whole store file was successful.
 
 If not, call `setError:` and specify `NO`.
 
 @param success A Boolean indicating whether the whole store file was uploaded or not. */
- (void)uploadedWholeStoreFileWithSuccess:(BOOL)success;

/** Indicate whether the creation of this client's directory inside this document's `WholeStore` directory was successful.
 
 If not, call `setError:` and specify `NO`.
 
 @param someSuccess A Boolean indicating whether the directory was created or not. */
- (void)createdThisClientWholeStoreDirectorySuccessfully:(BOOL)someSuccess;

/** Indicate whether the upload of the applied sync change sets file was successful.
 
 If not, call `setError:` and specify `NO`.
 
 @param success A Boolean indicating whether the applied sync change sets file was uploaded or not. */
- (void)uploadedAppliedSyncChangeSetsFileWithSuccess:(BOOL)success;

/** @name Properties */

/** The location of the whole store file to upload. */
@property (retain) NSURL *localWholeStoreFileLocation;

/** The location of the applied sync change sets file to upload. */
@property (retain) NSURL *localAppliedSyncChangeSetsFileLocation;

/** @name Completion */

/** Used to indicate that completion is currently in progress, and that no further checks should be made. */
@property (nonatomic, assign) BOOL completionInProgress;

/** The phase status regarding checking (and creating if necessary) this client's directory inside the `WholeStore` directory for this document. */
@property (nonatomic, assign) TICDSOperationPhaseStatus wholeStoreDirectoryStatus;

/** The phase status of the whole store file upload. */
@property (nonatomic, assign) TICDSOperationPhaseStatus wholeStoreFileUploadStatus;

/** The phase status of the applied sync change sets file upload. */
@property (nonatomic, assign) TICDSOperationPhaseStatus appliedSyncChangeSetsFileUploadStatus;

@end
