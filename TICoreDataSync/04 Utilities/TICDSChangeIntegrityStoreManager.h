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

+ (BOOL)containsDeletionRecordForObjectID:(NSManagedObjectID *)objectID;
+ (BOOL)containsInsertionRecordForObjectID:(NSManagedObjectID *)objectID;

+ (void)addObjectIDToDeletionIntegrityStore:(NSManagedObjectID *)objectID;
+ (void)removeObjectIDFromDeletionIntegrityStore:(NSManagedObjectID *)objectID;

+ (void)addObjectIDToInsertionIntegrityStore:(NSManagedObjectID *)objectID;
+ (void)removeObjectIDFromInsertionIntegrityStore:(NSManagedObjectID *)objectID;

+ (void)addChangedProperties:(NSDictionary *)changedProperties toChangeIntegrityStoreForObjectID:(NSManagedObjectID *)objectID;
+ (void)removeChangedProperties:(NSDictionary *)changedProperties fromChangeIntegrityStoreForObjectID:(NSManagedObjectID *)objectID;

+ (void)storeTICDSSyncID:(NSString *)ticdsSyncID forManagedObjectID:(NSManagedObjectID *)managedObjectID;
+ (NSString *)ticdsSyncIDForManagedObjectID:(NSManagedObjectID *)managedObjectID;

@end
