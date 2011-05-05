//
//  TICDSClassesAndProtocols.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#pragma mark -
#pragma mark PRIMARY CLASSES
@class TICDSApplicationSyncManager;
@class TICDSDocumentSyncManager;
@class TICDSSynchronizedManagedObjectContext;
@class TICDSSynchronizedManagedObject;
@class TICDSSyncConflict;

#pragma mark Operations
@class TICDSOperation;
@class TICDSApplicationRegistrationOperation;
@class TICDSDocumentRegistrationOperation;
@class TICDSListOfPreviouslySynchronizedDocumentsOperation;
@class TICDSWholeStoreUploadOperation;
@class TICDSWholeStoreDownloadOperation;
@class TICDSSynchronizationOperation;
@class TICDSVacuumOperation;

#pragma mark File Manager-Based
@class TICDSFileManagerBasedApplicationSyncManager;
@class TICDSFileManagerBasedDocumentSyncManager;
@class TICDSFileManagerBasedApplicationRegistrationOperation;
@class TICDSFileManagerBasedDocumentRegistrationOperation;
@class TICDSFileManagerBasedListOfPreviouslySynchronizedDocumentsOperation;
@class TICDSFileManagerBasedWholeStoreUploadOperation;
@class TICDSFileManagerBasedWholeStoreDownloadOperation;
@class TICDSFileManagerBasedSynchronizationOperation;
@class TICDSFileManagerBasedVacuumOperation;

#pragma mark -
#pragma mark INTERNAL DATA MODEL
@class TICDSSyncChange;
@class TICDSSyncChangeSet;

#pragma mark -
#pragma mark EXTERNAL CLASSES
@class TICoreDataFactory;
@class TIKQDirectoryWatcher;

#pragma mark -
#pragma mark DELEGATE PROTOCOLS
#pragma mark Application Sync Manager
/** The `TICDSApplicationSyncManagerDelegate` protocol defines the methods implemented by delegates of a `TICDSApplicationSyncManager` object. */

@protocol TICDSApplicationSyncManagerDelegate <NSObject>

@optional

#pragma mark Registration
/** @name Registration */

/** Informs the delegate that the sync manager has started the application registration process.
 
 At the end of the registration process, one of the `applicationSyncManger:didFailToRegisterWithError:` or `applicationSyncManagerDidFinishRegistering:` methods will be called.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)applicationSyncManagerDidBeginRegistering:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the registration process failed to complete because of an error.
  
 @param aSyncManager The application sync manager object that sent the message.
 @param anError The error that caused the registration process to fail. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFailToRegisterWithError:(NSError *)anError;

/** Informs the delegate that the registration process completed successfully.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)applicationSyncManagerDidFinishRegistering:(TICDSApplicationSyncManager *)aSyncManager;

#pragma mark Listing Previously Synchronized Documents
/** @name Listing Previously Synchronized Documents */

/** Informs the delegate that the sync manager has started to check for available documents that have previously been synchronized.
 
 At the end of the process, one of the `applicationSyncManager:didFailToCheckForPreviouslySynchronizedDocumentsWithError:`, `applicationSyncManagerDidFinishCheckingAndFoundNoPreviouslySynchronizedDocuments:`, or `applicationSyncManager:didFinishCheckingAndFoundPreviouslySynchronizedDocuments:` methods will be called.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)applicationSyncManagerDidBeginCheckingForPreviouslySynchronizedDocuments:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the sync manager failed to check for available documents that have previously been synchronized.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param anError The error that caused the failure. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFailToCheckForPreviouslySynchronizedDocumentsWithError:(NSError *)anError;

/** Informs the delegate that the sync manager didn't find any available documents that have previously been synchronized.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)applicationSyncManagerDidFinishCheckingAndFoundNoPreviouslySynchronizedDocuments:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the sync manager found one or more available documents that have previously been synchronized.
 
 One `NSDictionary` is supplied per document, containing the following keys:
 
 1. `kTICDSDocumentIdentifier`--the unique synchronization identifier of the document.
 2. `kTICDSDocumentDescription`--the description of the document, as provided when it was originally registered.
 3. `kTICDSOriginalDeviceIdentifier`--the unique identifier of the client that first registered the document.
 4. `kTICDSOriginalDeviceDescription`--the description of the client that first registered the document.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param documentsArray An array of `NSDictionary` objects containing information about each available document. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFinishCheckingAndFoundPreviouslySynchronizedDocuments:(NSArray *)documentsArray;

#pragma mark Downloading a Previously Synchronized Document
/** @name Downloading a Previously Synchronized Document */

