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
 
 1. Check whether every object in the store to upload has the `ticdsSyncID` attribute set.
 2. If not, set any missing `ticdsSyncID` attributes.
 3. Check whether a directory exists for this client inside the `WholeStore` directory inside the document's `TemporaryFiles` directory.
 4. If so, delete it.
 5. Create a directory for this client inside the `WholeStore` directory inside the document's `TemporaryFiles` directory.
 6. Upload the whole store file to this temporary directory.
 7. Upload the applied sync change sets file that goes with this whole store to this temporary directory.
 8. Check whether a directory exists for this client inside the document's `WholeStore` directory.
 9. If so, delete it.
 10. Copy the temporary directory the non-temporary location.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSWholeStoreUploadOperation`. */

@interface TICDSWholeStoreUploadOperation : TICDSOperation {
@private
    NSURL *_localWholeStoreFileLocation;
    NSURL *_localAppliedSyncChangeSetsFileLocation;
    
//    NSPersistentStoreCoordinator *_primaryPersistentStoreCoordinator;
//    NSManagedObjectContext *_backgroundApplicationContext;
}

#pragma mark - Overridden Methods
/** @name Methods Overridden by Subclasses */

/** Check whether a directory exists for this client inside the `WholeStore` directory inside the document's `TemporaryFiles` directory.
 
 This method must call `discoveredStatusOfTemporaryWholeStoreDirectory:` to indicate the status. */
- (void)checkWhetherThisClientTemporaryWholeStoreDirectoryExists;

/** Delete the directory for this client inside the `WholeStore` directory inside the document's `TemporaryFiles` directory.
 
 This method must call `deletedThisClientTemporaryWholeStoreDirectoryWithSuccess:` to indicate whether the deletion was successful. */
- (void)deleteThisClientTemporaryWholeStoreDirectory;

/** Create this client's directory inside the `WholeStore` directory inside this document's `TemporaryFiles` directory.
 
 This method must call `createdThisClientTemporaryWholeStoreDirectoryWithSuccess:` to indicate whether the creation was successful. */
- (void)createThisClientTemporaryWholeStoreDirectory;

/** Upload the store at `localWholeStoreFileLocation` to the remote path `/Documents/documentIdentifier/TemporaryFiles/WholeStore/clientIdentifier/WholeStore.ticdsync`.
 
 This method must call `uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:` when finished. */
- (void)uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectory;

/** Upload the file at `localAppliedSyncChangeSetsFileLocation` to the remote path `/Documents/documentIdentifier/TemporaryFiles/WholeStore/clientIdentifier/AppliedSyncChangeSets.ticdsync`.
 
 This method must call `uploadedAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:` when finished. */
- (void)uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectory;

/** Check whether a directory exists for this client inside the document's `WholeStore` directory.
 
 This method must call `discoveredStatusOfThisClientWholeStoreDirectory:` to indicate the status.
 */
- (void)checkWhetherThisClientWholeStoreDirectoryExists;

/** Delete the directory for this client inside this document's `WholeStore` directory.
 
 This method must call `deletedThisClientWholeStoreDirectoryWithSuccess:` to indicate whether the deletion was successful. */
- (void)deleteThisClientWholeStoreDirectory;

/** Copy the entire directory at `/Documents/documentIdentifier/TemporaryFiles/WholeStore/` to `/Documents/documentIdentifier/WholeStore/`.
 
 This method must call `copiedThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectoryWithSuccess:` when finished. */
- (void)copyThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectory;

#pragma mark - Callbacks
/** @name Callbacks */

/** Indicate the status of this client's directory inside the `WholeStore` directory inside the `TemporaryFiles` directory for this document.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfThisClientTemporaryWholeStoreDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the deletion of this client's directory inside the `WholeStore` directory inside the document's `TemporaryFiles` directory was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory was deleted, otherwise `NO`. */
- (void)deletedThisClientTemporaryWholeStoreDirectoryWithSuccess:(BOOL)success;

/** Indicate whether the creation of this client's directory inside the `WholeStore` directory inside the document's `TemporaryFiles` directory was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory was created, otherwise `NO`. */
- (void)createdThisClientTemporaryWholeStoreDirectoryWithSuccess:(BOOL)success;

/** Indicate that the upload of the whole store file made progress.
 */
- (void)uploadingWholeStoreFileToThisClientTemporaryWholeStoreDirectoryMadeProgress;

/** Indicate whether the upload of the whole store file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the file was uploaded, otherwise `NO`. */
- (void)uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:(BOOL)success;

/** Indicate that the upload of the whole store file made progress.
 */
- (void)uploadingLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryMadeProgress;

/** Indicate whether the upload of the applied sync change sets file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the file was uploaded, otherwise `NO`. */
- (void)uploadedAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:(BOOL)success;

/** Indicate the status of this client's directory inside the `WholeStore` directory for this document.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the directory: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfThisClientWholeStoreDirectory:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the deletion of this client's directory inside the document's `WholeStore` directory was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory was deleted, otherwise `NO`. */
- (void)deletedThisClientWholeStoreDirectoryWithSuccess:(BOOL)success;

/** Indicate whether the temporary WholeStore directory was copied to the non-temporary directory location successfully.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the directory was copied, otherwise `NO`. */
- (void)copiedThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectoryWithSuccess:(BOOL)success;

#pragma mark Configuration
/** Configure a background context (for applying sync changes) using the same persistent store coordinator as the main application context.
 
 @param aPersistentStoreCoordinator The persistent store coordinator to use for the background context. */
- (void)configureBackgroundApplicationContextForPrimaryManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

#pragma mark - Properties
/** @name Properties */

/** The location of the whole store file to upload. */
@property (strong) NSURL *localWholeStoreFileLocation;

/** The location of the applied sync change sets file to upload. */
@property (strong) NSURL *localAppliedSyncChangeSetsFileLocation;

/** The persistent store coordinator to use when creating the background context. */
@property (strong) NSManagedObjectContext *primaryManagedObjectContext;
//@property (strong) NSPersistentStoreCoordinator *primaryPersistentStoreCoordinator;

/** The managed object context to use when checking for missing ticdsSyncIDs prior to upload. */
@property (nonatomic, strong) NSManagedObjectContext *backgroundApplicationContext;

@end
