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

#pragma mark Operations
@class TICDSOperation;
@class TICDSApplicationRegistrationOperation;
@class TICDSDocumentRegistrationOperation;
@class TICDSListOfPreviouslySynchronizedDocumentsOperation;

#pragma mark File Manager-Based
@class TICDSFileManagerBasedApplicationSyncManager;
@class TICDSFileManagerBasedDocumentSyncManager;
@class TICDSFileManagerBasedApplicationRegistrationOperation;
@class TICDSFileManagerBasedDocumentRegistrationOperation;
@class TICDSFileManagerBasedListOfPreviouslySynchronizedDocumentsOperation;

#pragma mark -
#pragma mark INTERNAL DATA MODEL
@class TICDSSyncChange;

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
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)syncManagerDidStartRegistration:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the sync manager encountered an error during the application registration process.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param anError The error that was encountered. */
- (void)syncManager:(TICDSApplicationSyncManager *)aSyncManager encounteredRegistrationError:(NSError *)anError;

/** Informs the delegate that the registration process failed to complete.
 
 The error will previously have been supplied through the `syncManager:encounteredRegistrationError:` method.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)syncManagerFailedToRegister:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the registration process completed successfully.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)syncManagerDidRegisterSuccessfully:(TICDSApplicationSyncManager *)aSyncManager;

#pragma mark Previously-Synchronized Documents
/** @name Previously-Synchronized Documents */

/** Informs the delegate that the sync manager has started to check for available documents that have previously been synchronized.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)syncManagerDidBeginToCheckForPreviouslySynchronizedDocuments:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the sync manager failed to check for previously-synchronized documents.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param anError The error related to the failure. */
- (void)syncManager:(TICDSApplicationSyncManager *)aSyncManager failedToCheckForPreviouslySynchronizedDocumentsWithError:(NSError *)anError;

/** Informs the delegate that the sync manager didn't find any previously-synchronized documents.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)syncManagerDidNotFindAnyPreviouslySynchronizedDocuments:(TICDSApplicationSyncManager *)aSyncManager;

/** Informs the delegate that the sync manager found one or more previously-synchronized documents.
 
 One `NSDictionary` is supplied per document, containing the following keys:
 
 1. `kTICDSDocumentIdentifier`--the unique synchronization identifier of the document.
 2. `kTICDSDocumentDescription`--the description of the document, as provided when it was originally registered.
 3. `kTICDSOriginalDeviceIdentifier`--the unique identifier of the client that first registered the document.
 4. `kTICDSOriginalDeviceDescription`--the description of the client that first registered the document.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param documentsArray An array of `NSDictionary` objects containing information about each available document. */
- (void)syncManager:(TICDSApplicationSyncManager *)aSyncManager didFindPreviouslySynchronizedDocuments:(NSArray *)documentsArray;

@end

#pragma mark Document Sync Manager
/** The `TICDSDocumentSyncManagerDelegate` protocol defines the methods implemented by delegates of a `TICDSDocumentSyncManager` object. */

@protocol TICDSDocumentSyncManagerDelegate <NSObject>

@optional

#pragma mark Registration
/** @name Registration Phase */

/** Informs the delegate that the sync manager has started the document registration process.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)syncManagerDidStartDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the sync manager encountered an error during the document registration process.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param anError The error that was encountered. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager encounteredDocumentRegistrationError:(NSError *)anError;

/** Informs the delegate that the sync manager paused the document registration process because the remote file structure does not yet exist for the specified document.
 
 @param aSyncManager The application sync manager object that sent the message. 
 @param anIdentifier The unique identifier for the document (as supplied at registration).
 @param aDescription The description of the document (as supplied at registration).
 @param userInfo The user info dictionary (as supplied at registration).
 
 @warning You *must* call the `continueRegistrationByCreatingRemoteFileStructure:` method to indicate whether registration should continue or not.
 */
@required
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo;

@optional

/** Informs the delegate that the sync manager has resumed the document registration process.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)syncManagerDidResumeRegistration:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the sync manager failed to complete the document registration process.
 
 The error will previously have been supplied through the `syncManager:encounteredDocumentRegistrationError:` method.

 @param aSyncManager The application sync manager object that sent the message. */
- (void)syncManagerFailedToRegisterDocument:(TICDSDocumentSyncManager *)aSyncManager;

/** Informs the delegate that the registration process completed successfully.
 
 @param aSyncManager The application sync manager object that sent the message. */
- (void)syncManagerDidRegisterDocumentSuccessfully:(TICDSDocumentSyncManager *)aSyncManager;

#pragma mark Helper Files
/** @name Helper Files */

/** Invoked to allow the delegate to return a custom location for a local directory to contain the helper files the `TICoreDataSync` framework uses to synchronize a document.
 
 If you don't implement this method, the default location will be `~/Library/Application Support/<application name>/Documents/<document identifier/`.
 
 @param aSyncManager The application sync manager object that sent the message.
 @param anIdentifier The unique identifier for the document (as supplied at registration).
 @param aDescription The description of the document (as supplied at registration).
 @param userInfo The user info dictionary (as supplied at registration).
 
 @return The `NSURL` for the location you wish to use.
 @warning The location you specify *must* already exist. */
- (NSURL *)syncManager:(TICDSDocumentSyncManager *)aSyncManager helperFileDirectoryLocationForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo;

#pragma mark Processing
/** @name Processing after Managed Object Context save */

/** Informs the delegate that the sync manager has begun to process the changes that have occurred since the previous `save:` of the managed object context.
 
 @param aSyncManager The application sync manager object that sent the message.
 @param aMoc The managed object context. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager didBeginProcessingAfterMOCDidSave:(TICDSSynchronizedManagedObjectContext *)aMoc;

/** Informs the delegate that the sync manager failed to process the changes that have occurred since the previous `save:` of the managed object context.
 
 @param aSyncManager The application sync manager object that sent the message.
 @param aMoc The managed object context. */
- (void)syncManager:(TICDSDocumentSyncManager *)aSyncManager failedToProcessAfterMOCDidSave:(TICDSSynchronizedManagedObjectContext *)aMoc;

@end

#pragma mark -
#pragma mark OPERATION DELEGATE PROTOCOLS
#pragma Generic Operation Delegate
/** The `TICDSOperationDelegate` protocol defines the methods implemented by delegates of any generic `TICDSOperation`. */

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