/** Informs the delegate that the sync manager has started to download a requested document that has previously been synchronized.
 
 @param aSyncManager The application sync manager object that sent the message.
 @param anIdentifier The unique synchronization identifier of the document. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didBeginDownloadingDocumentWithIdentifier:(NSString *)anIdentifier;

/** Informs the delegate that the download of a requested document has failed to complete because of an error.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param anIdentifier The unique synchronization identifier of the document.
 @param anError The error that caused the download to fail. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFailToDownloadDocumentWithIdentifier:(NSString *)anIdentifier error:(NSError *)anError;

/** Informs the delegate that a downloaded store file file is about to replace an existing store file on disc.
 
 @param aSyncManager The application sync manager object that sent the message.
 @param anIdentifier The unique synchronization identifier of the document.
 @param aFileURL The location on disc of the existing document that will be replaced. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager willReplaceWholeStoreFileForDocumentWithIdentifier:(NSString *)anIdentifier atURL:(NSURL *)aFileURL;

/** Invoked to request the delegate to return a configured (though not yet registered) document sync manager for a downloaded document.
 
 This method will be called once the whole store has been replaced for the document. You should create a suitable document sync manager for the downloaded store, and configure it by calling `configureWithDelegate:appSyncManager:documentIdentifier:`;
 
 Do not register the document sync manager until after the `applicationSyncManager:didFinishDownloadingDocumentWithIdentifier:atURL:` method is called.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anIdentifier The unique synchronization identifier for the document.
 @param aFileURL The location on disc of the downloaded document.
 
 @return The pre-configured, unregistered sync manager for the document. */
@required
- (TICDSDocumentSyncManager *)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager preConfiguredDocumentSyncManagerForDownloadedDocumentWithIdentifier:(NSString *)anIdentifier atURL:(NSURL *)aFileURL;
@optional
/** Informs the delegate that the download of a requested document has completed successfully.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param anIdentifier The unique synchronization identifier of the document.
 @param aFileURL The location of the downloaded store file. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFinishDownloadingDocumentWithIdentifier:(NSString *)anIdentifier atURL:(NSURL *)aFileURL;
@end

#pragma mark Document Sync Manager
/** The `TICDSDocumentSyncManagerDelegate` protocol defines the methods implemented by delegates of a `TICDSDocumentSyncManager` object. */

@protocol TICDSDocumentSyncManagerDelegate <NSObject>

@optional

#pragma mark Registration
/** @name Registration Phase */

/** Informs the delegate that the sync manager has started the document registration process.
 
 If an error occurs during document registration, the `syncManager:encounteredDocumentRegistrationError:` method will be called.
 
 At the end of the registration process, one of the `syncManagerFailedToRegisterDocument:` or `syncManagerDidRegisterDocumentSuccessfully:` methods will be called.

 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerDidStartDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the sync manager encountered an error during the document registration process.
 
 @param aSyncManager The document sync manager object that sent the message. 
 @param anError The error that was encountered. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager encounteredDocumentRegistrationError:(NSError *)anError;

/** Informs the delegate that the sync manager paused the document registration process because the remote file structure does not yet exist for the specified document.
 
 @param aSyncManager The document sync manager object that sent the message. 
 @param anIdentifier The unique identifier for the document (as supplied at registration).
 @param aDescription The description of the document (as supplied at registration).
 @param userInfo The user info dictionary (as supplied at registration).
 
 @warning You *must* call the `continueRegistrationByCreatingRemoteFileStructure:` method to indicate whether registration should continue or not.
 */
@required
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo;

@optional

/** Informs the delegate that the sync manager has resumed the document registration process.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerDidResumeRegistration:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the sync manager failed to complete the document registration process.
 
 The error will previously have been supplied through the `syncManager:encounteredDocumentRegistrationError:` method.

 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerFailedToRegisterDocument:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the registration process completed successfully.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerDidRegisterDocumentSuccessfully:(TICDSDocumentSyncManager *)aSyncManager;

#pragma mark Helper Files
/** @name Helper Files */

