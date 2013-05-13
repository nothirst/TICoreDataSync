//
//  TICDSDocumentSyncManager.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSClassesAndProtocols.h"
#import "TICDSTypesAndEnums.h"

/** `TICDSDocumentSyncManager` describes the generic behavior provided by a Document Sync Manager in the `TICoreDataSync` framework.
 
 A Document Sync Manager is responsible for synchronization settings relating to a single document--you'll need one for each document you wish to synchronize. If your application is a non-document-based application, you'll still need a single document sync manager to represent your application's data.
 
 Don't instantiate this class directly, but instead use one of the subclasses:
 
 1. `TICDSFileManagerBasedDocumentSyncManager`
 2. `TICDSDropboxSDKBasedDocumentSyncManager`
 
 @warning You must register the document sync manager before you can use it to synchronize the document, or perform any other tasks. */

@interface TICDSDocumentSyncManager : NSObject <TICDSDocumentRegistrationOperationDelegate, TICDSSynchronizationOperationDelegate> {
@private
    TICDSDocumentSyncManagerState _state;
    
    BOOL _shouldUseEncryption;
    BOOL _shouldUseCompressionForWholeStoreMoves;
    
    BOOL _mustUploadStoreAfterRegistration;
    
    id <TICDSDocumentSyncManagerDelegate> __weak _delegate;
    TICDSApplicationSyncManager *_applicationSyncManager;
    NSString *_documentIdentifier;
    NSString *_documentDescription;
	NSString *_clientIdentifier;
    NSDictionary *_documentUserInfo;
    
    NSFileManager *_fileManager;
    
    NSURL *_helperFileDirectoryLocation;
    
    NSManagedObjectContext *_primaryDocumentMOC;
    TICoreDataFactory *_coreDataFactory;
    NSMutableDictionary *_syncChangesMOCs;
    
    NSOperationQueue *_registrationQueue;
    NSOperationQueue *_synchronizationQueue;
    NSOperationQueue *_otherTasksQueue;
    
    NSString *_integrityKey;

#if TARGET_OS_IPHONE
    UIBackgroundTaskIdentifier _backgroundTaskID;
#endif
    BOOL _shouldContinueProcessingInBackgroundState;
}

#pragma mark - Local helper file removal
/** @name Local Helper File Removal */

/** Remove Local Helper Files.
 
 Use this method to teardown the local sync helper files that TICDS stores. This method does not require a configured and registered document sync manager unless you've specified a custom location for TICDS to store the helper files.
 
 @param error If the file manager fails to remove the files the error will be non-nil.
  */
- (void)removeLocalHelperFiles:(NSError **)error;

#pragma mark - Deregistration

/** @name Deregistration */

/**
 Puts this document sync manager in a deregistered state.
 */
- (void)deregisterDocumentSyncManager;

#pragma mark - One-Shot Document Registration
/** @name One-Shot Document Registration */

/** Register a document ready for synchronization.
 
 Use this method to register the sync manager ready for document synchronization.
 
 This will automatically spawn a `TICDSDocumentRegistrationOperation`, and notify you of progress through the `TICDSDocumentSyncManagerDelegate` methods.
 
 If this is the first time you have registered the document with this identifier, registration will automatically create the file structure necessary at the remote end for this and other clients to synchronize. See `[TICDSUtilities remoteDocumentFileStructure]` for the structure that will be created.
 
 If you provide an application sync manager that isn't yet ready to sync, the document registration task will be suspended until the application has finished registering.
 
 If this is the first time you have registered this document, or the remote file structure has been removed for some reason, your delegate will be notified with the `documentSyncManager:didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:description:userInfo:` method. You must continue registration manually by calling the `continueRegistrationByCreatingRemoteFileStructure:` method.
 
 @warning You must call this method before using the document sync manager for any other purpose.
 
 @param aDelegate The object you wish to be notified regarding document-related sync information; this object must conform to the `TICDSDocumentSyncManagerDelegate` protocol, which includes some required methods.
 @param anAppSyncManager The application sync manager responsible for overseeing this document.
 @param aContext The primary managed object context in your application; this must be an instance of `NSManagedObjectContext` whose synchronized property is set to YES.
 @param aDocumentIdentifier An identification string to identify this document uniquely. You would typically create a UUID string the first time this doc is registered and store this in e.g. the store metadata.
 @param aDocumentDescription A human-readable string used to identify this document, e.g. the full name of the document.
 @param someUserInfo A dictionary of information that will be saved throughout all future synchronizations. Because this information is saved in a plist, everything in the dictionary must be archivable using `NSKeyedArchiver`.
 */
