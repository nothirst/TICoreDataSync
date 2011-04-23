//
//  TICDSTypesAndEnums.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSTypesAndEnums.h"


NSString * const TICDSErrorUserInfoKey = @"TICDSErrorUserInfoKey";
NSString * const TICDSErrorUnderlyingErrorKey = @"TICDSErrorUnderlyingErrorKey";
NSString * const TICDSErrorClassAndMethod = @"TICDSErrorClassAndMethod";
NSString * const TICDSErrorDomain = @"com.timisted.ticoredatasync";

NSString * const kTICDSClientDeviceDescription = @"kTICDSClientDeviceDescription";
NSString * const kTICDSClientDeviceUserInfo = @"kTICDSClientDeviceUserInfo";
NSString * const kTICDSLastSyncDate = @"kTICDSLastSyncDate";
NSString * const kTICDSDocumentIdentifier = @"kTICDSDocumentIdentifier";
NSString * const kTICDSDocumentName = @"kTICDSDocumentName";
NSString * const kTICDSDocumentUserInfo = @"kTICDSDocumentUserInfo";
NSString * const kTICDSOriginalDeviceDescription = @"kTICDSOriginalDeviceDescription";
NSString * const kTICDSOriginalDeviceIdentifier = @"kTICDSOriginalDeviceIdentifier";

NSString * const kTICDSUtilitiesFileStructureClientDeviceUID = @"kTICDSUtilitiesFileStructureClientDeviceUID";
NSString * const kTICDSUtilitiesFileStructureDocumentUID = @"kTICDSUtilitiesFileStructureDocumentUID";

NSString * const TICDSClientDevicesDirectoryName = @"ClientDevices";
NSString * const TICDSDocumentsDirectoryName = @"Documents";
NSString * const TICDSSyncChangesDirectoryName = @"SyncChanges";
NSString * const TICDSUnappliedChangesDirectoryName = @"UnappliedSyncChanges";
NSString * const TICDSSyncChangesToPushDirectoryName = @"SyncChangesToPush";

NSString * const TICDSApplicationSyncManagerDidRegisterSuccessfullyNotification = @"TICDSApplicationSyncManagerDidRegisterSuccessfullyNotification";
NSString * const TICDSDocumentSyncManagerDidRegisterSuccessfullyNotification = @"TICDSDocumentSyncManagerDidRegisterSuccessfullyNotification";