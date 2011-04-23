//
//  TICDSTypesAndEnums.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#pragma mark -
#pragma mark TYPEDEFS
#pragma mark Sync Managers
typedef enum _TICDSApplicationSyncManagerState {
    TICDSApplicationSyncManagerStateUnknown = 0,
    
    TICDSApplicationSyncManagerStateAbleToSync = 1,
    
    // Registration Phase
    TICDSApplicationSyncManagerStateNotYetRegistered = -100,
    TICDSApplicationSyncManagerStateRegistering = -110,
} TICDSApplicationSyncManagerState;

typedef enum _TICDSDocumentSyncManagerState {
    TICDSDocumentSyncManagerStateUnknown = 0,
    
    TICDSDocumentSyncManagerStateAbleToSync = 1,
    
    // Registration Phase
    TICDSDocumentSyncManagerStateNotYetRegistered = -100,
    TICDSDocumentSyncManagerStateRegistering = -110,
    
    // Helper Files
    TICDSDocumentSyncManagerStateUnableToSyncBecauseDelegateProvidedHelperFileDirectoryDoesNotExist = -162,
    TICDSDocumentSyncManagerStateFailedToCreateDefaultHelperFileDirectory = -167,
    
    // Synchronization
    TICDSDocumentSyncManagerStateSynchronizing = -400
} TICDSDocumentSyncManagerState;

#pragma mark Existence
typedef enum _TICDSRemoteFileStructureExistsResponseType {
    
    TICDSRemoteFileStructureExistsResponseTypeError = 0,
    TICDSRemoteFileStructureExistsResponseTypeDoesNotExist = -1,
    TICDSRemoteFileStructureExistsResponseTypeDoesExist = 1,
    
} TICDSRemoteFileStructureExistsResponseType;

#pragma mark Logging
typedef enum _TICDSLogVerbosity {
    TICDSLogVerbosityNoLogging = 0,
    TICDSLogVerbosityErrorsOnly = 1,
    TICDSLogVerbosityStartAndEndOfMainPhase = 10,
    TICDSLogVerbosityStartAndEndOfEachPhase = 50,
    TICDSLogVerbosityEveryStep = 100
} TICDSLogVerbosity;

#pragma mark Errors
typedef enum _TICDSErrorCode {
    
    TICDSErrorCodeNoError = 0,
    
    TICDSErrorCodeMethodNotOverriddenBySubclass,
    TICDSErrorCodeFileManagerError,
    TICDSErrorCodeUnexpectedOrIncompleteDirectoryStructure,
    TICDSErrorCodeHelperFileDirectoryDoesNotExist,
    TICDSErrorCodeFailedToSaveSyncChangesMOC,
    TICDSErrorCodeFailedToCreateOperationObject,
    TICDSErrorCodeFileAlreadyExistsAtSpecifiedLocation,
    TICDSErrorCodeNoPreviouslyUploadedStoreExists,
    TICDSErrorCodeCoreDataFetchError,
    TICDSErrorCodeCoreDataSaveError,
} TICDSErrorCode;

#pragma mark Operations
typedef enum _TICDSOperationPhaseStatus {
    TICDSOperationPhaseStatusInProgress = 0,
    
    TICDSOperationPhaseStatusSuccess = 1,
    TICDSOperationPhaseStatusFailure = -1,
    
} TICDSOperationPhaseStatus;

#pragma mark -
#pragma mark STRING CONSTANTS
extern NSString * const TICDSErrorUserInfoKey;
extern NSString * const TICDSErrorUnderlyingErrorKey;
extern NSString * const TICDSErrorClassAndMethod;
extern NSString * const TICDSErrorDomain;

extern NSString * const kTICDSClientDeviceDescription;
extern NSString * const kTICDSClientDeviceUserInfo;
extern NSString * const kTICDSLastSyncDate;
extern NSString * const kTICDSDocumentIdentifier;
extern NSString * const kTICDSDocumentName;
extern NSString * const kTICDSDocumentUserInfo;
extern NSString * const kTICDSOriginalDeviceDescription;
extern NSString * const kTICDSOriginalDeviceIdentifier;

extern NSString * const kTICDSUtilitiesFileStructureClientDeviceUID;
extern NSString * const kTICDSUtilitiesFileStructureDocumentUID;

extern NSString * const TICDSClientDevicesDirectoryName;
extern NSString * const TICDSDocumentsDirectoryName;
extern NSString * const TICDSSyncChangesDirectoryName;
extern NSString * const TICDSUnappliedChangesDirectoryName;
extern NSString * const TICDSSyncChangesToPushDirectoryName;

extern NSString * const TICDSApplicationSyncManagerDidRegisterSuccessfullyNotification;
extern NSString * const TICDSDocumentSyncManagerDidRegisterSuccessfullyNotification;