/** Invoked to allow the delegate to return a custom location for a local directory to contain the helper files the `TICoreDataSync` framework uses to synchronize a document.
 
 If you don't implement this method, the default location will be `~/Library/Application Support/ApplicationName/Documents/documentIdentifier/`.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anIdentifier The unique identifier for the document (as supplied at registration).
 @param aDescription The description of the document (as supplied at registration).
 @param userInfo The user info dictionary (as supplied at registration).
 
 @return The `NSURL` for the location you wish to use.
 
 @warning The location you specify *must* already exist. */
- (NSURL *)syncManager:(TICDSDocumentSyncManager *)aSyncManager helperFileDirectoryLocationForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo;

#pragma mark Whole Store Upload
/** @name Whole Store Upload */

/** Invoked to ask the delegate whether the document sync manager should automatically initiate a Whole Store Upload at registration.
 
 @param aSyncManager The document sync manager object that sent the message.
 
 @return A Boolean indicating whether to initiate the upload. */
- (BOOL)syncManagerShouldUploadWholeStoreAfterDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager;

/** Invoked to ask the delegate for the URL of the document's SQLite store to upload.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anIdentifier The unique identifier for the document (as supplied at registration).
 @param aDescription The description of the document (as supplied at registration).
 @param userInfo The user info dictionary (as supplied at registration).
 
 @return The location of the store file. */
@required
- (NSURL *)syncManager:(TICDSDocumentSyncManager *)aSyncManager URLForWholeStoreToUploadForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo;
@optional

/** Informs the delegate that the document sync manager has begun to upload the whole store file, together with necessary helper files.
 
 If an error occurs during the upload process, the `syncManager:encounteredWholeStoreUploadError:` method will be called.
 
 At the end of the upload process, one of the `syncManagerFailedToUploadWholeStore:` or `syncManagerDidUploadWholeStoreSuccessfully:` methods will be called.

 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerDidBeginToUploadWholeStore:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager encountered an error during the whole store upload.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anError The error. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager encounteredWholeStoreUploadError:(NSError *)anError;

/** Informs the delegate that the document sync manager failed to upload the whole store file.
 
 The error will previously have been supplied through the `syncManager:encounteredWholeStoreUploadError:` method.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerFailedToUploadWholeStore:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager finished uploading the whole store file successfully.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerDidUploadWholeStoreSuccessfully:(TICDSDocumentSyncManager *)aSyncManager;

#pragma mark Whole Store Download
/** @name Whole Store Download */

/** Invoked to ask the delegate for the URL of the document's store once it's been downloaded.
 
 If this method is not implemented, the sync manager will ask the synchronized persistent store coordinator for the location of its `persistentStores` array's `lastObject`.
 
 @param aSyncManager The document sync manager object that sent the message.
 
 @return The location of the store file. */
- (NSURL *)syncManagerFinalURLForDownloadedStore:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager has begun to download the whole store file, together with necessary helper files.
 
 If an error occurs during the download process, the `syncManager:encounteredWholeStoreDownloadError:` method will be called.
 
 The store will be downloaded to a temporary location; once this has happened, the `syncManager:willReplaceStoreWithDownloadedStoreAtLocation:` method will be called just before the store is moved to the location given by the `syncManagerFinalURLForDownloadedStore:` method to allow you to remove the file from any persistent store coordinators. Once the file has been moved, the `syncManager:didReplaceStoreWithDownloadedStoreAtLocation:` method will be called.
 
 At the end of the download process, one of the `syncManagerFailedToDownloadWholeStore:` or `syncManagerDidDownloadWholeStoreSuccessfully:` methods will be called.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerDidBeginToDownloadWholeStore:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager has downloaded the store to a temporary location, and is about to replace the store at the given location.
 
 You should remove the given store from the persistent store coordinator.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aLocation The location of the persistent store that will be replaced. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager willReplaceStoreWithDownloadedStoreAtLocation:(NSURL *)aLocation;

