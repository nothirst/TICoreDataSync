//
//  TICDSTypesAndEnums.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

/** Contains Typedefs and enums for the entire `TICoreDataSync` framework */

#pragma mark Sync Managers
/** @name Sync Managers */
/** The state of an Application Sync Manager 
 */
typedef enum _TICDSApplicationSyncManagerState {
    TICDSApplicationSyncManagerStateUnknown = 0,
    
    TICDSApplicationSyncManagerStateAbleToSync = 1,
    
    /** Configuration Phase */
    TICDSApplicationSyncManagerStateConfigured = -50,
    
    /** Registration Phase */
    TICDSApplicationSyncManagerStateNotYetRegistered = -100,
    TICDSApplicationSyncManagerStateRegistering = -110,
} TICDSApplicationSyncManagerState;

/** The state of a Document Sync Manager 
 */
typedef enum _TICDSDocumentSyncManagerState {
    TICDSDocumentSyncManagerStateUnknown = 0,
    
    TICDSDocumentSyncManagerStateAbleToSync = 1,
    
    /** Configuration Phase */
    TICDSDocumentSyncManagerStateConfigured = -50,
    
    /** Registration Phase */
    TICDSDocumentSyncManagerStateNotYetRegistered = -100,
    TICDSDocumentSyncManagerStateRegistering = -110,
    
    /** Helper Files */
    TICDSDocumentSyncManagerStateUnableToSyncBecauseDelegateProvidedHelperFileDirectoryDoesNotExist = -162,
    TICDSDocumentSyncManagerStateFailedToCreateDefaultHelperFileDirectory = -167,
    
    /** Synchronization */
    TICDSDocumentSyncManagerStateSynchronizing = -400
} TICDSDocumentSyncManagerState;

#pragma mark File Structure Existence
/** @name File Structure Existence */
/** Whether file structures exist or not 
 */
typedef enum _TICDSRemoteFileStructureExistsResponseType {
    
    TICDSRemoteFileStructureExistsResponseTypeError = 0,
    TICDSRemoteFileStructureExistsResponseTypeDoesNotExist = -1,
    TICDSRemoteFileStructureExistsResponseTypeDoesExist = 1,
    
} TICDSRemoteFileStructureExistsResponseType;

/** Whether files or directories were deleted. */
typedef enum _TICDSRemoteFileStructureDeletionResponseType {
    TICDSRemoteFileStructureDeletionResponseTypeError = 0,
    TICDSRemoteFileStructureDeletionResponseTypeDeleted = -1, 
    TICDSRemoteFileStructureDeletionResponseTypeNotDeleted = 1,
} TICDSRemoteFileStructureDeletionResponseType;

#pragma mark Logging
/** @name Logging */
/** Verbosity for Logging debugging output
 */
typedef enum _TICDSLogVerbosity {
    TICDSLogVerbosityNoLogging = 0,
    TICDSLogVerbosityErrorsOnly = 1,
    TICDSLogVerbosityStartAndEndOfMainPhase = 10,
    TICDSLogVerbosityStartAndEndOfEachPhase = 20,
    TICDSLogVerbosityStartAndEndOfMainOperationPhase = 50,
    TICDSLogVerbosityStartAndEndOfEachOperationPhase = 60,
    TICDSLogVerbosityManagedObjectOutput = 80,
    TICDSLogVerbosityEveryStep = 100
} TICDSLogVerbosity;

#pragma mark Errors
/** @name Errors */
/** Error codes
 */
