//
//  TICDSChangeIntegrityStoreManager.m
//  MoneyWell
//
//  Created by Michael Fey on 10/14/11.
//  Copyright (c) 2011 No Thirst Software. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSChangeIntegrityStoreManager ()

@property (nonatomic, strong) NSMutableSet *deletionSet;
@property (nonatomic, strong) NSMutableSet *insertionSet;
@property (nonatomic, strong) NSMutableDictionary *changeDictionary;
@property (nonatomic, strong) NSMutableDictionary *ticdsSyncIDDictionary;

@end

@implementation TICDSChangeIntegrityStoreManager

static NSLock *deletionStoreLock = nil;
static NSLock *insertionStoreLock = nil;
static NSLock *changeStoreLock = nil;

@synthesize deletionSet = _deletionSet;
@synthesize changeDictionary = _changeDictionary;

#pragma mark - Deletion Integrity methods

+ (BOOL)containsDeletionRecordForSyncID:(NSString *)ticdsSyncID
{
    BOOL containsDeletionRecord = NO;
    @synchronized(deletionStoreLock) {
        containsDeletionRecord = [[[self sharedChangeIntegrityStoreManager] deletionSet] containsObject:ticdsSyncID];
    }

    return containsDeletionRecord;
}

+ (void)addSyncIDToDeletionIntegrityStore:(NSString *)ticdsSyncID
{
    @synchronized(deletionStoreLock) {
        [[[self sharedChangeIntegrityStoreManager] deletionSet] addObject:ticdsSyncID];
    }
}

+ (void)removeSyncIDFromDeletionIntegrityStore:(NSString *)ticdsSyncID
{
    @synchronized(deletionStoreLock) {
        [[[self sharedChangeIntegrityStoreManager] deletionSet] removeObject:ticdsSyncID];
    }
}

#pragma mark - Insertion Integrity methods

+ (BOOL)containsInsertionRecordForSyncID:(NSString *)ticdsSyncID;
{
    BOOL containsInsertionRecord = NO;
    @synchronized(insertionStoreLock) {
        containsInsertionRecord = [[[self sharedChangeIntegrityStoreManager] insertionSet] containsObject:ticdsSyncID];
    }

    return containsInsertionRecord;
}

+ (void)addSyncIDToInsertionIntegrityStore:(NSString *)ticdsSyncID
{
    @synchronized(insertionStoreLock) {
        [[[self sharedChangeIntegrityStoreManager] insertionSet] addObject:ticdsSyncID];
    }
}

+ (void)removeSyncIDFromInsertionIntegrityStore:(NSString *)ticdsSyncID
{
    @synchronized(insertionStoreLock) {
        [[[self sharedChangeIntegrityStoreManager] insertionSet] removeObject:ticdsSyncID];
    }
}

#pragma mark - Change Integrity methods

+ (BOOL)containsChangedAttributeRecordForKey:(id)key withValue:(id)value syncID:(NSString *)ticdsSyncID
{
    @synchronized(changeStoreLock) {
        NSDictionary *storedAttributes = [[[self sharedChangeIntegrityStoreManager] changeDictionary] objectForKey:ticdsSyncID];
        if (storedAttributes == nil) {
            return NO;
        }

        id storedValue = [storedAttributes objectForKey:key];
        if (storedValue == nil) {
            return NO;
        }

        return [storedValue isEqual:value];
    }
}

+ (void)addChangedAttributeValue:(id)value forKey:(id)key toChangeIntegrityStoreForSyncID:(NSString *)ticdsSyncID
{
    if (key == nil) {
        return;
    }
    
    @synchronized(changeStoreLock) {
        NSMutableDictionary *storedAttributes = [[[self sharedChangeIntegrityStoreManager] changeDictionary] objectForKey:ticdsSyncID];
        if (storedAttributes == nil) {
            storedAttributes = [NSMutableDictionary dictionary];
        }

        if (value == nil) {
            [storedAttributes removeObjectForKey:key];
        } else {
            [storedAttributes setObject:value forKey:key];
        }

        [[[self sharedChangeIntegrityStoreManager] changeDictionary] setObject:storedAttributes forKey:ticdsSyncID];
    }
}

+ (void)removeChangedAttributesEntryFromChangeIntegrityStoreForSyncID:(NSString *)ticdsSyncID
{
    @synchronized(changeStoreLock) {
        [[[self sharedChangeIntegrityStoreManager] changeDictionary] removeObjectForKey:ticdsSyncID];
    }
}

#pragma mark - Undo Integrity methods

+ (void)storeTICDSSyncID:(NSString *)ticdsSyncID forManagedObjectID:(NSManagedObjectID *)managedObjectID
{
    if ([ticdsSyncID length] == 0) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Attempted to store a 0 length ticdsSyncID for managedObject with ID %@", managedObjectID);
        return;
    }
    
    [[[self sharedChangeIntegrityStoreManager] ticdsSyncIDDictionary] setObject:ticdsSyncID forKey:managedObjectID];
}

+ (NSString *)ticdsSyncIDForManagedObjectID:(NSManagedObjectID *)managedObjectID
{
    NSString *syncID = [[[self sharedChangeIntegrityStoreManager] ticdsSyncIDDictionary] objectForKey:managedObjectID];
    if ([syncID length] == 0) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Retrieved a 0 length ticdsSyncID for managedObject with ID %@", managedObjectID);
    }
    
    return syncID;
}

#pragma mark - Overridden getters/setters

- (NSMutableSet *)deletionSet
{
    if (_deletionSet == nil) {
        _deletionSet = [[NSMutableSet alloc] init];
    }
    
    return _deletionSet;
}

- (NSMutableSet *)insertionSet
{
    if (_insertionSet == nil) {
        _insertionSet = [[NSMutableSet alloc] init];
    }
    
    return _insertionSet;
}

- (NSMutableDictionary *)changeDictionary
{
    if (_changeDictionary == nil) {
        _changeDictionary = [[NSMutableDictionary alloc] init];
    }
    
    return _changeDictionary;
}

- (NSMutableDictionary *)ticdsSyncIDDictionary
{
    if (_ticdsSyncIDDictionary == nil) {
        _ticdsSyncIDDictionary = [[NSMutableDictionary alloc] init];
    }
    
    return _ticdsSyncIDDictionary;
}

#pragma mark - Singleton methods

static TICDSChangeIntegrityStoreManager *sharedChangeIntegrityStoreManager = nil;

+ (void)initialize
{
    deletionStoreLock = [[NSLock alloc] init];
    insertionStoreLock = [[NSLock alloc] init];
    changeStoreLock = [[NSLock alloc] init];
}

+ (TICDSChangeIntegrityStoreManager *)sharedChangeIntegrityStoreManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedChangeIntegrityStoreManager = [[self alloc] init];
    });

	return sharedChangeIntegrityStoreManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self)
	{
		if (sharedChangeIntegrityStoreManager == nil) {
			sharedChangeIntegrityStoreManager = [super allocWithZone:zone];
			return sharedChangeIntegrityStoreManager;
		}
	}

	return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

#pragma mark -

@end
