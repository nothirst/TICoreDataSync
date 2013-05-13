//
//  TICDSChangeIntegrityStoreManager.h
//  MoneyWell
//
//  Created by Michael Fey on 10/14/11.
//  Copyright (c) 2011 No Thirst Software. All rights reserved.
//

@interface TICDSChangeIntegrityStoreManager : NSObject {
    NSMutableSet *_deletionSet;
    NSMutableDictionary *_changeDictionary;
}

+ (TICDSChangeIntegrityStoreManager *)sharedChangeIntegrityStoreManager;

#pragma mark - Deletion Integrity methods

+ (BOOL)containsDeletionRecordForSyncID:(NSString *)ticdsSyncID;
+ (void)addSyncIDToDeletionIntegrityStore:(NSString *)ticdsSyncID;
+ (void)removeSyncIDFromDeletionIntegrityStore:(NSString *)ticdsSyncID;

#pragma mark - Insertion Integrity methods

+ (BOOL)containsInsertionRecordForSyncID:(NSString *)ticdsSyncID;
+ (void)addSyncIDToInsertionIntegrityStore:(NSString *)ticdsSyncID;
+ (void)removeSyncIDFromInsertionIntegrityStore:(NSString *)ticdsSyncID;

#pragma mark - Change Integrity methods

+ (BOOL)containsChangedAttributeRecordForKey:(id)key withValue:(id)value syncID:(NSString *)ticdsSyncID;
+ (void)addChangedAttributeValue:(id)value forKey:(id)key toChangeIntegrityStoreForSyncID:(NSString *)ticdsSyncID;
+ (void)removeChangedAttributesEntryFromChangeIntegrityStoreForSyncID:(NSString *)ticdsSyncID;

#pragma mark - Undo Integrity methods

+ (void)storeTICDSSyncID:(NSString *)ticdsSyncID forManagedObjectID:(NSManagedObjectID *)managedObjectID;
+ (NSString *)ticdsSyncIDForManagedObjectID:(NSManagedObjectID *)managedObjectID;

@end
