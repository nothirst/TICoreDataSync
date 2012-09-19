//
//  TICDSChangeIntegrityStoreManager.m
//  MoneyWell
//
//  Created by Michael Fey on 10/14/11.
//  Copyright (c) 2011 No Thirst Software. All rights reserved.
//

#import "TICDSChangeIntegrityStoreManager.h"

@interface TICDSChangeIntegrityStoreManager ()

@property (nonatomic, retain) NSMutableSet *deletionSet;
@property (nonatomic, retain) NSMutableDictionary *changeDictionary;

@end

@implementation TICDSChangeIntegrityStoreManager

static NSLock *deletionStoreLock = nil;
static NSLock *changeStoreLock = nil;

@synthesize deletionSet = _deletionSet;
@synthesize changeDictionary = _changeDictionary;

#pragma mark -
#pragma mark Public methods

+ (BOOL)containsDeletionRecordForObjectID:(NSManagedObjectID *)objectID
{
    BOOL containsDeletionRecord = NO;
    @synchronized(deletionStoreLock) {
        containsDeletionRecord = [[[self sharedChangeIntegrityStoreManager] deletionSet] containsObject:objectID];
    }
    
    return containsDeletionRecord;
}

+ (void)addObjectIDToDeletionIntegrityStore:(NSManagedObjectID *)objectID
{
    @synchronized(deletionStoreLock) {
        [[[self sharedChangeIntegrityStoreManager] deletionSet] addObject:objectID];
    }
}

+ (void)removeObjectIDFromDeletionIntegrityStore:(NSManagedObjectID *)objectID
{
    @synchronized(deletionStoreLock) {
        [[[self sharedChangeIntegrityStoreManager] deletionSet] removeObject:objectID];
    }
}

+ (void)addChangedProperties:(NSDictionary *)changedProperties toChangeIntegrityStoreForObjectID:(NSManagedObjectID *)objectID
{
//    @synchronized(changeStoreLock) {
//        NSMutableDictionary *previouslyChangedProperties = [[[self sharedChangeIntegrityStoreManager] changeDictionary] objectForKey:objectID];
//        if (previouslyChangedProperties == nil) {
//            previouslyChangedProperties = [NSMutableDictionary dictionaryWithDictionary:changedProperties];
//        } else {
//            NSArray *keys = [previouslyChangedProperties allKeys];
//            
//        }
//        
//        [[[self sharedChangeIntegrityStoreManager] changeDictionary] setObject:previouslyChangedProperties forKey:objectID];
//    }
}

+ (void)removeChangedProperties:(NSDictionary *)changedProperties fromChangeIntegrityStoreForObjectID:(NSManagedObjectID *)objectID
{
//    @synchronized(changeStoreLock) {
//        
//    }
}

#pragma mark -
#pragma mark Overridden getters/setters

- (NSMutableSet *)deletionSet
{
    if (_deletionSet == nil) {
        _deletionSet = [[NSMutableSet alloc] init];
    }
    
    return _deletionSet;
}

- (NSMutableDictionary *)changeDictionary
{
    if (_changeDictionary == nil) {
        _changeDictionary = [[NSMutableDictionary alloc] init];
    }
    
    return _changeDictionary;
}

#pragma mark -
#pragma mark Singleton methods

static TICDSChangeIntegrityStoreManager *sharedChangeIntegrityStoreManager = nil;

+ (void)initialize
{
    deletionStoreLock = [[NSLock alloc] init];
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