/** Informs the delegate that the document sync manager has replaced the store at the given location with the downloaded store.
 
 You should add the store back for the persistent store coordinator.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aLocation The location of the persistent store that was replaced. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager didReplaceStoreWithDownloadedStoreAtLocation:(NSURL *)aLocation;

/** Informs the delegate that the document sync manager encountered an error during the whole store upload.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anError The error. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager encounteredWholeStoreDownloadError:(NSError *)anError;

/** Informs the delegate that the document sync manager failed to upload the whole store file.
 
 The error will previously have been supplied through the `syncManager:encounteredWholeStoreUploadError:` method.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerFailedToDownloadWholeStore:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager finished uploading the whole store file successfully.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerDidDownloadWholeStoreSuccessfully:(TICDSDocumentSyncManager *)aSyncManager;

#pragma mark Synchronization

/** @name Synchronization */

/** Informs the delegate that the document sync manager has begun to synchronize the document.
 
 If an error occurs during the upload process, the `syncManager:encounteredSynchronizationError:` method will be called.
 
 At the end of the synchronization process, one of the `syncManagerFailedToSynchronize:` or `syncManagerDidFinishSynchronization:` methods will be called.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerDidBeginToSynchronize:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the sychronization process was paused because a conflict was detected.
 
 @param aSyncManager The document sync manager object that sent the message. 
 @param aConflict The conflict.
 
 @warning You *must* call the `continueSynchronizationByResolvingConflictWithResolutionType:` method to indicate whether registration should continue or not. */
@required
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseSynchronizationAwaitingResolutionOfSyncConflict:(id)aConflict;
@optional

/** Informs the delegate that the synchronization process continue after a conflict was resolved.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerDidResumeSynchronization:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that changes were made to managed objects in the application's context on a background thread during the synchronization process.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aNotification The `NSManagedObjectContextDidSave` notification object containing changes made to objects. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager didMakeChangesToObjectsInBackgroundContextAndSaveWithNotification:(NSNotification *)aNotification;

/** Informs the delegate that the document sync manager encountered an error during the synchronization process.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anError The error. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager encounteredSynchronizationError:(NSError *)anError;

/** Informs the delegate that warnings were generated during the synchronization process.
 
 Warnings indicate that e.g., an object was changed locally but deleted remotely.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param warnings An array of `NSDictionary` objects containing information about each warning. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager encounteredSynchronizationWarnings:(NSArray *)warnings;

/** Informs the delegate that the document sync manager failed to synchronize the document.
 
 The error will previously have been supplied through the `syncManager:encounteredSynchronizationError:` method.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerFailedToSynchronize:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager finished synchronizing the document.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerDidFinishSynchronization:(TICDSDocumentSyncManager *)aSyncManager;

#pragma mark Vacuuming
/** @name Vacuuming Unneeded Files */

/** Invoked to ask the delegate whether the document sync manager should automatically remove unneeded files at registration.
 
 @param aSyncManager The document sync manager object that sent the message.
 
 @return A Boolean indicating whether to initiate the vacuum. */
- (BOOL)syncManagerShouldVacuumUnneededRemoteFilesAfterDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the sync manager has begun to remove unneeded files from the remote.
 
 If an error occurs during the vacuum process, the `syncManager:encounteredVacuumError:` method will be called.
 
 At the end of the vacuum process, one of the `syncManagerFailedToVacuumUnneededRemoteFiles:` or `syncManagerDidFinishVacuumingUnneededRemoteFiles:` methods will be called.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerDidBeginToVacuumUnneededRemoteFiles:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the sync manager encountered an error wile vacuuming unneeded files from the remote.
 
 @param aSyncManager The document sync manager object that sent the message. 
 @param anError The error that was encountered. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager encounteredVacuumError:(NSError *)anError;

/** Informs the delegate that the document sync manager failed to vacuum unneeded files on the remote.
 
 The error will previously have been supplied through the `syncManager:encounteredVacuumError:` method.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerFailedToVacuumUnneededRemoteFiles:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager finished vacuuming unneeded files from the remote.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)syncManagerDidFinishVacuumingUnneededRemoteFiles:(TICDSDocumentSyncManager *)aSyncManager;

#pragma mark Processing
/** @name Processing after Managed Object Context save */

