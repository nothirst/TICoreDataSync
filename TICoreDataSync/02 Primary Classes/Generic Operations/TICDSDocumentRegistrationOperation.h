//
//  TICDSDocumentRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"
#import "TICDSClassesAndProtocols.h"

/** The `TICDSDocumentRegistrationOperation` class describes a generic operation used by the `TICoreDataSync` framework to register a document for future synchronization.
 
 The operation carries out the following tasks:
 
 1. Check whether the document has been previously registered with the remote (i.e., whether the file structure exists).
 2. If not, register the document and create the file structure.
 3. Check whether this client has previously been registered for this document (i.e., whether client-specific file structures exist).
 4. If not, create the necessary file structure for this client for this document.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSDocumentRegistrationOperation`.
 */

@interface TICDSDocumentRegistrationOperation : TICDSOperation {
@private
    BOOL _paused;
    BOOL _shouldCreateDocumentFileStructure;
    
    NSString *_documentIdentifier;
    NSString *_documentDescription;
    NSString *_clientDescription;
    NSDictionary *_userInfo;
    
    BOOL _documentHasBeenSynchronizedByAnyClient;
    BOOL _documentHasBeenSynchronizedByThisClient;
    
    BOOL _completionInProgress;
    TICDSOperationPhaseStatus _documentFileStructureStatus;
    TICDSOperationPhaseStatus _documentClientDeviceFileStructureStatus;
}

/** @name Designated Initializer */

/** Initialize a document registration operation using a delegate that supports the `TICDSDocumentRegistrationOperationDelegate` protocol.
 
 @param aDelegate The delegate to use for this operation.
 
 @return An initialized document registration operation. */
- (id)initWithDelegate:(NSObject<TICDSDocumentRegistrationOperationDelegate> *)aDelegate;

/** @name Methods Overridden by Subclasses */

/** Check whether this document has previously been registered; i.e., whether the remote file structure for this document already exists.
 
 Call `discoveredStatusOfRemoteDocumentFileStructure:` to indicate the status.
 */
- (void)checkWhetherRemoteDocumentFileStructureExists;

/** Create the file structure for this document; this method will be called automatically if the file structure dosn't already exist.
 
 Call `createdRemoteDocumentFileStructureWithSuccess:` to indicate whether the creation was successful.
 */
- (void)createRemoteDocumentFileStructure;

/** Check whether this client has previously been registered for this document; i.e., whether the files for this client device already exist.
 
 Call `discoveredStatusOfRemoteDocumentSyncChangesThisClientFileStructure:` to indicate the status.
 */
- (void)checkWhetherRemoteDocumentSyncChangesThisClientFileStructureExists;

/** Create the file structure for this client device for this document; this method will be called automatically if the file structure doesn't already exist.
 
 This file structure is currently just a directory with the `clientIdentifier` created inside the `SyncChanges` directory.
 
 Call `createdRemoteDocumentSyncChangesThisClientFileStructureWithSuccess:` to indicate whether the creation was successful.
 */
- (void)createRemoteDocumentSyncChangesThisClientFileStructure;

/** @name Callbacks */

/** Indicate the status of the remote document file structure; i.e., whether the document has previously been registered.
 
 If an error occurred, call `setError:` and return `TICDSRemoteFileStructureExistsResponseTypeError`.
 
 @param status The status of the structure: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfRemoteDocumentFileStructure:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the creation of the document file structure was successful.
 
 If not, call `setError:` and return `NO`.
 
 @param success A Boolean indicating whether the document file structure was created or not */
- (void)createdRemoteDocumentFileStructureWithSuccess:(BOOL)success;

/** Indicate the status of the file structure for this client; i.e. whether this client device has previously been registered.
 
 If an error occurred, call `setError:` and return `TICDSRemoteFileStructureExistsResponseTypeError`.
 
 @param status The status of the structure: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfRemoteDocumentSyncChangesThisClientFileStructure:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the creation of the file structure for this client was successful.
 
 If not, call `setError:` and return `NO`.
 
 @param someSuccess A Boolean indicating whether the document file structure was created or not. */
- (void)createdRemoteDocumentSyncChangesThisClientFileStructureWithSuccess:(BOOL)success;

/** @name Properties */

/** Used to indicate whether the operation is currently paused awaiting input from the operation delegate, or in turn the document sync manager delegate. */
@property (assign, getter = isPaused) BOOL paused;

/** Used by the `TICDSDocumentSyncManager` to indicate whether to create the remote document file structure after finding out it doesn't exist. */
@property (assign) BOOL shouldCreateDocumentFileStructure;

/** The document identifier. */
@property (retain) NSString *documentIdentifier;

/** The document description (typically a filename). */
@property (retain) NSString *documentDescription;

/** The client description. */
@property (retain) NSString *clientDescription;

/** The user info. */
@property (retain) NSDictionary *userInfo;

/** @name Completion */

/** Used to indicate that completion is currently in progress, and that no further checks should be made. */
@property (nonatomic, assign) BOOL completionInProgress;

/** The phase status of the document file structure tests/creation. */
@property (nonatomic, assign) TICDSOperationPhaseStatus documentFileStructureStatus;

/** The phase status of the client device file structure tests/creation. */
@property (nonatomic, assign) TICDSOperationPhaseStatus documentClientDeviceFileStructureStatus;

@end
