//
//  TICDSClassesAndProtocols.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#pragma mark - PRIMARY CLASSES
@class TICDSApplicationSyncManager;
@class TICDSDocumentSyncManager;
@class TICDSSynchronizedManagedObject;
@class TICDSSyncConflict;
@class TICDSSynchronizationOperationManagedObjectContext;
@class TICDSSyncTransaction;

#pragma mark Operations
@class TICDSOperation;
@class TICDSApplicationRegistrationOperation;
@class TICDSDocumentRegistrationOperation;
@class TICDSListOfPreviouslySynchronizedDocumentsOperation;
@class TICDSWholeStoreUploadOperation;
@class TICDSWholeStoreDownloadOperation;
@class TICDSSynchronizationOperation;
@class TICDSVacuumOperation;
@class TICDSListOfDocumentRegisteredClientsOperation;
@class TICDSListOfApplicationRegisteredClientsOperation;
@class TICDSDocumentDeletionOperation;
@class TICDSDocumentClientDeletionOperation;
@class TICDSRemoveAllRemoteSyncDataOperation;

#pragma mark File Manager-Based
@class TICDSFileManagerBasedApplicationSyncManager;
@class TICDSFileManagerBasedDocumentSyncManager;
@class TICDSFileManagerBasedApplicationRegistrationOperation;
@class TICDSFileManagerBasedDocumentRegistrationOperation;
@class TICDSFileManagerBasedListOfPreviouslySynchronizedDocumentsOperation;
@class TICDSFileManagerBasedWholeStoreUploadOperation;
@class TICDSFileManagerBasedWholeStoreDownloadOperation;
@class TICDSFileManagerBasedPreSynchronizationOperation;
@class TICDSFileManagerBasedPostSynchronizationOperation;
@class TICDSFileManagerBasedVacuumOperation;
@class TICDSFileManagerBasedListOfDocumentRegisteredClientsOperation;
@class TICDSFileManagerBasedListOfApplicationRegisteredClientsOperation;
@class TICDSFileManagerBasedDocumentDeletionOperation;
@class TICDSFileManagerBasedDocumentClientDeletionOperation;
@class TICDSFileManagerBasedRemoveAllRemoteSyncDataOperation;

#pragma mark DropboxSDK-Based
@class TICDSDropboxSDKBasedApplicationSyncManager;
@class TICDSDropboxSDKBasedDocumentSyncManager;
@class TICDSDropboxSDKBasedApplicationRegistrationOperation;
@class TICDSDropboxSDKBasedDocumentRegistrationOperation;
@class TICDSDropboxSDKBasedListOfPreviouslySynchronizedDocumentsOperation;
@class TICDSDropboxSDKBasedWholeStoreUploadOperation;
@class TICDSDropboxSDKBasedWholeStoreDownloadOperation;
@class TICDSDropboxSDKBasedVacuumOperation;
@class TICDSDropboxSDKBasedListOfDocumentRegisteredClientsOperation;
@class TICDSDropboxSDKBasedListOfApplicationRegisteredClientsOperation;
@class TICDSDropboxSDKBasedDocumentDeletionOperation;
@class TICDSDropboxSDKBasedDocumentClientDeletionOperation;
@class TICDSDropboxSDKBasedRemoveAllRemoteSyncDataOperation;

#pragma mark - INTERNAL DATA MODEL
@class TICDSSyncChange;
@class TICDSSyncChangeSet;

#pragma mark - UTILITIES - ENCRYPTION
@class FZACryptor;
@class FZAKeyManager;
#if (TARGET_OS_IPHONE)
@class FZAKeyManageriPhone;
#else
@class FZAKeyManagerMac;
#endif

#pragma mark - EXTERNAL CLASSES
@class TICoreDataFactory;
@class TIKQDirectoryWatcher;

#pragma mark - Whole Store Compression
@class SSZipArchive;

#pragma mark - DELEGATE PROTOCOLS
#pragma mark Sync Transaction

/** The `TICDSSyncTransactionDelegate` protocol defines the methods implemented by delegates of a `TICDSSyncTransaction` object. */
@protocol TICDSSyncTransactionDelegate <NSObject>

/** Informs the delegate that the sync transaction is ready to be closed.
  
 @param syncTransaction The sync transaction object that sent the message.
*/
- (void)syncTransactionIsReadyToBeClosed:(TICDSSyncTransaction *)syncTransaction;