/** Informs the delegate that the sync manager has begun to process the changes that have occurred since the previous `save:` of the managed object context.
 
 At the end of the process, one of the `syncManager:failedToProcessAfterMOCDidSave:` or `syncManager:didFinishProcessingAfterMOCDidSave` methods will be called.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aMoc The managed object context. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager didBeginProcessingAfterMOCDidSave:(TICDSSynchronizedManagedObjectContext *)aMoc;

/** Informs the delegate that the sync manager failed to process the changes that have occurred since the previous `save:` of the managed object context.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aMoc The managed object context. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager failedToProcessAfterMOCDidSave:(TICDSSynchronizedManagedObjectContext *)aMoc;

/** Informs the delegate that the sync manager finished processing the changes that have occurred since the previous `save:` of the managed object context.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aMoc The managed object context. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager didFinishProcessingAfterMOCDidSave:(TICDSSynchronizedManagedObjectContext *)aMoc;

/** Invoked to ask the delegate whether the document sync manager should automatically initiate Synchronization after finishing processing changes in a synchronized managed object context.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aMoc The managed object context that saved.
 
 @return A Boolean indicating whether to initiate the upload. */
- (BOOL)syncManager:(TICDSDocumentSyncManager *)aSyncManager shouldInitiateSynchronizationAfterSaveOfContext:(TICDSSynchronizedManagedObjectContext *)aMoc;

@end

#pragma mark -
#pragma mark OPERATION DELEGATE PROTOCOLS
#pragma mark Generic Operation Delegate
/** The `TICDSOperationDelegate` protocol defines the methods implemented by delegates of any generic `TICDSOperation`. In the `TICoreDataSync` framework, these delegate methods are implemented by the application and document sync managers. */

@protocol TICDSOperationDelegate <NSObject>

/** Informs the delegate that the operation has completely and successfully finished its tasks.
 
 @param anOperation The operation object that sent the message. */
- (void)operationCompletedSuccessfully:(TICDSOperation *)anOperation;

/** Informs the delegate that the operation was cancelled before it could finish its tasks.
 
 @param anOperation The operation object that sent the message. */
- (void)operationWasCancelled:(TICDSOperation *)anOperation;

/** Informs the delegate that the operation failed to complete before it could finish its tasks.
 
 @param anOperation The operation object that sent the message. */
- (void)operationFailedToComplete:(TICDSOperation *)anOperation;

@end

#pragma mark Document Registration Operation Delegate
/** The `TICDSDocumentRegistrationOperationDelegate` protocol defines the methods implemented by delegates of `TICDSDocumentRegistrationOperation` or one of its subclasses. In the `TICoreDataSync` framework, these delegate methods are implemented by the document sync manager. */

@protocol TICDSDocumentRegistrationOperationDelegate <TICDSOperationDelegate>

/** Informs the delegate that the operation has been paused because the remote document file structure does not exist. The delegate should query its own delegate to ask whether to continue registration by creating the structure.
 
 @param anOperation The operation object that sent the message. */
- (void)registrationOperationPausedToFindOutWhetherToCreateRemoteDocumentStructure:(TICDSDocumentRegistrationOperation *)anOperation;

/** Informs the delegate that the operation has resumed after being told whether or not to create the remote document file structure.
 
 @param anOperation The operation object that sent the message. */
- (void)registrationOperationResumedFollowingDocumentStructureCreationInstruction:(TICDSDocumentRegistrationOperation *)anOperation;

@end

#pragma mark Synchronization Operation Delegate
/** The `TICDSSynchronizationOperationDelegate` protocol defines the methods implemented by delegates of `TICDSSynchronizationOperation` or one of its subclasses. In the `TICoreDataSync` framework, these delegate methods are implemented by the document sync manager. */

@protocol TICDSSynchronizationOperationDelegate <TICDSOperationDelegate>

/** Informs the delegate that the operation has been paused because of a conflict. The delegate should query its own delegate to ask how to resolve the conflict.
 
 @param anOperation The operation object that sent the message.
 @param aConflict The conflict. */
- (void)synchronizationOperation:(TICDSSynchronizationOperation *)anOperation pausedToDetermineResolutionOfConflict:(id)aConflict;

/** Informs the delegate that the operation has resumed after being told how to resolve the conflict. 
 
 @param anOperation The operation object that sent the message. */
- (void)synchronizationOperationResumedFollowingResolutionOfConflict:(TICDSSynchronizationOperation *)anOperation;

@end