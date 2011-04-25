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
 2. `TICDSRestClientBasedDocumentSyncManager`
 
 @warning You must register the document sync manager before you can use it to synchronize the document, or perform any other tasks.
 
 @see TICDSFileManagerBasedDocumentSyncManager
 */

@interface TICDSDocumentSyncManager : NSObject <TICDSDocumentRegistrationOperationDelegate> {
@private
    TICDSDocumentSyncManagerState _state;
    
    id <TICDSDocumentSyncManagerDelegate> _delegate;
    TICDSApplicationSyncManager *_applicationSyncManager;
    NSString *_documentIdentifier;
    NSString *_documentDescription;
	NSString *_clientIdentifier;
    NSDictionary *_userInfo;
    
    NSFileManager *_fileManager;
    
    NSURL *_helperFileDirectoryLocation;
    
    TICDSSynchronizedManagedObjectContext *_primaryDocumentMOC;
    TICoreDataFactory *_coreDataFactory;
    NSManagedObjectContext *_syncChangesMOC;
    
    NSOperationQueue *_registrationQueue;
    NSOperationQueue *_synchronizationQueue;
    NSOperationQueue *_otherTasksQueue;
}

/** @name Registration */

/** Register a document ready for synchronization.
 
 Use this method to register the sync manager ready for document synchronization.
 
 This will automatically spawn a `TICDSDocumentRegistrationOperation`, and notify you of progress through the `TICDSDocumentSyncManagerDelegate` methods.
 
 If this is the first time you have registered the document with this identifier, registration will automatically create the file structure necessary at the remote end for this and other clients to synchronize. See `[TICDSUtilities remoteDocumentFileStructure]` for the structure that will be created.
 
 If you provide an application sync manager that isn't yet ready to sync, the document registration task will be suspended until the application has finished registering.
 
 If this is the first time you have registered this document, or the remote file structure has been removed for some reason, your delegate will be notified with the `syncManager:didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:description:userInfo:` method. You must continue registration manually by calling the `continueRegistrationByCreatingRemoteFileStructure:` method.
 
 @warning You must call this method before using the document sync manager for any other purpose.
 
 @param aDelegate The object you wish to be notified regarding document-related sync information; this object must conform to the `TICDSDocumentSyncManagerDelegate` protocol, which includes some required methods.
 @param anAppSyncManager The application sync manager responsible for overseeing this document.
 @param aContext The primary managed object context in your application; this must be an instance of `TICDSSynchronizedManagedObjectContext` and not just a plain `NSManagedObjectContext`.
 @param aDocumentIdentifier An identification string to identify this document uniquely. You would typically create a UUID string the first time this doc is registered and store this in e.g. the store metadata.
 @param aDocumentDescription A human-readable string used to identify this document, e.g. the full name of the document.
 @param userInfo A dictionary of information that will be saved throughout all future synchronizations. Because this information is saved in a plist, everything in the dictionary must be archivable using `NSKeyedArchiver`.
 */
