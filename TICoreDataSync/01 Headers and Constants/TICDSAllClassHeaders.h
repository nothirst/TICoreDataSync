//
//  TICDSAllClassHeaders.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#pragma mark - Primary Classes
#import "TICDSApplicationSyncManager.h"
#import "TICDSDocumentSyncManager.h"
#import "TICDSSynchronizedManagedObject.h"
#import "TICDSSyncConflict.h"
#import "TICDSSynchronizationOperationManagedObjectContext.h"
#import "TICDSSyncTransaction.h"
#import "NSManagedObjectContext+TICDSAdditions.h"

#pragma mark Operations
#import "TICDSOperation.h"
#import "TICDSApplicationRegistrationOperation.h"
#import "TICDSDocumentRegistrationOperation.h"
#import "TICDSListOfPreviouslySynchronizedDocumentsOperation.h"
#import "TICDSWholeStoreUploadOperation.h"
#import "TICDSWholeStoreDownloadOperation.h"
#import "TICDSPreSynchronizationOperation.h"
#import "TICDSSynchronizationOperation.h"
#import "TICDSPostSynchronizationOperation.h"
#import "TICDSVacuumOperation.h"
#import "TICDSListOfDocumentRegisteredClientsOperation.h"
#import "TICDSListOfApplicationRegisteredClientsOperation.h"
#import "TICDSDocumentDeletionOperation.h"
#import "TICDSDocumentClientDeletionOperation.h"
#import "TICDSRemoveAllRemoteSyncDataOperation.h"

#pragma mark File Manager-Based
#import "TICDSFileManagerBasedApplicationSyncManager.h"
#import "TICDSFileManagerBasedDocumentSyncManager.h"
#import "TICDSFileManagerBasedApplicationRegistrationOperation.h"
#import "TICDSFileManagerBasedDocumentRegistrationOperation.h"
#import "TICDSFileManagerBasedListOfPreviouslySynchronizedDocumentsOperation.h"
#import "TICDSFileManagerBasedWholeStoreUploadOperation.h"
#import "TICDSFileManagerBasedWholeStoreDownloadOperation.h"
#import "TICDSFileManagerBasedPreSynchronizationOperation.h"
#import "TICDSFileManagerBasedPostSynchronizationOperation.h"
#import "TICDSFileManagerBasedVacuumOperation.h"
#import "TICDSFileManagerBasedListOfDocumentRegisteredClientsOperation.h"
#import "TICDSFileManagerBasedListOfApplicationRegisteredClientsOperation.h"
#import "TICDSFileManagerBasedDocumentDeletionOperation.h"
#import "TICDSFileManagerBasedDocumentClientDeletionOperation.h"
#import "TICDSFileManagerBasedRemoveAllRemoteSyncDataOperation.h"

#pragma mark DropboxSDK-Based
#import "TICDSDropboxSDKBasedApplicationSyncManager.h"
#import "TICDSDropboxSDKBasedDocumentSyncManager.h"
#import "TICDSDropboxSDKBasedApplicationRegistrationOperation.h"
#import "TICDSDropboxSDKBasedDocumentRegistrationOperation.h"
#import "TICDSDropboxSDKBasedListOfPreviouslySynchronizedDocumentsOperation.h"
#import "TICDSDropboxSDKBasedWholeStoreUploadOperation.h"
#import "TICDSDropboxSDKBasedWholeStoreDownloadOperation.h"
#import "TICDSDropboxSDKBasedPreSynchronizationOperation.h"
#import "TICDSDropboxSDKBasedPostSynchronizationOperation.h"
#import "TICDSDropboxSDKBasedVacuumOperation.h"
#import "TICDSDropboxSDKBasedListOfDocumentRegisteredClientsOperation.h"
#import "TICDSDropboxSDKBasedListOfApplicationRegisteredClientsOperation.h"
#import "TICDSDropboxSDKBasedDocumentDeletionOperation.h"
#import "TICDSDropboxSDKBasedDocumentClientDeletionOperation.h"
#import "TICDSDropboxSDKBasedRemoveAllRemoteSyncDataOperation.h"

#pragma mark - Internal Data Model
#import "TICDSSyncChange.h"
#import "TICDSSyncChangeSet.h"

#pragma mark - Utilities
#import "TICDSUtilities.h"
#import "TICDSLog.h"
#import "TICDSError.h"
#import "TICDSChangeIntegrityStoreManager.h"

#pragma mark Encryption
#import "FZACryptor.h"
#import "FZAKeyManager.h"
#if (TARGET_OS_IPHONE)
#import "FZAKeyManageriPhone.h"
#else
#import "FZAKeyManagerMac.h"
#endif

#pragma mark - External Sources
#import "NSObject+TIDelegateCommunications.h"
#import "TICoreDataFactory.h"
#import "TIManagedObjectExtensions.h"
#import "TIKQDirectoryWatcher.h"
#if (TARGET_OS_IPHONE)
#import "UIApplication+TICDSAdditions.h"
#endif

#pragma mark - Whole Store Compression
#import "SSZipArchive.h"