@end

#pragma mark Application Sync Manager
/** The `TICDSApplicationSyncManagerDelegate` protocol defines the methods implemented by delegates of a `TICDSApplicationSyncManager` object. */

@protocol TICDSApplicationSyncManagerDelegate <NSObject>

@optional

#pragma mark Registration
/** @name Registration */

/** Informs the delegate that the application sync manager has started the application registration process.
 
 At the end of the registration process, one of the `applicationSyncManager:didFailToRegisterWithError:` or `applicationSyncManagerDidFinishRegistering:` methods will be called.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)applicationSyncManagerDidBeginRegistering:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the application sync manager paused the application registration process to find out whether to use encryption for this application, because this is the first time this application has been registered.
 
 @param aSyncManager The application sync manager object that sent the message. 
 
 @warning You *must* call the `continueRegisteringWithEncryptionPassword:` method to indicate whether registration should use an encryption password, or stay unencrypted, otherwise the registration process will be left permanently suspended. */
@required
- (void)applicationSyncManagerDidPauseRegistrationToAskWhetherToUseEncryptionForFirstTimeRegistration:(TICDSApplicationSyncManager *)aSyncManager;
@optional

/** Informs the delegate that the application sync manager paused the application registration process because a password is needed to work with this application's encrypted data.
 
 @param aSyncManager The application sync manager object that sent the message.
 
 @warning You *must* call the `continueRegisteringWithEncryptionPassword:` method to indicate the password to use, or the registration process will be left permanently suspended. */
@required
- (void)applicationSyncManagerDidPauseRegistrationToRequestPasswordForEncryptedApplicationSyncData:(TICDSApplicationSyncManager *)aSyncManager;
@optional

/** Informs the delegate that the application sync manager has resumed the application registration process.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)applicationSyncManagerDidContinueRegistering:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the application sync manager failed to register the application because of an error.
  
 @param aSyncManager The application sync manager object that sent the message.
 @param anError The error that caused the registration process to fail. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFailToRegisterWithError:(NSError *)anError;

/** Informs the delegate that the application sync manager finished registering the application successfully.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)applicationSyncManagerDidFinishRegistering:(TICDSApplicationSyncManager *)aSyncManager;

/** Asks the delegate whether or not the application sync manager should support continued operation processing after the app has been sent to a background state. If this delegate method isn't implemented the application sync manager defaults to YES and will process items in the background. Background processing currently only applies to sync operations running on iOS.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (BOOL)applicationSyncManagerShouldSupportProcessingInBackgroundState:(TICDSApplicationSyncManager *)aSyncManager;

/** Asks the delegate whether or not the application sync manager should support compressing the whole store file when transferring it between the local and remote locations. If this delegate method isn't implemented the application sync manager defaults to YES and will compress the whole store.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (BOOL)applicationSyncManagerShouldUseCompressionForWholeStoreMoves:(TICDSApplicationSyncManager *)aSyncManager;

#pragma mark Listing Previously Synchronized Documents
/** @name Listing Previously Synchronized Documents */