typedef enum _TICDSErrorCode {
    
    TICDSErrorCodeNoError = 0,
    
    TICDSErrorCodeMethodNotOverriddenBySubclass,
    TICDSErrorCodeFileManagerError,
    TICDSErrorCodeUnexpectedOrIncompleteFileLocationOrDirectoryStructure,
    TICDSErrorCodeHelperFileDirectoryDoesNotExist,
    TICDSErrorCodeFailedToCreateSyncChangesMOC,
    TICDSErrorCodeFailedToSaveSyncChangesMOC,
    TICDSErrorCodeFailedToCreateOperationObject,
    TICDSErrorCodeFileAlreadyExistsAtSpecifiedLocation,
    TICDSErrorCodeNoPreviouslyUploadedStoreExists,
    TICDSErrorCodeCoreDataFetchError,
    TICDSErrorCodeCoreDataSaveError,
    TICDSErrorCodeObjectCreationError,
    TICDSErrorCodeWholeStoreCannotBeUploadedWhileThereAreUnsynchronizedSyncChanges,
    TICDSErrorCodeTaskWasCancelled,
    TICDSErrorCodeDropboxSDKRestClientError,
    TICDSErrorCodeEncryptionError,
    TICDSErrorCodeUnableToRegisterUnconfiguredSyncManager,
    TICDSErrorCodeFZACryptorCreatedSaltDataButRespondedThatItWasNotCorrectlyConfiguredForEncryption,
} TICDSErrorCode;

typedef enum _FZACryptorErrorCode {
    FZACryptorErrorCodeFailedIntegrityCheck = 10000,
} FZACryptorErrorCode;

#pragma mark Operation Phases
/** @name Operation Phases */
/** The status of any particular phase of an operation 
 */
typedef enum _TICDSOperationPhaseStatus {
    TICDSOperationPhaseStatusInProgress = 0,
    
    TICDSOperationPhaseStatusSuccess = 1,
    TICDSOperationPhaseStatusFailure = -1,
    
} TICDSOperationPhaseStatus;

#pragma mark Sync Changes
/** @name Sync Changes */
/** The type of a sync change
 */
typedef enum _TICDSSyncChangeType {
    TICDSSyncChangeTypeUnknown = 0,
    TICDSSyncChangeTypeObjectInserted = 1,
    TICDSSyncChangeTypeAttributeChanged = 2,
    TICDSSyncChangeTypeToOneRelationshipChanged = 3,
    TICDSSyncChangeTypeToManyRelationshipChangedByAddingObject = 4,
    TICDSSyncChangeTypeToManyRelationshipChangedByRemovingObject = 5,
    TICDSSyncChangeTypeObjectDeleted = 10
} TICDSSyncChangeType;

#pragma mark Sync Warnings
/** @name Sync Warnings */
/** The type of a sync warning */
typedef enum _TICDSSyncWarningType {
    TICDSSyncWarningTypeUnknown = 0,
    
    TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteAttributeSyncChange = 1,
    TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteRelationshipSyncChange = 2,
    TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteDeletionSyncChange = 3,
    TICDSSyncWarningTypeObjectWithAttributesChangedLocallyAlreadyDeletedByRemoteSyncChange = 4,
    TICDSSyncWarningTypeObjectWithRelationshipsChangedLocallyAlreadyDeletedByRemoteSyncChange = 5,
    TICDSSyncWarningTypeObjectWithAttributesChangedRemotelyNowDeletedByLocalSyncChange = 6,
    TICDSSyncWarningTypeObjectWithRelationshipsChangedRemotelyNowDeletedByLocalSyncChange = 7,
    
} TICDSSyncWarningType;

#pragma mark Sync Conflicts
/** @name Sync Conflicts */

/** The type of a sync conflict. */
typedef enum _TICDSSyncConflictType {
    TICDSSyncConflictTypeUnknown = 0,
    TICDSSyncConflictRemoteAttributeChangedAndLocalAttributeChanged = 1,
} TICDSSyncConflictType;

/** The resolution for a sync conflict. */
typedef enum _TICDSSyncConflictResolutionType {
    TICDSSyncConflictResolutionTypeUnknown = 0,
    
    TICDSSyncConflictResolutionTypeRemoteWins = 1,
    TICDSSyncConflictResolutionTypeLocalWins = 2,
} TICDSSyncConflictResolutionType;