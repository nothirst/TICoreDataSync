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

#pragma mark - Public methods

+ (BOOL)containsDeletionRecordForSyncID:(NSString *)ticdsSyncID
{
    BOOL containsDeletionRecord = NO;
    @synchronized(deletionStoreLock) {
        containsDeletionRecord = [[[self sharedChangeIntegrityStoreManager] deletionSet] containsObject:ticdsSyncID];
    }
    
    return containsDeletionRecord;
}

+ (BOOL)containsInsertionRecordForSyncID:(NSString *)ticdsSyncID;
{
    BOOL containsInsertionRecord = NO;
    @synchronized(insertionStoreLock) {
        containsInsertionRecord = [[[self sharedChangeIntegrityStoreManager] insertionSet] containsObject:ticdsSyncID];
    }
    
    return containsInsertionRecord;
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

+ (void)addChangedProperties:(NSDictionary *)changedProperties toChangeIntegrityStoreForSyncID:(NSString *)ticdsSyncID
{
//    @synchronized(changeStoreLock) {
//        NSMutableDictionary *previouslyChangedProperties = [[[self sharedChangeIntegrityStoreManager] changeDictionary] objectForKey:ticdsSyncID];
//        if (previouslyChangedProperties == nil) {
//            previouslyChangedProperties = [NSMutableDictionary dictionaryWithDictionary:changedProperties];
//        } else {
//            NSArray *keys = [previouslyChangedProperties allKeys];
//            
//        }
//        
//        [[[self sharedChangeIntegrityStoreManager] changeDictionary] setObject:previouslyChangedProperties forKey:ticdsSyncID];
//    }
}

+ (void)removeChangedProperties:(NSDictionary *)changedProperties fromChangeIntegrityStoreForSyncID:(NSString *)ticdsSyncID
{
//    @synchronized(changeStoreLock) {
//        
//    }
}

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