/** Informs the delegate that the application sync manager has started to check for available documents that have previously been synchronized.
 
 At the end of the process, one of the `applicationSyncManager:didFailToCheckForPreviouslySynchronizedDocumentsWithError:`, `applicationSyncManagerDidFinishCheckingAndFoundNoPreviouslySynchronizedDocuments:`, or `applicationSyncManager:didFinishCheckingAndFoundPreviouslySynchronizedDocuments:` methods will be called.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)applicationSyncManagerDidBeginCheckingForPreviouslySynchronizedDocuments:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the application sync manager failed to check for available documents that have previously been synchronized.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param anError The error that caused the failure. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFailToCheckForPreviouslySynchronizedDocumentsWithError:(NSError *)anError;

/** Informs the delegate that the application sync manager didn't find any available documents that have previously been synchronized.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)applicationSyncManagerDidFinishCheckingAndFoundNoPreviouslySynchronizedDocuments:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the application sync manager found one or more available documents that have previously been synchronized.
 
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

/** Informs the delegate that the application sync manager has started to download a requested document that has previously been synchronized.
 
 @param aSyncManager The application sync manager object that sent the message.
 @param anIdentifier The unique synchronization identifier of the document. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didBeginDownloadingDocumentWithIdentifier:(NSString *)anIdentifier;

/** Informs the delegate that the application sync manager failed to download a requested document because of an error.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param anIdentifier The unique synchronization identifier of the document.
 @param anError The error that caused the download to fail. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFailToDownloadDocumentWithIdentifier:(NSString *)anIdentifier error:(NSError *)anError;

/** Informs the delegate that the application sync manager is about to replace an existing store file on disc with a newly-downloaded file.
 
 @param aSyncManager The application sync manager object that sent the message.
 @param anIdentifier The unique synchronization identifier of the document.
 @param aFileURL The location on disc of the existing document that will be replaced. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager willReplaceWholeStoreFileForDocumentWithIdentifier:(NSString *)anIdentifier atURL:(NSURL *)aFileURL;

/** Invoked to request the delegate to return a configured (though not yet registered) document sync manager for a downloaded document.
 
 This method will be called once the whole store has been replaced for the document. You should create a suitable document sync manager for the downloaded store, and *configure* it by calling `preConfigureWithDelegate:appSyncManager:documentIdentifier:`;
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anIdentifier The unique synchronization identifier for the document.
 @param aFileURL The location on disc of the downloaded document.
 
 @return The pre-configured, unregistered sync manager for the document. 
 
 @warning Do not *register* the document sync manager until after the `applicationSyncManager:didFinishDownloadingDocumentWithIdentifier:atURL:` method is called. 
 
 When you do register, you must use the full `registerWithDelegate:appSyncManager:managedObjectContext:documentIdentifier:description:userInfo:` method, and not the `registerConfiguredDocumentSyncManager` method. The latter is used for the delayed registration option; a *pre-configured* document sync manager is not the same as a *configured* document sync manager. */
@required
- (TICDSDocumentSyncManager *)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager preConfiguredDocumentSyncManagerForDownloadedDocumentWithIdentifier:(NSString *)anIdentifier atURL:(NSURL *)aFileURL;
@optional

/** Informs the delegate that the application sync manager finished downloading a requested document successfully.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param anIdentifier The unique synchronization identifier of the document.
 @param aFileURL The location of the downloaded store file. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFinishDownloadingDocumentWithIdentifier:(NSString *)anIdentifier atURL:(NSURL *)aFileURL;

/** Informs the delegate on the operation's progress being made in the download operation.
 
 @param aSyncManager The application sync manager object that sent the message.
 @param anIdentifier The unique synchronization identifier of the document.
 @param progress The progress level (0 to 1) as reported by the operation. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager whileDownloadingDocumentWithIdentifier:(NSString *)anIdentifier didReportProgress:(CGFloat)progress;


#pragma mark Registered Client Information
/** @name Registered Client Information */

/** Informs the delegate that the application sync manager has begun to fetch information on all registered devices from the remote.
 
 At the end of the request process, one of the `applicationSyncManager:didFailToFetchInformationForAllRegisteredDevicesWithError:` or `applicationSyncManagerDidFinishFetchingInformationForAllRegisteredDevices:` methods will be called.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)applicationSyncManagerDidBeginToFetchInformationForAllRegisteredDevices:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the application sync manager failed to fetch information on clients registered to synchronize with the application. 
 
 @param aSyncManager The application sync manager object that sent the message.
 @param anError The error that caused the request process to fail. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFailToFetchInformationForAllRegisteredDevicesWithError:(NSError *)anError;

/** Informs the delegate that the application sync manager finished fetching information for all registered devices for this application.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param information A dictionary containing as keys the unique synchronization identifiers of each client, and as values dictionaries of information about that client. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFinishFetchingInformationForAllRegisteredDevices:(NSDictionary *)information;

#pragma mark Document Deletion
/** @name Document Deletion */

