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
typedef NS_ENUM(NSInteger, TICDSApplicationSyncManagerState)
{
    TICDSApplicationSyncManagerStateUnknown = 0,

    TICDSApplicationSyncManagerStateAbleToSync = 1,

    /** Registration Phase */
    TICDSApplicationSyncManagerStateNotYetRegistered = -100,
    TICDSApplicationSyncManagerStateRegistering = -110,
};

/** The state of a Document Sync Manager
 */
typedef NS_ENUM(NSInteger, TICDSDocumentSyncManagerState)
{
    TICDSDocumentSyncManagerStateUnknown = 0,

    TICDSDocumentSyncManagerStateAbleToSync = 1,

    /** Registration Phase */
    TICDSDocumentSyncManagerStateNotYetRegistered = -100,
    TICDSDocumentSyncManagerStateRegistering = -110,

    /** Helper Files */
    TICDSDocumentSyncManagerStateUnableToSyncBecauseDelegateProvidedHelperFileDirectoryDoesNotExist = -162,
    TICDSDocumentSyncManagerStateFailedToCreateDefaultHelperFileDirectory = -167,

    /** Synchronization */
    TICDSDocumentSyncManagerStateSynchronizing = -400
};

#pragma mark File Structure Existence
/** @name File Structure Existence */
/** Whether file structures exist or not
 */
typedef NS_ENUM(NSInteger, TICDSRemoteFileStructureExistsResponseType)
{
    TICDSRemoteFileStructureExistsResponseTypeError = 0,
    TICDSRemoteFileStructureExistsResponseTypeDoesNotExist = -1,
    TICDSRemoteFileStructureExistsResponseTypeDoesExist = 1,
};

/** Whether files or directories were deleted. */
typedef NS_ENUM(NSInteger, TICDSRemoteFileStructureDeletionResponseType)
{
    TICDSRemoteFileStructureDeletionResponseTypeError = 0,
    TICDSRemoteFileStructureDeletionResponseTypeDeleted = -1,
    TICDSRemoteFileStructureDeletionResponseTypeNotDeleted = 1,
};

#pragma mark Logging
/** @name Logging */
/** Verbosity for Logging debugging output
 */
typedef NS_ENUM(NSInteger, TICDSLogVerbosity)
{
    TICDSLogVerbosityNoLogging = 0,
    TICDSLogVerbosityErrorsOnly = 1,
    TICDSLogVerbosityManagedObjectOutput = 9,
    TICDSLogVerbosityStartAndEndOfMainPhase = 10,
    TICDSLogVerbosityStartAndEndOfEachPhase = 20,
    TICDSLogVerbosityStartAndEndOfMainOperationPhase = 50,
    TICDSLogVerbosityStartAndEndOfEachOperationPhase = 60,
    TICDSLogVerbosityEveryStep = 100,
    TICDSLogVerbosityDirectoryWatcherPickUpEventIssue = 200,
};

#pragma mark Errors
/** @name Errors */
/** Error codes
 */
typedef NS_ENUM(NSInteger, TICDSErrorCode)
{
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
    TICDSErrorCodeCompressionError,
    TICDSErrorCodeUnableToRegisterUnconfiguredSyncManager,
    TICDSErrorCodeFZACryptorCreatedSaltDataButRespondedThatItWasNotCorrectlyConfiguredForEncryption,
    TICDSErrorCodeSynchronizationFailedBecauseIntegrityKeysDoNotMatch,
    TICDSErrorCodeSynchronizationFailedBecauseIntegrityKeyDirectoryIsMissing,
};

typedef NS_ENUM(NSInteger, FZACryptorErrorCode)
{
    FZACryptorErrorCodeFailedIntegrityCheck = 10000,
};

#pragma mark Operation Phases
/** @name Operation Phases */
/** The status of any particular phase of an operation
 */
typedef NS_ENUM(NSInteger, TICDSOperationPhaseStatus)
{
    TICDSOperationPhaseStatusInProgress = 0,

    TICDSOperationPhaseStatusSuccess = 1,
    TICDSOperationPhaseStatusFailure = -1,
};

#pragma mark Sync Changes
/** @name Sync Changes */
/** The type of a sync change
 */
typedef NS_ENUM(NSInteger, TICDSSyncChangeType)
{
    TICDSSyncChangeTypeUnknown = 0,
    TICDSSyncChangeTypeObjectInserted = 1,
    TICDSSyncChangeTypeAttributeChanged = 2,
    TICDSSyncChangeTypeToOneRelationshipChanged = 3,
    TICDSSyncChangeTypeToManyRelationshipChangedByAddingObject = 4,
    TICDSSyncChangeTypeToManyRelationshipChangedByRemovingObject = 5,
    TICDSSyncChangeTypeObjectDeleted = 10
};

#pragma mark Sync Warnings
/** @name Sync Warnings */
/** The type of a sync warning */
typedef NS_ENUM(NSInteger, TICDSSyncWarningType)
{
    TICDSSyncWarningTypeUnknown = 0,

    TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteAttributeSyncChange = 1,
    TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteRelationshipSyncChange = 2,
    TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteDeletionSyncChange = 3,
    TICDSSyncWarningTypeObjectWithAttributesChangedLocallyAlreadyDeletedByRemoteSyncChange = 4,
    TICDSSyncWarningTypeObjectWithRelationshipsChangedLocallyAlreadyDeletedByRemoteSyncChange = 5,
    TICDSSyncWarningTypeObjectWithAttributesChangedRemotelyNowDeletedByLocalSyncChange = 6,
    TICDSSyncWarningTypeObjectWithRelationshipsChangedRemotelyNowDeletedByLocalSyncChange = 7,
};

#pragma mark Sync Transactions

/** @name Sync Transactions */
/** The states of a sync transaction */
typedef NS_ENUM(NSInteger, TICDSSyncTransactionState) {
    TICDSSyncTransactionStateNotYetOpen = -1,
    TICDSSyncTransactionStateOpen = 1,
    TICDSSyncTransactionStateClosed = 0,
    TICDSSyncTransactionStateUnableToClose = -2
};

#pragma mark Sync Conflicts
/** @name Sync Conflicts */

/** The type of a sync conflict. */
typedef NS_ENUM(NSInteger, TICDSSyncConflictType)
{
    TICDSSyncConflictTypeUnknown = 0,
    TICDSSyncConflictRemoteAttributeChangedAndLocalAttributeChanged = 1,
};

/** The resolution for a sync conflict. */
typedef NS_ENUM(NSInteger, TICDSSyncConflictResolutionType)
{
    TICDSSyncConflictResolutionTypeUnknown = 0,

    TICDSSyncConflictResolutionTypeRemoteWins = 1,
    TICDSSyncConflictResolutionTypeLocalWins = 2,
};
