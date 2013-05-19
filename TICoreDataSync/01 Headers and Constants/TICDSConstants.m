//
//  TICDSStringConstants.m
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSConstants.h"

NSString * const TICDSFrameworkName = @"TICoreDataSync";

NSString * const TICDSSyncChangeTypeNames[] = {
    @"Unknown",
    @"Inserted",
    @"Deleted",
    @"Attribute Changed",
    @"Relationship Changed",
};

NSString * const TICDSSyncConflictTypeNames[] = {
    @"Unknown",
    @"Both local and remote have changes to the same attribute",
};

NSString * const TICDSSyncWarningTypeNames[] = {
    @"Unknown",
    
    @"Object not found locally for attribute sync change",
    @"Object not found locally for relationship sync change",
    @"Object not found locally for deletion sync change",
    @"Object with attributes changed locally has already been deleted remotely",
    @"Object with relationships changed locally has already been deleted remotely",
    @"Object with attributes changed remotely has been deleted locally",
    @"Object with relationships changed remotely has been deleted locally",
};

NSString * const kTICDSErrorUserInfo = @"kTICDSErrorUserInfo";
NSString * const kTICDSErrorClassAndMethod = @"kTICDSErrorClassAndMethod";
NSString * const kTICDSErrorDomain = @"com.timisted.ticoredatasync";
NSString * const kTICDSStackTrace = @"kTICDSStackTrace";

NSString * const FZACryptorErrorDomain = @"com.fuzzyaliens.fzacryptor";
NSString * const FZAKeyManagerErrorDomain = @"com.fuzzyaliens.fzacryptor.keymanager";
NSString * const kFZAKeyManagerSecurityFrameworkError = @"kFZAKeyManagerSecurityFrameworkError";

NSString * const kTICDSClientDeviceDescription = @"kTICDSClientDeviceDescription";
NSString * const kTICDSClientDeviceUserInfo = @"kTICDSClientDeviceUserInfo";
NSString * const kTICDSClientDeviceIdentifier = @"kTICDSClientDeviceIdentifier";
NSString * const kTICDSRegisteredDocumentIdentifiers = @"kTICDSRegisteredDocumentIdentifiers";
NSString * const kTICDSLastSyncDate = @"kTICDSLastSyncDate";
NSString * const kTICDSUploadedWholeStoreModificationDate = @"kTICDSUploadedWholeStoreModificationDate";
NSString * const kTICDSDocumentIdentifier = @"kTICDSDocumentIdentifier";
NSString * const kTICDSDocumentDescription = @"kTICDSDocumentDescription";
NSString * const kTICDSDocumentUserInfo = @"kTICDSDocumentUserInfo";
NSString * const kTICDSOriginalDeviceDescription = @"kTICDSOriginalDeviceDescription";
NSString * const kTICDSOriginalDeviceIdentifier = @"kTICDSOriginalDeviceIdentifier";

NSString * const kTICDSUtilitiesFileStructureClientDeviceUID = @"kTICDSUtilitiesFileStructureClientDeviceUID";
NSString * const kTICDSUtilitiesFileStructureDocumentUID = @"kTICDSUtilitiesFileStructureDocumentUID";

NSString * const kTICDSDocumentDownloadFinalWholeStoreLocation = @"kTICDSDocumentDownloadFinalWholeStoreLocation";