/** Informs the delegate that the application sync manager has begun the process of deleting a document from the remote.
 
 When the document directory is about to be deleted, the `applicationSyncManager:willDeleteDirectoryForDocumentWithIdentifier:` method will be called. Once the directory has been deleted, the `applicationSyncManager:didDeleteDirectoryForDocumentWithIdentifier:` method will be called.
 
 At the end of the process, one of the `applicationSyncManager:didFailToDeleteDocumentWithIdentifier:error:` or `applicationSyncManager:didFinishDeletingDocumentWithIdentifier:` methods will be called.
 
 @param aSyncManager The application sync manager object that sent the message.
 @param anIdentifier The identifier for the document that will be deleted. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didBeginDeletionProcessForDocumentWithIdentifier:(NSString *)anIdentifier;

/** Informs the delegate that the application sync manager failed to delete a document. 
 
 @param aSyncManager The application sync manager object that sent the message.
 @param anIdentifier The identifier of the document that wasn't deleted.
 @param anError The error that caused the request process to fail. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFailToDeleteDocumentWithIdentifier:(NSString *)anIdentifier error:(NSError *)anError;

/** Informs the delegate that the document's directory is about to be removed from the remote.
 
 @param aSyncManager The application sync manager object that sent the message.
 @param anIdentifier The identifier of the document that will be deleted. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager willDeleteDirectoryForDocumentWithIdentifier:(NSString *)anIdentifier;

/** Informs the delegate that the document's directory has just been removed from the remote.
 
 @param aSyncManager The application sync manager object that sent the message.
 @param anIdentifier The identifier of the document that was deleted. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didDeleteDirectoryForDocumentWithIdentifier:(NSString *)anIdentifier;

/** Informs the delegate that the application sync manager completed the deletion process for the specified document.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param anIdentifier The identifier of the document that was deleted. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFinishDeletingDocumentWithIdentifier:(NSString *)anIdentifier;

#pragma mark Removing all Remote Sync Data
/** @name Removing all Remote Sync Data */

/** Informs the delegate that the application sync manager will remove the entire remote directory structure.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)applicationSyncManagerWillRemoveAllSyncData:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the application sync manager has successfully removed the entire remote directory structure.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)applicationSyncManagerDidFinishRemovingAllSyncData:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the application sync manager failed to remove the entire remote directory structure.
 
 @param aSyncManager The application sync manager object that sent the message.
 @param anError The error that caused the deletion process to fail. */
- (void)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager didFailToRemoveAllSyncDataWithError:(NSError *)anError;

@end

#pragma mark Document Sync Manager
/** The `TICDSDocumentSyncManagerDelegate` protocol defines the methods implemented by delegates of a `TICDSDocumentSyncManager` object. */

@protocol TICDSDocumentSyncManagerDelegate <NSObject>

@optional

#pragma mark Registration
/** @name Registration Phase */

/** Informs the delegate that the document sync manager has started the document registration process.
 
 At the end of the registration process, one of the `documentSyncManager:didFailToRegisterWithError:` or `documentSyncManagerDidFinishRegistering:` methods will be called.

 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidBeginRegistering:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager paused the document registration process because the remote file structure does not yet exist for the specified document.
 
 @param aSyncManager The document sync manager object that sent the message. 
 @param anIdentifier The unique identifier for the document (as supplied at registration).
 @param aDescription The description of the document (as supplied at registration).
 @param userInfo The user info dictionary (as supplied at registration).
 
 @warning You *must* call the `continueRegistrationByCreatingRemoteFileStructure:` method to indicate whether registration should continue or not.
 */
@required
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo;

@optional

/** Informs the delegate that the document sync manager paused the document registration process because the remote file structure has previously been deleted for the specified document.
 
 @param aSyncManager The document sync manager object that sent the message. 
 @param anIdentifier The unique identifier for the document (as supplied at registration).
 @param aDescription The description of the document (as supplied at registration).
 @param userInfo The user info dictionary (as supplied at registration).
 
 @warning You *must* call the `continueRegistrationByCreatingRemoteFileStructure:` method to indicate whether registration should continue or not.
 */
@required
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseRegistrationAsRemoteFileStructureWasDeletedForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo;

@optional

/** Informs the delegate that the document sync manager has resumed the document registration process.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidContinueRegistering:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager failed to complete the document registration process.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anError The error that caused the registration process to fail. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFailToRegisterWithError:(NSError *)anError;

/** Informs the delegate that the client had previously been deleted from synchronizing this document.
 
 The client should alert the user, and download the store once registration has finished.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidDetermineThatClientHadPreviouslyBeenDeletedFromSynchronizingWithDocument:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager finished registering the document successfully.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidFinishRegistering:(TICDSDocumentSyncManager *)aSyncManager;

/** Asks the delegate whether or not the document sync manager should support continued operation processing after the app has been sent to a background state. .
 
 @param aSyncManager The document sync manager object that sent the message. */
- (BOOL)documentSyncManagerShouldSupportProcessingInBackgroundState:(TICDSDocumentSyncManager *)aSyncManager;

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
- (NSURL *)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager helperFileDirectoryURLForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo;

