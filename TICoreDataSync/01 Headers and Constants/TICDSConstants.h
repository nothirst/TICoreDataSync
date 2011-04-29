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
extern NSString * const kTICDSErrorUnderlyingError;
extern NSString * const kTICDSErrorClassAndMethod;
extern NSString * const kTICDSErrorDomain;
extern NSString * const kTICDSStackTrace;

extern NSString * const kTICDSClientDeviceDescription;
extern NSString * const kTICDSClientDeviceUserInfo;
extern NSString * const kTICDSLastSyncDate;
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
extern NSString * const TICDSWholeStoreDirectoryName;
extern NSString * const TICDSSyncChangesDirectoryName;
extern NSString * const TICDSRecentSyncsDirectoryName;
extern NSString * const TICDSUnappliedChangesDirectoryName;
extern NSString * const TICDSUnsynchronizedSyncChangesStoreName;
extern NSString * const TICDSSyncChangesBeingSynchronizedStoreName;
extern NSString * const TICDSWholeStoreFilename;
extern NSString * const TICDSAppliedSyncChangeSetsFilename;
extern NSString * const TICDSUnappliedChangeSetsFilename;
extern NSString * const TICDSSyncCommandSetFileExtension;
extern NSString * const TICDSSyncChangeSetFileExtension;
extern NSString * const TICDSRecentSyncFileExtension;

extern NSString * const TICDSSyncIDAttributeName;
extern NSString * const TICDSSyncChangeDataModelName;
extern NSString * const TICDSSyncChangeSetDataModelName;

extern NSString * const kTICDSChangedAttributeValue;

extern NSString * const kTICDSSyncWarningType;
extern NSString * const kTICDSSyncWarningDescription;
extern NSString * const kTICDSSyncWarningEntityName;
extern NSString * const kTICDSSyncWarningAttributes;
extern NSString * const kTICDSSyncWarningRelatedObjectEntityName;

extern NSString * const TICDSApplicationSyncManagerDidRegisterSuccessfullyNotification;
extern NSString * const TICDSDocumentSyncManagerDidRegisterSuccessfullyNotification;