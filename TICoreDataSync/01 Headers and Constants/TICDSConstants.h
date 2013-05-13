//
//  TICDSStringConstants.h
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

extern NSString * const TICDSFrameworkName;

#define TICDSSyncChangesCoreDataPersistentStoreType NSBinaryStoreType
#define TICDSSyncChangeSetsCoreDataPersistentStoreType NSSQLiteStoreType

extern NSString * const TICDSSyncChangeTypeNames[];
extern NSString * const TICDSSyncWarningTypeNames[];
extern NSString * const TICDSSyncConflictTypeNames[];

extern NSString * const kTICDSErrorUserInfo;
extern NSString * const kTICDSErrorClassAndMethod;
extern NSString * const kTICDSErrorDomain;
extern NSString * const kTICDSStackTrace;

extern NSString * const FZACryptorErrorDomain;
extern NSString * const FZAKeyManagerErrorDomain;
extern NSString * const kFZAKeyManagerSecurityFrameworkError;

extern NSString * const kTICDSClientDeviceDescription;
extern NSString * const kTICDSClientDeviceUserInfo;
extern NSString * const kTICDSClientDeviceIdentifier;
extern NSString * const kTICDSRegisteredDocumentIdentifiers;
extern NSString * const kTICDSLastSyncDate;
extern NSString * const kTICDSUploadedWholeStoreModificationDate;
extern NSString * const kTICDSDocumentIdentifier;
extern NSString * const kTICDSDocumentDescription;
extern NSString * const kTICDSDocumentUserInfo;
extern NSString * const kTICDSOriginalDeviceDescription;
extern NSString * const kTICDSOriginalDeviceIdentifier;

extern NSString * const kTICDSUtilitiesFileStructureClientDeviceUID;
extern NSString * const kTICDSUtilitiesFileStructureDocumentUID;

extern NSString * const kTICDSDocumentDownloadFinalWholeStoreLocation;

extern NSString * const TICDSClientDevicesDirectoryName;
extern NSString * const TICDSDocumentsDirectoryName;
extern NSString * const TICDSEncryptionDirectoryName;
extern NSString * const TICDSInformationDirectoryName;
extern NSString * const TICDSWholeStoreDirectoryName;
extern NSString * const TICDSSyncChangesDirectoryName;
extern NSString * const TICDSSyncCommandsDirectoryName;
extern NSString * const TICDSRecentSyncsDirectoryName;
extern NSString * const TICDSTemporaryFilesDirectoryName;
extern NSString * const TICDSDeletedDocumentsDirectoryName;
extern NSString * const TICDSDeletedClientsDirectoryName;
extern NSString * const TICDSIntegrityKeyDirectoryName;
extern NSString * const TICDSUnappliedSyncChangesDirectoryName;
extern NSString * const TICDSUnsavedAppliedSyncChangesDirectoryName;
extern NSString * const TICDSUnappliedSyncCommandsDirectoryName;
extern NSString * const TICDSUnsynchronizedSyncChangesStoreName;
extern NSString * const TICDSSyncChangesBeingSynchronizedStoreName;
extern NSString * const TICDSWholeStoreFilename;
extern NSString * const TICDSAppliedSyncChangeSetsFilename;
extern NSString * const TICDSUnsavedAppliedSyncChangeSetsFileExtension;
extern NSString * const TICDSUnappliedChangeSetsFilename;
extern NSString * const TICDSSyncCommandSetFileExtension;
extern NSString * const TICDSSyncChangeSetFileExtension;
extern NSString * const TICDSRecentSyncFileExtension;
extern NSString * const TICDSDeviceInfoPlistFilenameWithExtension;
extern NSString * const TICDSDeviceInfoPlistFilename;
extern NSString * const TICDSDeviceInfoPlistExtension;
extern NSString * const TICDSDocumentInfoPlistFilenameWithExtension;
extern NSString * const TICDSDocumentInfoPlistFilename;
extern NSString * const TICDSDocumentInfoPlistExtension;
extern NSString * const TICDSSaltFilenameWithExtension;
extern NSString * const TICDSEncryptionTestFilenameWithExtension;
extern NSString * const TICDSUserDefaultsPrefix;
extern NSString * const TICDSUserDefaultsIntegrityKeyComponent;

extern NSString * const TICDSSyncIDAttributeName;
extern NSString * const TICDSSyncChangeDataModelName;
extern NSString * const TICDSSyncChangeSetDataModelName;

extern NSString * const kTICDSChangedAttributeValue;

extern NSString * const kTICDSSyncWarningType;
extern NSString * const kTICDSSyncWarningDescription;
extern NSString * const kTICDSSyncWarningEntityName;
extern NSString * const kTICDSSyncWarningAttributes;
extern NSString * const kTICDSSyncWarningRelatedObjectEntityName;

extern NSString * const TICDSApplicationSyncManagerDidFinishRegisteringNotification;
extern NSString * const TICDSDocumentSyncManagerDidRegisterSuccessfullyNotification;
extern NSString * const TICDSApplicationSyncManagerWillRemoveAllSyncDataNotification;
extern NSString * const TICDSApplicationSyncManagerDidIncreaseActivityNotification;
extern NSString * const TICDSApplicationSyncManagerDidDecreaseActivityNotification;
extern NSString * const TICDSDocumentSyncManagerDidIncreaseActivityNotification;
extern NSString * const TICDSDocumentSyncManagerDidDecreaseActivityNotification;

/** For NSDocument or UIDocument-based applications this notification is essential to ensure that the document is marked as dirty. Because TICDS disables the undo manager when applying sync changes the document's normal change tracking is also disabled. In your main application you should subscribe to this notification and call `updateChangeCount:` on the appropriate document.
*/
extern NSString *const TICDSDocumentSyncManagerDidDirtyDocumentNotification;