#pragma mark Whole Store Upload
/** @name Whole Store Upload */

/** Invoked to ask the delegate whether the document sync manager should automatically initiate a Whole Store Upload at registration.
 
 @param aSyncManager The document sync manager object that sent the message.
 
 @return `YES` if the sync manager should initiate the upload, otherwise `NO`. */
- (BOOL)documentSyncManagerShouldUploadWholeStoreAfterDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager;

/** Invoked to ask the delegate for the URL of the document's persistent store to upload.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anIdentifier The unique identifier for the document (as supplied at registration).
 @param aDescription The description of the document (as supplied at registration).
 @param userInfo The user info dictionary (as supplied at registration).
 
 @return The location of the store file. */
@required
- (NSURL *)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager URLForWholeStoreToUploadForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo;
@optional

/** Informs the delegate that the document sync manager has begun to upload the whole store file, together with necessary helper files.
 
 At the end of the upload process, one of the `documentSyncManager:didFailToUploadWholeStoreWithError:` or `documentSyncManagerDidFinishUploadingWholeStore:` methods will be called.

 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidBeginUploadingWholeStore:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager failed to upload the whole store file.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anError The error that caused the upload to fail. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFailToUploadWholeStoreWithError:(NSError *)anError;

/** Informs the delegate that the document sync manager finished uploading the whole store file successfully.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidFinishUploadingWholeStore:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate on the operation's progress being made in the upload operation.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param progress The progress level (0 to 1) as reported by the operation. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager whileUploadingWholeStoreDidReportProgress:(CGFloat)progress;

#pragma mark Whole Store Download
/** @name Whole Store Download */

/** Invoked to ask the delegate for the URL of the document's store once it has been downloaded.
 
 If this method is not implemented, the sync manager will ask the persistent store coordinator of the primary synchronized managed object context (the one specified at registration) for the location of its `persistentStores` array's `lastObject`.
 
 @param aSyncManager The document sync manager object that sent the message.
 
 @return The location of the store file. */
- (NSURL *)documentSyncManagerURLForDownloadedStore:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager has begun to download the whole store file, together with necessary helper files.
 
 The store will be downloaded to a temporary location; once this has happened, the `documentSyncManager:willReplaceStoreWithDownloadedStoreAtURL:` method will be called just before the store is moved to the location given by the `documentSyncManagerURLForDownloadedStore:` method to allow you to remove the store file from any persistent store coordinators. Once the file has been moved, the `documentSyncManager:didReplaceStoreWithDownloadedStoreAtURL:` method will be called.
 
 At the end of the download process, one of the `documentSyncManager:didFailToDownloadWholeStoreWithError:` or `documentSyncManagerDidFinishDownloadingWholeStore:` methods will be called.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidBeginDownloadingWholeStore:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager has downloaded the store to a temporary location, and is about to replace the store at the given location.
 
 You should remove the given store from the persistent store coordinator.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aStoreURL The location of the persistent store that will be replaced. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager willReplaceStoreWithDownloadedStoreAtURL:(NSURL *)aStoreURL;

/** Informs the delegate that the document sync manager has replaced the store at the given location with the downloaded store.
 
 You should add the store back for the persistent store coordinator.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aStoreURL The location of the persistent store that was replaced. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didReplaceStoreWithDownloadedStoreAtURL:(NSURL *)aStoreURL;

/** Informs the delegate that the document sync manager failed to download the whole store file.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anError The error that caused the download to fail. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFailToDownloadWholeStoreWithError:(NSError *)anError;

/** Informs the delegate that the document sync manager finished downloading the whole store file successfully.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidFinishDownloadingWholeStore:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate on the operation's progress being made in the download operation.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param progress The progress level (0 to 1) as reported by the operation. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager whileDownloadingWholeStoreDidReportProgress:(CGFloat)progress;

#pragma mark Synchronization

/** @name Synchronization */

