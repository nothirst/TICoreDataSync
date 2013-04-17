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

+ (BOOL)containsDeletionRecordForSyncID:(NSString *)ticdsSyncID;
+ (BOOL)containsInsertionRecordForSyncID:(NSString *)ticdsSyncID;

+ (void)addSyncIDToDeletionIntegrityStore:(NSString *)ticdsSyncID;
+ (void)removeSyncIDFromDeletionIntegrityStore:(NSString *)ticdsSyncID;

+ (void)addSyncIDToInsertionIntegrityStore:(NSString *)ticdsSyncID;
+ (void)removeSyncIDFromInsertionIntegrityStore:(NSString *)ticdsSyncID;

+ (void)addChangedProperties:(NSDictionary *)changedProperties toChangeIntegrityStoreForSyncID:(NSString *)ticdsSyncID;
+ (void)removeChangedProperties:(NSDictionary *)changedProperties fromChangeIntegrityStoreForSyncID:(NSString *)ticdsSyncID;

+ (void)storeTICDSSyncID:(NSString *)ticdsSyncID forManagedObjectID:(NSManagedObjectID *)managedObjectID;
+ (NSString *)ticdsSyncIDForManagedObjectID:(NSManagedObjectID *)managedObjectID;

@end
