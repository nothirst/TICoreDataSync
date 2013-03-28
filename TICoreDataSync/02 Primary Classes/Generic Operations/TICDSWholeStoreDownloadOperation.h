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
    
    NSString *_integrityKey;
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

/** Fetch the integrity key for this document.
 
 This method must call `fetchedRemoteIntegrityKey:` to provide the key. */
- (void)fetchRemoteIntegrityKey;

/** @name Callbacks */

/** Indicate which client uploaded the most recent WholeStore.
 
 If an error occurs, call `setError:` first, then specify `nil` for `anIdentifier`
 
 @param anIdentifier The identifier of the client. */
- (void)determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:(NSString *)anIdentifier;

/** Indicate when the download operation makes progress. */
-(void)downloadingWholeStoreFileMadeProgress;

/** Indicate whether the download of the whole store file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the whole store file was downloaded, otherwise `NO`. */
- (void)downloadedWholeStoreFileWithSuccess:(BOOL)success;

/** Indicate when the download operation makes progress. */
- (void)downloadingAppliedSyncChangeSetsFileMadeProgress;

/** Indicate whether the download of the applied sync change sets file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the applied sync change sets file was downloaded, otherwise `NO`. */
- (void)downloadedAppliedSyncChangeSetsFileWithSuccess:(BOOL)success;

/** Pass back the remote integrity key for this document.
 
 If an error occurred, call `setError:` first, then specify `nil` for `aKey`.
 
 @param aKey The remote integrity key, or `nil` if an error occurred. */
- (void)fetchedRemoteIntegrityKey:(NSString *)aKey;

/** @name Properties */

/** The client identifier for the WholeStore to download. If this is not specified before the operation executes, the operation will determine which client uploaded a store most recently. */
@property (copy) NSString *requestedWholeStoreClientIdentifier;

/** The destination for the whole store file. */
@property (strong) NSURL *localWholeStoreFileLocation;

/** The destination for the applied sync change sets file. */
@property (strong) NSURL *localAppliedSyncChangeSetsFileLocation;

/** The integrity key of the newly-downloaded store. */
@property (copy) NSString *integrityKey;

@end