/** Informs the delegate that the document sync manager has begun to synchronize the document.
 
 At the end of the synchronization process, one of the `documentSyncManager:didFailToSynchronizeWithError:` or `documentSyncManagerDidFinishSynchronizing:` methods will be called.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidBeginSynchronizing:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the operation has processed a sync change from a client.
 
 @param aSyncManager The document sync manager object that sent the message. 
 @param changeNumber The number of the change that was processed so it can be presented to the user like 2 of 10.
 @param totalChangeCount The total number of changes that will be processed.
 @param clientIdentifier The unique identifier of the client whose changes we are processing. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager processedChangeNumber:(NSNumber *)changeNumber outOfTotalChangeCount:(NSNumber *)totalChangeCount fromClientWithID:(NSString *)clientIdentifier;


/** Informs the delegate that the document sync manager paused the sychronization process because a conflict was detected.
 
 @param aSyncManager The document sync manager object that sent the message. 
 @param aConflict The conflict that was detected.
 
 @warning You *must* call the `continueSynchronizationByResolvingConflictWithResolutionType:` method to indicate whether registration should continue or not. */
@required
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseSynchronizationAwaitingResolutionOfSyncConflict:(id)aConflict;
@optional

/** Informs the delegate that the synchronization process has continued after a conflict was resolved.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidContinueSynchronizing:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that changes were made to managed objects in the application's context on a background thread during the synchronization process.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aNotification The `NSManagedObjectContextDidSave` notification object containing changes made to objects. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didMakeChangesToObjectsInBackgroundContextAndSaveWithNotification:(NSNotification *)aNotification;

/** Informs the delegate that warnings were generated during the synchronization process.
 
 Warnings indicate that e.g., an object was changed locally but deleted remotely.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param warnings An array of `NSDictionary` objects containing information about each warning. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didEncounterWarningsWhileSynchronizing:(NSArray *)warnings;

/** Informs the delegate that the document sync manager failed to synchronize the document.
 
 @warning One possible cause of failure that you should test for is that sync failed because the integrity keys do not match. In this instance, you should alert the user and initiate a download of the whole store.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anError The error that caused synchronization to fail. */
@required
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFailToSynchronizeWithError:(NSError *)anError;
@optional

/** Informs the delegate that the document sync manager finished synchronizing the document.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidFinishSynchronizing:(TICDSDocumentSyncManager *)aSyncManager;

#pragma mark Vacuuming
/** @name Vacuuming Unneeded Files */

/** Invoked to ask the delegate whether the document sync manager should automatically remove unneeded files at registration.
 
 @param aSyncManager The document sync manager object that sent the message.
 
 @return `YES` if the document sync manager should initiate the vacuum, otherwise `NO`. */
- (BOOL)documentSyncManagerShouldVacuumUnneededRemoteFilesAfterDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager has begun to remove unneeded files from the remote.
 
 At the end of the vacuum process, one of the `documentSyncManager:didFailToVacuumUnneededRemoteFilesWithError:` or `documentSyncManagerDidFinishVacuumingUnneededRemoteFiles:` methods will be called.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidBeginVacuumingUnneededRemoteFiles:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager failed to vacuum unneeded files on the remote.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anError The error that caused the vacuum process to fail. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFailToVacuumUnneededRemoteFilesWithError:(NSError *)anError;

/** Informs the delegate that the document sync manager finished vacuuming unneeded files from the remote.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidFinishVacuumingUnneededRemoteFiles:(TICDSDocumentSyncManager *)aSyncManager;

#pragma mark Registered Client Information
/** Informs the delegate that the document sync manager has begun to fetch information on all registered devices from the remote.
 
 At the end of the request process, one of the `documentSyncManager:didFailToFetchInformationForAllRegisteredDevicesWithError:` or `documentSyncManagerDidFinishFetchingInformationForAllRegisteredDevices:` methods will be called.
 
 @param aSyncManager The document sync manager object that sent the message. */
- (void)documentSyncManagerDidBeginFetchingInformationForAllRegisteredDevices:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the document sync manager failed to fetch information on clients registered to synchronize with a document. 
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anError The error that caused the request process to fail. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFailToFetchInformationForAllRegisteredDevicesWithError:(NSError *)anError;

