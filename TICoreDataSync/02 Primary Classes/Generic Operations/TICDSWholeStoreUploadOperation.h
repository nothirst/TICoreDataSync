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
 
 1. Upload the whole store file.
 2. Upload the applied sync change sets file that goes with this whole store.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSWholeStoreUploadOperation`.
 */

@interface TICDSWholeStoreUploadOperation : TICDSOperation {
@private
    NSURL *_localWholeStoreFileLocation;
    NSURL *_localAppliedSyncChangeSetsFileLocation;
    
    BOOL _completionInProgress;
    TICDSOperationPhaseStatus _wholeStoreFileUploadStatus;
    TICDSOperationPhaseStatus _appliedSyncChangeSetsUploadStatus;
}

/** @name Methods Overridden by Subclasses */

/** Upload the store at `localWholeStoreFileLocation` to the remote path `Documents/<document identifier>/WholeStore/<client identifier>/WholeStore.sqlite`. 
 
    Call `uploadedWholeStoreFileWithSuccess:` when finished. */
- (void)uploadWholeStoreFile;

/** Upload the applied sync change sets file at `localAppliedSyncChangeSetsFileLocation` to the remote path `Documents/<document identifier>/WholeStore/<client identifier>/AppliedSyncChangeSets.sqlite`. 
 
 Call `uploadedWholeStoreFileWithSuccess:` when finished. */
- (void)uploadAppliedSyncChangeSetsFile;

/** @name Callbacks */

/** Indicate whether the upload of the whole store file was successful.
 
 If not, call `setError:` and specify `NO`.
 
 @param success A Boolean indicating whether the whole store file was uploaded or not. */
- (void)uploadedWholeStoreFileWithSuccess:(BOOL)success;

/** Indicate whether the upload of the applied sync change sets file was successful.
 
 If not, call `setError:` and specify `NO`.
 
 @param success A Boolean indicating whether the applied sync change sets file was uploaded or not. */
- (void)uploadedAppliedSyncChangeSetsFileWithSuccess:(BOOL)success;

/** @name Properties */

/** The location of the whole store file to upload. */
@property (retain) NSURL *localWholeStoreFileLocation;

/** @name Completion */

/** Used to indicate that completion is currently in progress, and that no further checks should be made. */
@property (nonatomic, assign) BOOL completionInProgress;

/** The phase status of the whole store file upload. */
@property (nonatomic, assign) TICDSOperationPhaseStatus wholeStoreFileUploadStatus;

/** The phase status of the applied sync change sets file upload. */
@property (nonatomic, assign) TICDSOperationPhaseStatus appliedSyncChangeSetsFileUploadStatus;

@end
