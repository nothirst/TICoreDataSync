//
//  TICDSApplicationRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSApplicationRegistrationOperation` class describes a generic operation used by the `TICoreDataSync` framework to register an application for future synchronization of documents.
 
 The operation carries out the following tasks:
 
 1. Check whether the application has been previously registered with the remote (i.e., whether the file structure exists).
 2. If not, register the app and create the file structure.
 3. Check whether this client has previously been registered for this application (i.e., whether client-specific file structures exist).
 4. If not, create the necessary file structure for this client.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSApplicationRegistrationOperation`.
 */
 
@interface TICDSApplicationRegistrationOperation : TICDSOperation {
@private
    NSString *_appIdentifier;
    NSString *_clientDescription;
    NSDictionary *_userInfo;
    
    BOOL _completionInProgress;
    TICDSOperationPhaseStatus _globalAppFileStructureStatus;
    TICDSOperationPhaseStatus _clientDeviceFileStructureStatus;
}

/** @name Methods Overridden by Subclasses */

/** Check whether this application has previously been registered; i.e., whether the remote file structure for this application already exists.
 
 This method must call `discoveredStatusOfRemoteGlobalAppFileStructure:` to indicate the status.
 */
- (void)checkWhetherRemoteGlobalAppFileStructureExists;

/** Create the file structure for this application; this method will be called automatically if the file structure dosn't already exist.
 
 This method must call `createdRemoteGlobalAppFileStructureSuccessfully:` to indicate whether the creation was successful.
 */
- (void)createRemoteGlobalAppFileStructure;

/** Check whether this client has previously been registered for this application; i.e., whether the files for this client device already exist.
 
 This method must call `discoveredStatusOfRemoteClientDeviceFileStructure:` to indicate the status.
 */
- (void)checkWhetherRemoteGlobalAppThisClientDeviceFileStructureExists;

/** Create the file structure for this client device for this application; this method will be called automatically if the file structure doesn't already exist.
 
 This method must call `createdRemoteClientDeviceFileStructureSuccessfully:` to indicate whether the creation was successful.
 */
- (void)createRemoteGlobalAppThisClientDeviceFileStructure;

/** @name Callbacks */

/** Indicate the status of the remote global app file structure; i.e., whether the application has previously been registered.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the structure: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfRemoteGlobalAppFileStructure:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the creation of the global app file structure was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the global app file structure was created or not. */
- (void)createdRemoteGlobalAppFileStructureSuccessfully:(BOOL)success;

/** Indicate the status of the file structure for this client; i.e. whether this client device has previously been registered.
 
 If an error occurred, call `setError:` first, then specify `TICDSRemoteFileStructureExistsResponseTypeError` for `status`.
 
 @param status The status of the structure: does exist, does not exist, or error (see `TICDSTypesAndEnums.h` for possible values). */
- (void)discoveredStatusOfRemoteClientDeviceFileStructure:(TICDSRemoteFileStructureExistsResponseType)status;

/** Indicate whether the creation of the file structure for this client was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the global app file structure was created or not. */
- (void)createdRemoteClientDeviceFileStructureSuccessfully:(BOOL)success;

/** @name Properties */

/** The application identifier. */
@property (nonatomic, retain) NSString *appIdentifier;

/** The client description. */
@property (nonatomic, retain) NSString *clientDescription;

/** The user info. */
@property (nonatomic, retain) NSDictionary *userInfo;

/** @name Completion */

/** Used to indicate that completion is currently in progress, and no further checks should be made. */
@property (nonatomic, assign) BOOL completionInProgress;

/** The phase status of the global app file structure tests/creation. */
@property (nonatomic, assign) TICDSOperationPhaseStatus globalAppFileStructureStatus;

/** The phase status of the client device file structure tests/creation. */
@property (nonatomic, assign) TICDSOperationPhaseStatus clientDeviceFileStructureStatus;

@end