/** Informs the delegate that the document sync manager finished fetching information for all registered devices for this document.
 
 @param aSyncManager The document sync manager object that sent the message. 
 @param information A dictionary containing as keys the unique synchronization identifiers of each client, and as values dictionaries of information about that client. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFinishFetchingInformationForAllRegisteredDevices:(NSDictionary *)information;

#pragma mark Deletion of a Client's Synchronization Data from a Document
/** Informs the delegate that the document sync manager has begun to delete a client's synchronization data from the remote document.
 
 At the end of the process, one of the `documentSyncManager:didFailToFetchInformationForAllRegisteredDevicesWithError:` or `documentSyncManagerDidFinishFetchingInformationForAllRegisteredDevices:` methods will be called.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anIdentifier The identifier of the client that will be deleted. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didBeginDeletingSynchronizationDataFromDocumentForClientWithIdentifier:(NSString *)anIdentifier;

/** Informs the delegate that the document sync manager failed to delete a client's synchronization data from the remote document. 
 
 @param aSyncManager The document sync manager object that sent the message.
 @param anIdentifier The identifier of the client that couldn't be deleted.
 @param anError The error that caused the process to fail. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFailToDeleteSynchronizationDataFromDocumentForClientWithIdentifier:(NSString *)anIdentifier withError:(NSError *)anError;

/** Informs the delegate that the document sync manager finished deleting synchronization data for a client from the document.
 
 @param aSyncManager The document sync manager object that sent the message. 
 @param anIdentifier The identifier of the client that was deleted. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFinishDeletingSynchronizationDataFromDocumentForClientWithIdentifier:(NSString *)anIdentifier;

#pragma mark Processing
/** @name Processing after Managed Object Context Save */

/** Informs the delegate that the document sync manager has begun to process the changes that have occurred since the previous `save:` of the managed object context.
 
 At the end of the process, one of the `documentSyncManager:didFailToProcessSyncChangesBeforeManagedObjectContextWillSave:withError:` or `documentSyncManager:didFinishProcessingSyncChangesBeforeManagedObjectContextWillSave:` methods will be called.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aMoc The managed object context. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didBeginProcessingSyncChangesBeforeManagedObjectContextWillSave:(NSManagedObjectContext *)aMoc;

/** Informs the delegate that the sync manager failed to process the changes that have occurred since the previous `save:` of the managed object context.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aMoc The managed object context.
 @param anError The error that caused processing to fail. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFailToProcessSyncChangesBeforeManagedObjectContextWillSave:(NSManagedObjectContext *)aMoc withError:(NSError *)anError;

/** Informs the delegate that the sync manager finished processing the changes that have occurred since the previous `save:` of the managed object context.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aMoc The managed object context. */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFinishProcessingSyncChangesBeforeManagedObjectContextWillSave:(NSManagedObjectContext *)aMoc;

/** Invoked to ask the delegate whether the document sync manager should initiate Synchronization automatically after finishing processing changes in a synchronized managed object context.
 
 @param aSyncManager The document sync manager object that sent the message.
 @param aMoc The managed object context that saved.
 
 @return `YES` if the document sync manager should initiate the upload, otherwise `NO`. */
- (BOOL)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager shouldBeginSynchronizingAfterManagedObjectContextDidSave:(NSManagedObjectContext *)aMoc;

@end

#pragma mark - OPERATION DELEGATE PROTOCOLS
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

/** Informs the delegate that the operation has reported progress.
 
 @param anOperation The operation object that sent the message. */
- (void)operationReportedProgress:(TICDSOperation *)anOperation;

/** Asks the delegate whether or not the operation should support continued processing after the app has been sent to a background state. .
 
 @param anOperation The operation object that sent the message. */
- (BOOL)operationShouldSupportProcessingInBackgroundState:(TICDSOperation *)anOperation;

@end

#pragma mark Application Registration Operation Delegate
/** The `TICDSApplicationRegistrationOperationDelegate` protocol defines the methods implemented by delegates of `TICDSApplicationRegistrationOperation` or one of its subclasses. In the `TICoreDataSync` framework, these delegate methods are implemented by the application sync manager. */

@protocol TICDSApplicationRegistrationOperationDelegate <TICDSOperationDelegate>

/** Informs the delegate that the operation has been paused because the global app directory does not exist. The delegate should query its own delegate to ask whether to enable encryption for this application, and if so find out the password to use.
 
 @param anOperation The operation object that sent the message. */
- (void)registrationOperationPausedToFindOutWhetherToEnableEncryption:(TICDSApplicationRegistrationOperation *)anOperation;

/** Informs the delegate that the operation has resumed after being told whether to use encryption.
 
 @param anOperation The operation object that sent the message. */
- (void)registrationOperationResumedFollowingEncryptionInstruction:(TICDSApplicationRegistrationOperation *)anOperation;

/** Informs the delegate that the operation has been paused because this is the first time this client has registered to synchronize with this application, and the existing data is encrypted.
 
 @param anOperation The operation object that sent the message. */
