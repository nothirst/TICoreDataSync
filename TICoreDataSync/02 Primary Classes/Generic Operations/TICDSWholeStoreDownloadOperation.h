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
 
 1. If `requestedWholeStoreClientIdentifier` is not set, determine which client uploaded a store most recently, and set `requestedWholeStoreClientIdentifier`.
 1. Download the whole store file from the `requestedWholeStoreClientIdentifier`'s directory.
 2. Download the applied sync change sets file that goes with this whole store.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSWholeStoreDownloadOperation`. */

@interface TICDSWholeStoreDownloadOperation : TICDSOperation {
@private
    NSString *_requestedWholeStoreClientIdentifier;
    
    NSURL *_localWholeStoreFileLocation;
    NSURL *_localAppliedSyncChangeSetsFileLocation;
    
    BOOL _completionInProgress;
    TICDSOperationPhaseStatus _determineMostRecentlyUploadedStoreStatus;
    TICDSOperationPhaseStatus _wholeStoreFileDownloadStatus;
    TICDSOperationPhaseStatus _appliedSyncChangeSetsDownloadStatus;
}

/** @name Methods Overridden by Subclasses */

/** Determine which client uploaded a WholeStore most recently.
 
 This method must call `determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:` when finished. */
- (void)checkForMostRecentClientWholeStore;

/** Download the store at the remote document store path to the `localWholeStoreFileLocation`. 
 
 This method must call `downloadedWholeStoreFileWithSuccess:` when finished. */
- (void)downloadWholeStoreFile;

/** Download the applied sync change sets file at the remote document store path to the `localAppliedSyncChangeSetsFileLocation`. 
 
 This method must call `downloadedAppliedSyncChangeSetsFileWithSuccess:` when finished. */
- (void)downloadAppliedSyncChangeSetsFile;

/** @name Callbacks */

/** Indicate which client uploaded the most recent WholeStore.
 
 If an error occurs, call `setError:` first, then specify `nil` for `anIdentifier`
 
 @param anIdentifier The identifier of the client. */
- (void)determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:(NSString *)anIdentifier;

/** Indicate whether the download of the whole store file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the whole store file was downloaded or not. */
- (void)downloadedWholeStoreFileWithSuccess:(BOOL)success;

/** Indicate whether the download of the applied sync change sets file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the applied sync change sets file was downloaded or not. */
- (void)downloadedAppliedSyncChangeSetsFileWithSuccess:(BOOL)success;

/** @name Properties */

/** The client identifier for the WholeStore to download. If this is not specified before the operation executes, the operation will determine which client uploaded a store most recently. */
@property (retain) NSString *requestedWholeStoreClientIdentifier;

/** The location of the whole store file to upload. */
@property (retain) NSURL *localWholeStoreFileLocation;

/** The location of the applied sync change sets file to upload. */
@property (retain) NSURL *localAppliedSyncChangeSetsFileLocation;

/** @name Completion */

/** Used to indicate that completion is currently in progress, and that no further checks should be made. */
@property (nonatomic, assign) BOOL completionInProgress;

/** The phase status of the check for which client uploaded a store most recently. */
@property (nonatomic, assign) TICDSOperationPhaseStatus determineMostRecentlyUploadedStoreStatus;

/** The phase status of the whole store file upload. */
@property (nonatomic, assign) TICDSOperationPhaseStatus wholeStoreFileDownloadStatus;

/** The phase status of the applied sync change sets file upload. */
@property (nonatomic, assign) TICDSOperationPhaseStatus appliedSyncChangeSetsFileDownloadStatus;

@end
