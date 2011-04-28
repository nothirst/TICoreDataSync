//
//  TICDSTypesAndEnums.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

/** Contains Typedefs and enums for the entire `TICoreDataSync` framework */

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
    
    /** Registration Phase */
    TICDSDocumentSyncManagerStateNotYetRegistered = -100,
    TICDSDocumentSyncManagerStateRegistering = -110,
    
    /** Helper Files */
    TICDSDocumentSyncManagerStateUnableToSyncBecauseDelegateProvidedHelperFileDirectoryDoesNotExist = -162,
    TICDSDocumentSyncManagerStateFailedToCreateDefaultHelperFileDirectory = -167,
    
    /** Synchronization */
    TICDSDocumentSyncManagerStateSynchronizing = -400
} TICDSDocumentSyncManagerState;

/** @name File Structure Existence */
/** Whether file structures exist or not 
 */
typedef enum _TICDSRemoteFileStructureExistsResponseType {
    
    TICDSRemoteFileStructureExistsResponseTypeError = 0,
    TICDSRemoteFileStructureExistsResponseTypeDoesNotExist = -1,
    TICDSRemoteFileStructureExistsResponseTypeDoesExist = 1,
    
} TICDSRemoteFileStructureExistsResponseType;

/** @name Logging */
/** Verbosity for Logging debugging output
 */
typedef enum _TICDSLogVerbosity {
    TICDSLogVerbosityNoLogging = 0,
    TICDSLogVerbosityErrorsOnly = 1,
    TICDSLogVerbosityStartAndEndOfMainPhase = 10,
    TICDSLogVerbosityStartAndEndOfEachPhase = 50,
    TICDSLogVerbosityEveryStep = 100
} TICDSLogVerbosity;

/** @name Errors */
/** Error codes
 */
typedef enum _TICDSErrorCode {
    
    TICDSErrorCodeNoError = 0,
    
    TICDSErrorCodeMethodNotOverriddenBySubclass,
    TICDSErrorCodeFileManagerError,
    TICDSErrorCodeUnexpectedOrIncompleteFileLocationOrDirectoryStructure,
    TICDSErrorCodeHelperFileDirectoryDoesNotExist,
    TICDSErrorCodeFailedToSaveSyncChangesMOC,
    TICDSErrorCodeFailedToCreateOperationObject,
    TICDSErrorCodeFileAlreadyExistsAtSpecifiedLocation,
    TICDSErrorCodeNoPreviouslyUploadedStoreExists,
    TICDSErrorCodeCoreDataFetchError,
    TICDSErrorCodeCoreDataSaveError,
} TICDSErrorCode;

/** @name Operation Phases */
/** The status of any particular phase of an operation 
 */
typedef enum _TICDSOperationPhaseStatus {
    TICDSOperationPhaseStatusInProgress = 0,
    
    TICDSOperationPhaseStatusSuccess = 1,
    TICDSOperationPhaseStatusFailure = -1,
    
} TICDSOperationPhaseStatus;

/** @name Sync Changes */
/** The type of a sync change
 */
typedef enum _TICDSSyncChangeType {
    TICDSSyncChangeTypeUnknown = 0,
    TICDSSyncChangeTypeObjectInserted = 1,
    TICDSSyncChangeTypeAttributeChanged = 2,
    TICDSSyncChangeTypeRelationshipChanged = 3,
    TICDSSyncChangeTypeObjectDeleted = 4,
} TICDSSyncChangeType;