- (void)registrationOperationPausedToRequestEncryptionPassword:(TICDSApplicationRegistrationOperation *)anOperation;

/** Informs the delegate that the operation has resumed after being given a password.
 
 @param anOperation The operation object that sent the message. */
- (void)registrationOperationResumedFollowingPasswordProvision:(TICDSApplicationRegistrationOperation *)anOperation;

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

/** Informs the delegate that the operation determined that the document had previously been deleted from synchronizing this document.
 
 @param anOperation The operation object that sent the message. */
- (void)registrationOperationDidDetermineThatClientHadPreviouslyBeenDeletedFromSynchronizingWithDocument:(TICDSDocumentRegistrationOperation *)anOperation;

@end

#pragma mark Synchronization Operation Delegate
/** The `TICDSSynchronizationOperationDelegate` protocol defines the methods implemented by delegates of `TICDSSynchronizationOperation` or one of its subclasses. In the `TICoreDataSync` framework, these delegate methods are implemented by the document sync manager. */

@protocol TICDSSynchronizationOperationDelegate <TICDSOperationDelegate>

/** Informs the delegate that the operation has processed a sync change from a client. The delegate should pass this info on to its own delegate.
 
 @param anOperation The operation object that sent the message.
 @param changeNumber The number of the change that was processed so it can be presented to the user like 2 of 10.
 @param totalChangeCount The total number of changes that will be processed.
 @param clientIdentifier The unique ID of the client whose changes we are processing. */
- (void)synchronizationOperation:(TICDSSynchronizationOperation *)anOperation processedChangeNumber:(NSNumber *)changeNumber outOfTotalChangeCount:(NSNumber *)totalChangeCount fromClientWithID:(NSString *)clientIdentifier;

/** Informs the delegate that the operation has been paused because of a conflict. The delegate should query its own delegate to ask how to resolve the conflict.
 
 @param anOperation The operation object that sent the message.
 @param aConflict The conflict. */
- (void)synchronizationOperation:(TICDSSynchronizationOperation *)anOperation pausedToDetermineResolutionOfConflict:(id)aConflict;

/** Informs the delegate that the operation has resumed after being told how to resolve the conflict. 
 
 @param anOperation The operation object that sent the message. */
- (void)synchronizationOperationResumedFollowingResolutionOfConflict:(TICDSSynchronizationOperation *)anOperation;


@end

#pragma mark Document Deletion Delegate
/** The `TICDSDocumentDeletionOperationDelegate` protocol defines the methods implemented by delegates of `TICDSDocumentDeletionOperation` or one of its subclasses. In the `TICoreDataSync` framework, these delegate methods are implemented by the application sync manager. */

@protocol TICDSDocumentDeletionOperationDelegate <TICDSOperationDelegate>

/** Informs the delegate that the document is about to be deleted from the remote. The delegate should alert its own delegate.
 
 @param anOperation The operation object that sent the message. */
- (void)documentDeletionOperationWillDeleteDocument:(TICDSDocumentDeletionOperation *)anOperation;

/** Informs the delegate that the document was deleted from the remote. The delegate should alert its own delegate.
 
 @param anOperation The operation object that sent the message. */
- (void)documentDeletionOperationDidDeleteDocument:(TICDSDocumentDeletionOperation *)anOperation;

@end

#pragma mark Remove All Sync Data Delegate
/** The `TICDSRemoveAllRemoteSyncDataOperationDelegate` protocol defines the methods implemented by delegates of `TICDSRemoveAllRemoteSyncDataOperation` or one of its subclasses. In the `TICoreDataSync` framework, these delegate methods are implemented by the application sync manager. */

@protocol TICDSRemoveAllRemoteSyncDataOperationDelegate <TICDSOperationDelegate>

/** Informs the delegate that all remote sync data is about to be deleted from the remote. The delegate should alert its own delegate.
 
 @param anOperation The operation object that sent the message. */
- (void)removeAllSyncDataOperationWillRemoveAllSyncData:(TICDSRemoveAllRemoteSyncDataOperation *)anOperation;

/** Informs the delegate that all remote sync data has been deleted from the remote. The delegate should alert its own delegate.
 
 @param anOperation The operation object that sent the message. */
- (void)removeAllSyncDataOperationDidRemoveAllSyncData:(TICDSRemoveAllRemoteSyncDataOperation *)anOperation;

@end