NSString * const TICDSClientDevicesDirectoryName = @"ClientDevices";
NSString * const TICDSDocumentsDirectoryName = @"Documents";
NSString * const TICDSEncryptionDirectoryName = @"Encryption";
NSString * const TICDSInformationDirectoryName = @"Information";
NSString * const TICDSWholeStoreDirectoryName = @"WholeStore";
NSString * const TICDSSyncChangesDirectoryName = @"SyncChanges";
NSString * const TICDSSyncCommandsDirectoryName = @"SyncCommands";
NSString * const TICDSRecentSyncsDirectoryName = @"RecentSyncs";
NSString * const TICDSTemporaryFilesDirectoryName = @"TemporaryFiles";
NSString * const TICDSDeletedDocumentsDirectoryName = @"DeletedDocuments";
NSString * const TICDSDeletedClientsDirectoryName = @"DeletedClients";
NSString * const TICDSIntegrityKeyDirectoryName = @"IntegrityKey";
NSString * const TICDSUnappliedSyncChangesDirectoryName = @"UnappliedSyncChanges";
NSString * const TICDSUnsavedAppliedSyncChangesDirectoryName = @"UnsavedAppliedSyncChanges";
NSString * const TICDSUnappliedSyncCommandsDirectoryName = @"UnappliedSyncCommands";
NSString * const TICDSUnsynchronizedSyncChangesStoreName = @"UnsynchronizedSyncChanges.syncchg";
NSString * const TICDSSyncChangesBeingSynchronizedStoreName = @"SyncChangesBeingSynchronized.syncchg";
NSString * const TICDSWholeStoreFilename = @"WholeStore.ticdsync";
NSString * const TICDSAppliedSyncChangeSetsFilename = @"AppliedSyncChangeSets.ticdsync";
NSString * const TICDSUnsavedAppliedSyncChangeSetsFileExtension = @"unsavedticdsync";
NSString * const TICDSUnappliedChangeSetsFilename = @"UnappliedSyncChangeSets.ticdsync";
NSString * const TICDSSyncCommandSetFileExtension = @"synccmd";
NSString * const TICDSSyncChangeSetFileExtension = @"syncchg";
NSString * const TICDSRecentSyncFileExtension = @"recentsync";
NSString * const TICDSDeviceInfoPlistFilenameWithExtension = @"deviceInfo.plist";
NSString * const TICDSDeviceInfoPlistFilename = @"deviceInfo";
NSString * const TICDSDeviceInfoPlistExtension = @"plist";
NSString * const TICDSDocumentInfoPlistFilenameWithExtension = @"documentInfo.plist";
NSString * const TICDSDocumentInfoPlistFilename = @"documentInfo";
NSString * const TICDSDocumentInfoPlistExtension = @"plist";
NSString * const TICDSSaltFilenameWithExtension = @"salt.ticdsync";
NSString * const TICDSEncryptionTestFilenameWithExtension = @"test.ticdsync";
NSString * const TICDSUserDefaultsPrefix = @"TICDSync.";
NSString * const TICDSUserDefaultsIntegrityKeyComponent = @"integrityKey.";

NSString * const TICDSSyncIDAttributeName = @"ticdsSyncID";
NSString * const TICDSSyncChangeDataModelName = @"TICDSSyncChange";
NSString * const TICDSSyncChangeSetDataModelName = @"TICDSSyncChangeSet";

NSString * const kTICDSChangedAttributeValue = @"kTICDSChangedAttributeValue";

NSString * const kTICDSSyncWarningType = @"kTICDSSyncWarningType";
NSString * const kTICDSSyncWarningDescription = @"kTICDSSyncWarningDescription";
NSString * const kTICDSSyncWarningEntityName = @"kTICDSSyncWarningEntityName";
NSString * const kTICDSSyncWarningAttributes = @"kTICDSSyncWarningAttributes";
NSString * const kTICDSSyncWarningRelatedObjectEntityName = @"kTICDSSyncWarningRelatedObjectEntityName";

NSString * const TICDSApplicationSyncManagerDidFinishRegisteringNotification = @"TICDSApplicationSyncManagerDidFinishRegisteringNotification";
NSString * const TICDSDocumentSyncManagerDidRegisterSuccessfullyNotification = @"TICDSDocumentSyncManagerDidRegisterSuccessfullyNotification";
NSString * const TICDSApplicationSyncManagerWillRemoveAllSyncDataNotification = @"TICDSApplicationSyncManagerWillRemoveAllSyncDataNotification";
NSString * const TICDSApplicationSyncManagerDidIncreaseActivityNotification = @"TICDSApplicationSyncManagerDidIncreaseActivityNotification";
NSString * const TICDSApplicationSyncManagerDidDecreaseActivityNotification = @"TICDSApplicationSyncManagerDidDecreaseActivityNotification";
NSString * const TICDSDocumentSyncManagerDidIncreaseActivityNotification = @"TICDSDocumentSyncManagerDidIncreaseActivityNotification";
NSString * const TICDSDocumentSyncManagerDidDecreaseActivityNotification = @"TICDSDocumentSyncManagerDidDecreaseActivityNotification";
NSString *const TICDSDocumentSyncManagerDidDirtyDocumentNotification = @"TICDSDocumentSyncManagerDidDirtyDocumentNotification";