- (void)registerWithDelegate:(id <TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager managedObjectContext:(NSManagedObjectContext *)aContext documentIdentifier:(NSString *)aDocumentIdentifier description:(NSString *)aDocumentDescription userInfo:(NSDictionary *)someUserInfo;

#pragma mark - Delayed Document Registration
/** @name Delayed Document Registration */

/** Configure a document but don't immediately register it.
 
 Use this method to configure the sync manager in environments where you may not have a permanent internet connection, such as an iOS device, or a desktop WebDAV client, etc. 
 
 This will configure everything necessary to track changes made by the user. When you wish to initiate a sync, or perform any other task, you'll need to call the `registerConfiguredDocumentSyncManager` method first to initiate registration.
 
 @warning You must call this method before using the document sync manager for any other purpose.
 
 Do not use this method of registration the very first time the user configures registration on a document, or the internal checks to update the sync attribute on any pre-existing managed objects will not be made.
 
 @param aDelegate The object you wish to be notified regarding document-related sync information; this object must conform to the `TICDSDocumentSyncManagerDelegate` protocol, which includes some required methods.
 @param anAppSyncManager The application sync manager responsible for overseeing this document.
 @param aContext The primary managed object context in your application; this must be an instance of `NSManagedObjectContext` and not just a plain `NSManagedObjectContext`.
 @param aDocumentIdentifier An identification string to identify this document uniquely. You would typically create a UUID string the first time this doc is registered and store this in e.g. the store metadata.
 @param aDocumentDescription A human-readable string used to identify this document, e.g. the full name of the document.
 @param someUserInfo A dictionary of information that will be saved throughout all future synchronizations. Because this information is saved in a plist, everything in the dictionary must be archivable using `NSKeyedArchiver`.
 */
- (void)configureWithDelegate:(id <TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager managedObjectContext:(NSManagedObjectContext *)aContext documentIdentifier:(NSString *)aDocumentIdentifier description:(NSString *)aDocumentDescription userInfo:(NSDictionary *)someUserInfo;

/** Register a document that has already been pre-configured.
 
 Use this method to register a document sync manager that you have already configured using the `configureWithDelegate:appSyncManager:managedObjectContext:documentIdentifier:description:userInfo:` method. */
- (void)registerConfiguredDocumentSyncManager;

#pragma mark - General Registration
/** @name General Registration */

/** Continue Registration.
 
 If this is the first time you have registered this document, or the remote file structure has been removed for some reason, your delegate will be notified with the `documentSyncManager:didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:description:userInfo:` method. You must continue registration manually by calling this method, specifying whether or not the registration should continue by creating the remote file structure.
 
 If you specify `NO`, registration will fail with an error.
 
 @param shouldCreateFileStructure `YES` if the registration should continue and create the necessary remote file structure, or `NO` to cancel the registration. 
 */
- (void)continueRegistrationByCreatingRemoteFileStructure:(BOOL)shouldCreateFileStructure;

/** Pre-configure a sync manager for a document that's just been downloaded, but without carrying out full registration.
 
 Use this method to provide basic configuration of the sync manager for a document that's been downloaded by calling the `TICDSApplicationSyncManager` method `requestDownloadOfDocumentWithIdentifier:toLocation:`, normally in response to the `TICDSApplicationSyncManager` delegate method `applicationSyncManager:preConfiguredDocumentSyncManagerForDownloadedDocumentWithIdentifier:atURL:`.
 
 This will setup the necessary helper file location and do any local configuration, but won't register the document with the remote.
 
 If an error occurs, the delegate will be informed via the `applicationSyncManager:didFailToRegisterWithError:` method.
 
 @warning This method is called automatically by `registerWithDelegate:appSyncManager:managedObjectContext:documentIdentifier:description:userInfo:`, so you should only call it when needed during the document download process, not during general document registration.
 
 @param aDelegate The object you wish to be notified regarding document-related sync information; this object must conform to the `TICDSDocumentSyncManagerDelegate` protocol, which includes some required methods.
 @param anAppSyncManager The application sync manager responsible for overseeing this document.
 @param aDocumentIdentifier An identification string to identify this document uniquely. You would typically create a UUID string the first time this doc is registered and store this in e.g. the store metadata.
 */
- (void)preConfigureWithDelegate:(id <TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager documentIdentifier:(NSString *)aDocumentIdentifier;

/** Add an additional background managed object context to this document sync manager.
 
 Use this method to add an additional managed object context in which changes should be tracked, for example a context used to add items in the background. 
 
 @param aContext The additional managed object context to add. */
- (void)addManagedObjectContext:(NSManagedObjectContext *)aContext;

#pragma mark - Whole Store Upload and Download
/** @name Whole Store Upload and Download */

/** Start the process manually to upload the entire store file for this document, along with the relevant `AppliedSyncChanges.ticdsync` file.
 
 This will automatically spawn a `TICDSWholeStoreUploadOperation`, and notify you of progress through the `TICDSDocumentSyncManagerDelegate` methods.
 
 The location of the store file (and the applied sync changes file) will be requested from the delegate immediately after calling this method. */
- (void)initiateUploadOfWholeStore;

/** Start the process to download the entire store file for this document, along with the relevant `AppliedSyncChanges.ticdsync` file.
 
 This will automatically spawn a `TICDSWholeStoreDownloadOperation`, and notify you of progress through the `TICDSDocumentSyncManagerDelegate` methods.
 
 The location of the store file (and the applied sync changes file) will be requested from the delegate immediately after calling this method. */
- (void)initiateDownloadOfWholeStore;

#pragma mark - Synchronization Process
/** @name Synchronization Process */

/** Start synchronizing the document with the remote location. 
 
 This will automatically spawn a `TICDSSynchronizationOperation`, and notify you of progress through the `TICDSDocumentSyncManagerDelegate` methods. */
- (void)initiateSynchronization;

/** Cancel synchronizing the document with the remote location.
 
 This will cancel all synchronization operations and notify you of progress through the `TICDSDocumentSyncManagerDelegate` methods. */
- (void)cancelSynchronization;

/** If a conflict is encountered during synchronization, your delegate will be notified with the `solveConflict:` method. You must decide whether the remote or local `SyncChange` wins, and inform the document sync manager using this method to continue synchronization.
 
 @param aType The type of conflict resolution; see `TICDSTypesAndEnums.h` for possible values. */
- (void)continueSynchronizationByResolvingConflictWithResolutionType:(TICDSSyncConflictResolutionType)aType;

#pragma mark - Other Tasks Process
/** @name Other Tasks Process */

/** Cancel any operations in both the ApplicationSyncManager's and DocumentSyncManager's OtherTasks op queues */
- (void)cancelOtherTasks;

#pragma mark - Background State Processing
/** @name Background State Processing */

/** Initiate cancellation of tasks that are not marked as being supported in background state */
- (void)cancelNonBackgroundStateOperations;

#pragma mark - Vacuuming Files
/** @name Vacuuming Unneeded Files */

/** Initiate a vacuum operation to clean up files hanging around on the remote that are no longer needed by any registered clients.
 
 This will automatically spawn a `TICDSVacuumOperation`, and notify you of progress through the `TICDSDocumentSyncManagerDelegate` methods. */
- (void)initiateVacuumOfUnneededRemoteFiles;

#pragma mark - Information on Registered Clients
/** @name Information on Registered Clients */

/** Fetch a list of devices that are registered to synchronize with this client. */
- (void)requestInformationForAllRegisteredDevices;

#pragma mark - Deleting Devices from a Document
/** @name Deleting Clients from a Document */

/** Delete the files used by a client to synchronize with this document.
 
 This will automatically spawn a `TICDSDocumentClientDeletionOperation`, and notify you of progress through the `TICDSDocumentSyncManagerDelegate` methods. 
 @param anIdentifier The unique synchronization identifier of the client to delete. */
- (void)deleteDocumentSynchronizationDataForClientWithIdentifier:(NSString *)anIdentifier;

#pragma mark - Polling methods

/** @name Polling Remote Storage for Changes */

/** Begin polling the remote storage for changes to the sync directory.
 
 This method will cause the document sync manager to periodically poll the remote storage for changes to the sync directory and will kick off a sync if changes are found.
 */
- (void)beginPollingRemoteStorageForChanges;

/** Stop polling the remote storage for changes to the sync directory.
 
 This method will cause the document sync manager to stop polling the remote storage for changes to the sync directory.
 */
- (void)stopPollingRemoteStorageForChanges;

#pragma mark - Overridden Methods
/** @name Methods Overridden by Subclasses */

/** Returns a document registration operation.
 
 Subclasses of `TICDSDocumentSyncManager` use this method to return a correctly-configured document registration operation for their particular sync method.
 
 @return A correctly-configured subclass of `TICDSDocumentRegistrationOperation`.
 */
- (TICDSDocumentRegistrationOperation *)documentRegistrationOperation;

/** Returns a whole store upload operation.
 
 Subclasses of `TICDSDocumentSyncManager` use this method to return a correctly-configured whole store upload operation for their particular sync method.
 
 @return A correctly-configured subclass of `TICDSWholeStoreUploadOperation`. */
- (TICDSWholeStoreUploadOperation *)wholeStoreUploadOperation;

/** Returns a whole store download operation.
 
 Subclasses of `TICDSDocumentSyncManager` use this method to return a correctly-configured whole store download operation (including the remote location of the document's whole store, etc) for their particular sync method.

 @return A correctly-configured subclass of `TICDSWholeStoreDownloadOperation`. */
- (TICDSWholeStoreDownloadOperation *)wholeStoreDownloadOperation;

/** Returns a synchronization operation.
 
 Subclasses of `TICDSDocumentSyncManager` use this method to return a correctly-configured synchronization operation for their particular sync method.
 
 @return A correctly-configured subclass of `TICDSSynchronizationOperation`. */
- (TICDSSynchronizationOperation *)synchronizationOperation;

/** Returns a vacuum operation.
 
 Subclasses of `TICDSDocumentSyncManager` use this method to return a correctly-configured vacuum operation for their particular sync method.
 
 @return A correctly-configured subclass of `TICDSVacuumOperation`. */
- (TICDSVacuumOperation *)vacuumOperation;

/** Returns a "list of registered clients for this document" operation.
 
 Subclasses of `TICDSDocumentSyncManager` use this method to return a correctly-configured operation for their particularly sync method.
 
 @return A correctly-configured subclass of `TICDSListOfDocumentRegisteredClientsOperation`. */
- (TICDSListOfDocumentRegisteredClientsOperation *)listOfDocumentRegisteredClientsOperation;


/** Returns a "deletion of client synchronization data from a document" operation.
 
 Subclasses of `TICDSDocumentSyncManager` use this method to return a correctly-configured operation for their particularly sync method.
 
 @return A correctly-configured subclass of `TICDSDocumentClientDeletionOperation`. */
- (TICDSDocumentClientDeletionOperation *)documentClientDeletionOperation;

#pragma mark - MOC Saving
/** @name Managed Object Context Saving */

/** Indicate that the synchronized managed object context is about to save.
 
 This method is called automatically by `NSManagedObjectContext` when it's about to initiate a `save:`.
 
 @param aMoc The synchronized managed object context.
 */
- (void)synchronizedMOCWillSave:(NSManagedObjectContext *)aMoc;

#pragma mark - Properties
/** @name Properties */

/** Document Sync Manager State.
 
 The state of the document sync manager indicates whether it is ready to synchronize.
 
 Possible values are defined in `TICDSTypesAndEnums.h`.
 */
@property (nonatomic, assign) TICDSDocumentSyncManagerState state;

/** Used to indicate whether the document sync manager should use encryption for the remote files.
 
 This value is set automatically by the application sync manager. */
@property (nonatomic, assign) BOOL shouldUseEncryption;

/** Used to indicate whether the document sync manager should use compression when moving whole store.
 
This value is set automatically by the application sync manager. */
@property (nonatomic, assign) BOOL shouldUseCompressionForWholeStoreMoves;

/** Used internally to indicate whether the document sync manager must upload the store after registration has completed.
 
 This will be `YES` if this is the first time this document has been registered. */
@property (nonatomic, assign) BOOL mustUploadStoreAfterRegistration;

/** The Document Sync Manager Delegate. */
@property (nonatomic, weak) id <TICDSDocumentSyncManagerDelegate> delegate;

/** The Application Sync Manager responsible for this document. */
@property (nonatomic, strong) TICDSApplicationSyncManager *applicationSyncManager;

/** The Document Identifier used for registration.
 
 Set the identifier when registering with `registerWithDelegate:appSyncManager:managedObjectContext:documentIdentifier:description:userInfo:`.
 */
@property (nonatomic, readonly, copy) NSString *documentIdentifier;

/** The Document Description used for registration.
 
 Set the identifier when registering with `registerWithDelegate:appSyncManager:managedObjectContext:documentIdentifier:description:userInfo:`.
 */
@property (nonatomic, readonly, copy) NSString *documentDescription;

/** The Client Identifier used for registration.
 
 Set the identifier when registering with `registerWithDelegate:appSyncManager:managedObjectContext:documentIdentifier:description:userInfo:`.
 */
@property (nonatomic, readonly, copy) NSString *clientIdentifier;

/** The User Info used for registration.
 
 Set the user info when registering with `registerWithDelegate:appSyncManager:managedObjectContext:documentIdentifier:description:userInfo:`.
 */
@property (nonatomic, readonly, strong) NSDictionary *documentUserInfo;

/** An `NSFileManager` suitable for use in document registration tasks. */
@property (nonatomic, readonly, strong) NSFileManager *fileManager;

/** The location of a directory used by the `TICoreDataSync` framework to store local helper files for this document.
 
 You typically set this property by implementing the `TICDSDocumentSyncManagerDelegate` method `documentSyncManager:helperFileDirectoryURLForDocumentWithIdentifier:description:userInfo:`.
 
 By default, the framework will use the location `~/Library/Application Support/ApplicationName/Documents/documentIdentifier`.
 */
@property (readonly, strong) NSURL *helperFileDirectoryLocation;

/** A dictionary containing the SyncChanges managed object contexts to use for each document managed object context. */
@property (strong) NSMutableDictionary *syncChangesMOCs;

/** Returns a SyncChanges managed object context for a given document managed object context. */
- (NSManagedObjectContext *)syncChangesMocForDocumentMoc:(NSManagedObjectContext *)aContext;

/** The document managed object context that was supplied at registration, and therefore treated as the primary context. */
@property (nonatomic, strong) NSManagedObjectContext *primaryDocumentMOC;

/** The `TICoreDataFactory` object used for SyncChange managed object contexts. */
@property (nonatomic, strong) TICoreDataFactory *coreDataFactory;

/** Used to indicate if the document sync manager has been configured via the -configureWithDelegate:appSyncManager:managedObjectContext:documentIdentifier:description:userInfo: method. */
@property (nonatomic, getter = isConfigured) BOOL configured;

#if TARGET_OS_IPHONE
/** Unique task identifier used when Sync Manager is performing a series of tasks that should be continued after app goes into background state */
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskID;
#endif

/** Indicates whether the document sync manager should be setup to continue processing after the app has been moved from the Active to Background state */
@property (nonatomic, assign) BOOL shouldContinueProcessingInBackgroundState;

#pragma mark - Operation Queues
/** @name Operation Queues */

/** The operation queue used for registration operations.
 */
@property (nonatomic, readonly, strong) NSOperationQueue *registrationQueue;

/** The operation queue used for synchronization operations.
 
 The queue supports only 1 operation at a time, and is suspended until the document has registered successfully. */
@property (nonatomic, readonly, strong) NSOperationQueue *synchronizationQueue;

/** The operation queue used for other tasks.
 
 The queue is suspended until the document has registered successfully. */
@property (nonatomic, readonly, strong) NSOperationQueue *otherTasksQueue;

#pragma mark - Relative Paths
/** @name Relative Paths */

/** The path to the `ClientDevices` directory, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToClientDevicesDirectory;

/** The path to the `Information` directory, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToInformationDirectory;

/** The path to the `DeletedDocuments` directory inside the `Information` directory, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString * relativePathToInformationDeletedDocumentsDirectory;

/** The path to this document's `identifier.plist` file inside the `DeletedDocuments` directory, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToDeletedDocumentsThisDocumentIdentifierPlistFile;

/** The path to the `Documents` directory, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToDocumentsDirectory;

/** The path to this document's directory inside the `Documents` directory, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentDirectory;

/** The path to this document's `DeletedClients` directory, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentDeletedClientsDirectory;

/** The path to the `SyncChanges` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentSyncChangesDirectory;

/** The path to this client's directory inside the `SyncChanges` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentSyncChangesThisClientDirectory;

/** The path to the `SyncCommands` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentSyncCommandsDirectory;

/** The path to this client's directory inside the `SyncCommands` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentSyncCommandsThisClientDirectory;

/** The path to the `WholeStore` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentWholeStoreDirectory;

/** The path to this client's directory inside the `WholeStore` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentWholeStoreThisClientDirectory;

/** The path to the `TemporaryFiles` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentTemporaryFilesDirectory;

/** The path to the `WholeStore` directory inside the `TemporaryFiles` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentTemporaryWholeStoreDirectory;

/** The path to this client's directory inside the `WholeStore` directory inside the `TemporaryFiles` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentTemporaryWholeStoreThisClientDirectory;

/** The path to this client's `WholeStore.ticdsync` file inside it's directory inside the `WholeStore` directory inside the `TemporaryFiles` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFile;

/** The path to this client's `AppliedSyncChangeSets.ticdsync` file inside it's directory inside the `WholeStore` directory inside the `TemporaryFiles` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFile;

/** The path to this client's `WholeStore.ticdsync` file inside it's directory inside the `WholeStore` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentWholeStoreThisClientDirectoryWholeStoreFile;

/** The path to this client's `AppliedSyncChangeSets.ticdsync` file inside it's directory inside the `WholeStore` directory for this document, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFile;

/** The path to this document's `RecentSyncs` directory, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentRecentSyncsDirectory;

/** The path this client's RecentSync file inside this document's `RecentSyncs` directory, relative to the root of the remote file structure. */
@property (weak, nonatomic, readonly) NSString *relativePathToThisDocumentRecentSyncsDirectoryThisClientFile;


/** The path to the `AppliedSyncChanges.ticdsync` file, located in the `helperFileDirectoryLocation`. */
@property (weak, nonatomic, readonly) NSString *localAppliedSyncChangesFilePath;

/** The path to the `SyncChangesBeingSynchronized.syncchg` file, located in the `helperFileDirectoryLocation`. */
@property (weak, nonatomic, readonly) NSString *syncChangesBeingSynchronizedStorePath;

/** The path to the `UnsynchronizedSyncChanges.syncchg` file, located in the `helperFileDirectoryLocation`. */
@property (weak, nonatomic, readonly) NSString *unsynchronizedSyncChangesStorePath;

/** The integrity key used to check whether the synchronization data matches what's expected. */
@property (nonatomic, copy) NSString *integrityKey;

@end
