//
//  TICDSDocumentSyncManager.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSClassesAndProtocols.h"
#import "TICDSTypesAndEnums.h"


@interface TICDSDocumentSyncManager : NSObject {
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

/** Register document for synchronization */
/** Call this method before using the sync manager for any other purpose */
- (void)registerWithDelegate:(id <TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager managedObjectContext:(TICDSSynchronizedManagedObjectContext *)aContext documentIdentifier:(NSString *)aDocumentIdentifier description:(NSString *)aDocumentDescription userInfo:(NSDictionary *)someUserInfo;

/** Continue the document registration operation by creating (YES or NO) the file structure */
/** If no, registration will fail with an error */
- (void)continueRegistrationByCreatingRemoteFileStructure:(BOOL)shouldCreateFileStructure;

#pragma mark -
#pragma mark Methods Overridden by Subclasses
- (TICDSDocumentRegistrationOperation *)documentRegistrationOperation;

#pragma mark -
#pragma mark MOC Saving
- (void)synchronizedMOCWillSave:(TICDSSynchronizedManagedObjectContext *)aMoc;
- (void)synchronizedMOCDidSave:(TICDSSynchronizedManagedObjectContext *)aMoc;
- (void)synchronizedMOCFailedToSave:(TICDSSynchronizedManagedObjectContext *)aMoc withError:(NSError *)anError;

@property (nonatomic, assign) id <TICDSDocumentSyncManagerDelegate> delegate;
@property (nonatomic, assign) TICDSDocumentSyncManagerState state;
@property (nonatomic, retain) TICDSApplicationSyncManager *applicationSyncManager;
@property (nonatomic, readonly, retain) NSString *documentIdentifier;
@property (nonatomic, readonly, retain) NSString *documentDescription;
@property (nonatomic, readonly, retain) NSString *clientIdentifier;
@property (nonatomic, readonly, retain) NSDictionary *userInfo;
@property (nonatomic, readonly) NSString *relativePathToDocumentsDirectory;
@property (nonatomic, readonly) NSString *relativePathToThisDocumentDirectory;
@property (nonatomic, readonly) NSString *relativePathToThisDocumentSyncChangesDirectory;
@property (nonatomic, readonly) NSString *relativePathToThisDocumentSyncChangesThisClientDirectory;

@property (nonatomic, readonly) NSString * unsynchronizedSyncChangesStorePath;

/*@property (nonatomic, readonly) NSString *relativePathToThisDocumentSyncChangesDirectory;
@property (nonatomic, readonly) NSString *relativePathToThisDocumentClientDeviceDirectory;
@property (nonatomic, readonly) NSString *relativePathToThisDocumentWholeStoreDirectory;
@property (nonatomic, readonly) NSString *relativePathToThisDocumentWholeStoreThisClientDeviceDirectory;
@property (nonatomic, readonly) NSString *unsynchronizedSyncChangesStorePath;
@property (nonatomic, readonly) NSString *localSyncChangesToPushDirectory;*/
@property (nonatomic, retain) NSFileManager *fileManager;
@property (retain) NSURL *helperFileDirectoryLocation;
@property (nonatomic, retain) TICDSSynchronizedManagedObjectContext *primaryDocumentMOC;
@property (nonatomic, retain) TICoreDataFactory *coreDataFactory;
@property (nonatomic, retain) NSManagedObjectContext *syncChangesMOC;
@property (nonatomic, retain) NSOperationQueue *registrationQueue;
@property (nonatomic, retain) NSOperationQueue *synchronizationQueue;
@property (nonatomic, retain) NSOperationQueue *otherTasksQueue;

@end
