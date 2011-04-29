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

NSString * const TICDSErrorUserInfoKey = @"TICDSErrorUserInfoKey";
NSString * const TICDSErrorUnderlyingErrorKey = @"TICDSErrorUnderlyingErrorKey";
NSString * const TICDSErrorClassAndMethod = @"TICDSErrorClassAndMethod";
NSString * const TICDSErrorDomain = @"com.timisted.ticoredatasync";

NSString * const kTICDSClientDeviceDescription = @"kTICDSClientDeviceDescription";
NSString * const kTICDSClientDeviceUserInfo = @"kTICDSClientDeviceUserInfo";
NSString * const kTICDSLastSyncDate = @"kTICDSLastSyncDate";
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
NSString * const TICDSWholeStoreDirectoryName = @"WholeStore";
NSString * const TICDSSyncChangesDirectoryName = @"SyncChanges";
NSString * const TICDSRecentSyncsDirectoryName = @"RecentSyncs";
NSString * const TICDSUnappliedChangesDirectoryName = @"UnappliedSyncChanges";
NSString * const TICDSUnsynchronizedSyncChangesStoreName = @"UnsynchronizedSyncChanges.syncchg";
NSString * const TICDSSyncChangesBeingSynchronizedStoreName = @"SyncChangesBeingSynchronized.syncchg";
NSString * const TICDSWholeStoreFilename = @"WholeStore.ticdsync";
NSString * const TICDSAppliedSyncChangeSetsFilename = @"AppliedSyncChangeSets.ticdsync";
NSString * const TICDSUnappliedChangeSetsFilename = @"UnappliedSyncChangeSets.ticdsync";
NSString * const TICDSSyncCommandSetFileExtension = @"synccmd";
NSString * const TICDSSyncChangeSetFileExtension = @"syncchg";
NSString * const TICDSRecentSyncFileExtension = @"recentsync";

NSString * const TICDSSyncIDAttributeName = @"ticdsSyncID";
NSString * const TICDSSyncChangeDataModelName = @"TICDSSyncChange";
NSString * const TICDSSyncChangeSetDataModelName = @"TICDSSyncChangeSet";

NSString * const TICDSApplicationSyncManagerDidRegisterSuccessfullyNotification = @"TICDSApplicationSyncManagerDidRegisterSuccessfullyNotification";
NSString * const TICDSDocumentSyncManagerDidRegisterSuccessfullyNotification = @"TICDSDocumentSyncManagerDidRegisterSuccessfullyNotification";