- (void)registerWithDelegate:(id <TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager managedObjectContext:(TICDSSynchronizedManagedObjectContext *)aContext documentIdentifier:(NSString *)aDocumentIdentifier description:(NSString *)aDocumentDescription userInfo:(NSDictionary *)someUserInfo;

/** Continue Registration.
 
 If this is the first time you have registered this document, or the remote file structure has been removed for some reason, your delegate will be notified with the `syncManager:didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:description:userInfo:` method. You must continue registration manually by calling this method, specifying whether or not the registration should continue by creating the remote file structure.
 
 If you specify `NO`, registration will fail with an error.
 
 @param shouldCreateFileStructure A Boolean indicating whether the registration should continue and create the necessary remote file structure. 
 */
- (void)continueRegistrationByCreatingRemoteFileStructure:(BOOL)shouldCreateFileStructure;

/** @name Whole Store Upload */

/** Start the process manually to upload the entire store file for this document, along with the relevant `AppliedSyncChanges.sqlite` file.
 
 The location of the store file (and the applied sync changes file) will be requested from the delegate immediately after calling this method. */
- (void)initiateUploadOfWholeStore;

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

/** @name Managed Object Context Saving */

/** Indicate that the synchronized managed object context is about to save.
 
 This method is called automatically by `TICDSSynchronizedManagedObjectContext` when it's about to initiate a `save:`.
 
 @param aMoc The synchronized managed object context.
 */
- (void)synchronizedMOCWillSave:(TICDSSynchronizedManagedObjectContext *)aMoc;

/** Indicate that the synchronized managed object context completed a successful save.
 
 This method is called automatically by `TICDSSynchronizedManagedObjectContext` when it has successfully completed a `save:`.
 
 @param aMoc The synchronized managed object context.
 */
- (void)synchronizedMOCDidSave:(TICDSSynchronizedManagedObjectContext *)aMoc;

/** Indicate that the synchronized managed object context failed to save.
 
 This method is called automatically by `TICDSSynchronizedManagedObjectContext` when it's failed to `save:`.
 
 @param aMoc The synchronized managed object context.
 @param anError The relevant saving error.
 */
- (void)synchronizedMOCFailedToSave:(TICDSSynchronizedManagedObjectContext *)aMoc withError:(NSError *)anError;

/** @name Properties */

/** Document Sync Manager State.
 
 The state of the document sync manager indicates whether it is ready to synchronize.
 
 Possible values are defined in `TICDSTypesAndEnums.h`.
 */
@property (nonatomic, assign) TICDSDocumentSyncManagerState state;

/** The Document Sync Manager Delegate. */
@property (nonatomic, assign) id <TICDSDocumentSyncManagerDelegate> delegate;

/** The Application Sync Manager responsible for this document. */
@property (nonatomic, retain) TICDSApplicationSyncManager *applicationSyncManager;

/** The Document Identifier used for registration.
 
 Set the identifier when registering with `registerWithDelegate:appSyncManager:managedObjectContext:documentIdentifier:description:userInfo:`.
 */
@property (nonatomic, readonly, retain) NSString *documentIdentifier;

/** The Document Description used for registration.
 
 Set the identifier when registering with `registerWithDelegate:appSyncManager:managedObjectContext:documentIdentifier:description:userInfo:`.
 */
@property (nonatomic, readonly, retain) NSString *documentDescription;

/** The Client Identifier used for registration.
 
 Set the identifier when registering with `registerWithDelegate:appSyncManager:managedObjectContext:documentIdentifier:description:userInfo:`.
 */
@property (nonatomic, readonly, retain) NSString *clientIdentifier;

/** The User Info used for registration.
 
 Set the user info when registering with `registerWithDelegate:appSyncManager:managedObjectContext:documentIdentifier:description:userInfo:`.
 */
@property (nonatomic, readonly, retain) NSDictionary *userInfo;

/** An `NSFileManager` suitable for use in document registration tasks. */
@property (nonatomic, retain) NSFileManager *fileManager;

/** The location of a directory used by the `TICoreDataSync` framework to store local helper files for this document.
 
 You typically set this property by implementing the `TICDSDocumentSyncManagerDelegate` method `syncManager:helperFileDirectoryLocationForDocumentWithIdentifier:description:userInfo:`.
 
 By default, the framework will use the location `~/Library/Application Support/ApplicationName/Documents/documentIdentifier`.
 */
@property (readonly, retain) NSURL *helperFileDirectoryLocation;

@property (nonatomic, retain) TICDSSynchronizedManagedObjectContext *primaryDocumentMOC;
@property (nonatomic, retain) TICoreDataFactory *coreDataFactory;
@property (nonatomic, retain) NSManagedObjectContext *syncChangesMOC;

/** @name Operation Queues */

/** The operation queue used for registration operations.
 */
@property (nonatomic, retain) NSOperationQueue *registrationQueue;

/** The operation queue used for synchronization operations.
 
 The queue supports only 1 operation at a time, and is suspended until the document has registered successfully. */
@property (nonatomic, retain) NSOperationQueue *synchronizationQueue;

/** The operation queue used for other tasks.
 
 The queue is suspended until the document has registered successfully. */
@property (nonatomic, retain) NSOperationQueue *otherTasksQueue;

/** @name Relative Paths */

/** The path to the `Documents` directory, relative to the root of the remote file structure. */
@property (nonatomic, readonly) NSString *relativePathToDocumentsDirectory;

/** The path to this document's directory inside the `Documents` directory, relative to the root of the remote file structure. */
@property (nonatomic, readonly) NSString *relativePathToThisDocumentDirectory;

/** The path to the `SyncChanges` directory for this document, relative to the root of the remote file structure. */
@property (nonatomic, readonly) NSString *relativePathToThisDocumentSyncChangesDirectory;

/** The path to this client's directory inside the `SyncChanges` directory for this document, relative to the root of the remote file structure. */
@property (nonatomic, readonly) NSString *relativePathToThisDocumentSyncChangesThisClientDirectory;

@property (nonatomic, readonly) NSString * unsynchronizedSyncChangesStorePath;

@end
