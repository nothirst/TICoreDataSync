//
//  TICDSyncChange.m
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSSyncChange ()

#ifdef DEBUG
@property NSString *fetchingThreadName;
#endif

@end


@implementation TICDSSyncChange


#pragma mark - Overridden KVO methods to provide thread access checks methods

#ifdef DEBUG

@synthesize fetchingThreadName = _fetchingThreadName;

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    self.fetchingThreadName = [[NSThread currentThread] name];
}

- (void)willChangeValueForKey:(NSString *)key
{
    NSAssert([self.fetchingThreadName isEqualToString:[[NSThread currentThread] name]], @"This object is being accessed from a different thread/queue from where it was originally fetched.");
    [super willChangeValueForKey:key];
}

- (void)didChangeValueForKey:(NSString *)key
{
    NSAssert([self.fetchingThreadName isEqualToString:[[NSThread currentThread] name]], @"This object is being accessed from a different thread/queue from where it was originally fetched.");
    [super didChangeValueForKey:key];
}

- (void)willChange:(NSKeyValueChange)changeKind valuesAtIndexes:(NSIndexSet *)indexes forKey:(NSString *)key
{
    NSAssert([self.fetchingThreadName isEqualToString:[[NSThread currentThread] name]], @"This object is being accessed from a different thread/queue from where it was originally fetched.");
    [super willChange:changeKind valuesAtIndexes:indexes forKey:key];
}

- (void)didChange:(NSKeyValueChange)changeKind valuesAtIndexes:(NSIndexSet *)indexes forKey:(NSString *)key
{
    NSAssert([self.fetchingThreadName isEqualToString:[[NSThread currentThread] name]], @"This object is being accessed from a different thread/queue from where it was originally fetched.");
    [super didChange:changeKind valuesAtIndexes:indexes forKey:key];
}

- (void)willChangeValueForKey:(NSString *)key withSetMutation:(NSKeyValueSetMutationKind)mutationKind usingObjects:(NSSet *)objects
{
    NSAssert([self.fetchingThreadName isEqualToString:[[NSThread currentThread] name]], @"This object is being accessed from a different thread/queue from where it was originally fetched.");
    [super willChangeValueForKey:key withSetMutation:mutationKind usingObjects:objects];
}

- (void)didChangeValueForKey:(NSString *)key withSetMutation:(NSKeyValueSetMutationKind)mutationKind usingObjects:(NSSet *)objects
{
    NSAssert([self.fetchingThreadName isEqualToString:[[NSThread currentThread] name]], @"This object is being accessed from a different thread/queue from where it was originally fetched.");
    [super didChangeValueForKey:key withSetMutation:mutationKind usingObjects:objects];
}

#endif

#pragma mark - Helper Methods
+ (id)syncChangeOfType:(TICDSSyncChangeType)aType inManagedObjectContext:(NSManagedObjectContext *)aMoc
{
    TICDSSyncChange *syncChange = [self ti_objectInManagedObjectContext:aMoc];
    
    [syncChange setLocalTimeStamp:[NSDate date]];
    [syncChange setChangeType:[NSNumber numberWithInt:aType]];
    
    return syncChange;
}

#pragma mark - Inspection
- (NSString *)shortDescription
{
    return [NSString stringWithFormat:@"%@ %@", TICDSSyncChangeTypeNames[ [[self changeType] unsignedIntValue] ], [self objectEntityName]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"\n%@\nCHANGED ATTRIBUTES\n%@\nCHANGED RELATIONSHIPS\n%@", [super description], [self changedAttributes], [self changedRelationships]];
}

#pragma mark - TIManagedObjectExtensions
+ (NSString *)ti_entityName
{
    return NSStringFromClass([self class]);
}

@dynamic changeType;
@synthesize relevantManagedObject = _relevantManagedObject;
@dynamic objectEntityName;
@dynamic objectSyncID;
@dynamic changedAttributes;
@dynamic changedRelationships;
@dynamic relevantKey;
@dynamic localTimeStamp;
@dynamic relatedObjectEntityName;

@end
