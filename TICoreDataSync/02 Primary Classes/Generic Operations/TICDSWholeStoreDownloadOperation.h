//
//  TICDSWholeStoreDownloadOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSWholeStoreDownloadOperation` class describes a generic operation used by the `TICoreDataSync` framework to download the whole store for a document.
 
 The operation carries out the following tasks:
 
 1. Download the whole store file.
 2. Download the applied sync change sets file that goes with this whole store.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSWholeStoreDownloadOperation`. */

@interface TICDSWholeStoreDownloadOperation : TICDSOperation {
@private
    NSURL *_localWholeStoreFileLocation;
    NSURL *_localAppliedSyncChangeSetsFileLocation;
    
    BOOL _completionInProgress;
    TICDSOperationPhaseStatus _wholeStoreFileDownloadStatus;
    TICDSOperationPhaseStatus _appliedSyncChangeSetsDownloadStatus;
}

/** @name Methods Overridden by Subclasses */

/** Download the store at the remote document store path to the `localWholeStoreFileLocation`. 
 
 This method must call `downloadedWholeStoreFileWithSuccess:` when finished. */
- (void)downloadWholeStoreFile;

/** Download the applied sync change sets file at the remote document store path to the `localAppliedSyncChangeSetsFileLocation`. 
 
 This method must call `downloadedAppliedSyncChangeSetsFileWithSuccess:` when finished. */
- (void)downloadAppliedSyncChangeSetsFile;

/** @name Callbacks */

/** Indicate whether the download of the whole store file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the whole store file was downloaded or not. */
- (void)downloadedWholeStoreFileWithSuccess:(BOOL)success;

/** Indicate whether the download of the applied sync change sets file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the applied sync change sets file was downloaded or not. */
- (void)downloadedAppliedSyncChangeSetsFileWithSuccess:(BOOL)success;

/** @name Properties */

/** The location of the whole store file to upload. */
@property (retain) NSURL *localWholeStoreFileLocation;

/** The location of the applied sync change sets file to upload. */
@property (retain) NSURL *localAppliedSyncChangeSetsFileLocation;

/** @name Completion */

/** Used to indicate that completion is currently in progress, and that no further checks should be made. */
@property (nonatomic, assign) BOOL completionInProgress;

/** The phase status of the whole store file upload. */
@property (nonatomic, assign) TICDSOperationPhaseStatus wholeStoreFileDownloadStatus;

/** The phase status of the applied sync change sets file upload. */
@property (nonatomic, assign) TICDSOperationPhaseStatus appliedSyncChangeSetsFileDownloadStatus;

@end
