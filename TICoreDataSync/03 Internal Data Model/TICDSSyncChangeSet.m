//
//  TICDSSyncChangeSet.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"
#import "TIManagedObjectExtensions.h"

@interface TICDSSyncChangeSet ()

#ifdef DEBUG
@property NSString *fetchingThreadName;
#endif

@end

@implementation TICDSSyncChangeSet

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
+ (BOOL)hasSyncChangeSetWithIdentifer:(NSString *)anIdentifier alreadyBeenAppliedInManagedObjectContext:(NSManagedObjectContext *)aMoc
{
    return [self changeSetWithIdentifier:anIdentifier inManagedObjectContext:aMoc] != nil;
}

+ (TICDSSyncChangeSet *)changeSetWithIdentifier:(NSString *)anIdentifier inManagedObjectContext:(NSManagedObjectContext *)aMoc
{
    NSError *anyError = nil;
    TICDSSyncChangeSet *matchingChangeSet = [self ti_firstObjectInManagedObjectContext:aMoc error:&anyError matchingPredicateWithFormat:@"syncChangeSetIdentifier == %@", anIdentifier];
    
    if( anyError ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching a change set: %@", anyError);
    }
    
    return matchingChangeSet;
}

#pragma mark - Initialization and Deallocation
+ (id)syncChangeSetWithIdentifier:(NSString *)anIdentifier fromClient:(NSString *)aClientIdentifier creationDate:(NSDate *)aDate inManagedObjectContext:(NSManagedObjectContext *)aMoc
{
    TICDSSyncChangeSet *changeSet = [self ti_objectInManagedObjectContext:aMoc];
    [changeSet setCreationDate:aDate];
    [changeSet setSyncChangeSetIdentifier:anIdentifier];
    [changeSet setFileName:[anIdentifier stringByAppendingPathExtension:TICDSSyncChangeSetFileExtension]];
    [changeSet setClientIdentifier:aClientIdentifier];
    return changeSet;
}

#pragma mark - TIManagedObjectExtensions
+ (NSString *)ti_entityName
{
    return @"TICDSyncChangeSet";
}

#pragma mark - Properties
@dynamic creationDate;
@dynamic fileName;
@dynamic syncChangeSetIdentifier;
@dynamic localDateOfApplication;
@dynamic clientIdentifier;

@end
