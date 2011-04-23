//
//  TICDSSynchronizedManagedObject.m
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSSynchronizedManagedObject ()

- (TICDSSyncChange *)createSyncChangeForChangeType:(TICDSSyncChangeType)aType;
- (void)createSyncChangesForAllRelationships;
- (void)createSyncChangeForRelationship:(NSRelationshipDescription *)aRelationship;

@end

@implementation TICDSSynchronizedManagedObject

#pragma mark -
#pragma mark Sync Change Creation
- (TICDSSyncChange *)createSyncChangeForChangeType:(TICDSSyncChangeType)aType
{
    TICDSSyncChange *syncChange = [TICDSSyncChange syncChangeOfType:aType inManagedObjectContext:[self syncChangesMOC]];
    
    [syncChange setObjectSyncID:[self valueForKey:TICDSSyncIDAttributeName]];
    [syncChange setObjectEntityName:[[self entity] name]];
    [syncChange setLocalTimeStamp:[NSDate date]];
    [syncChange setRelevantManagedObject:self];
    
    return syncChange;
}

- (void)createSyncChangesForAllRelationships
{
    NSDictionary *objectRelationshipsByName = [[self entity] relationshipsByName];
    
    for( NSString *eachRelationshipName in objectRelationshipsByName ) {
        NSRelationshipDescription *relationship = [objectRelationshipsByName valueForKey:eachRelationshipName];
        NSRelationshipDescription *inverseRelationship = [relationship inverseRelationship];
        
        // Check if this is a many-to-one relationship (only sync the -to-one side)
        if( ([relationship isToMany]) && (![inverseRelationship isToMany]) ) {
            continue;
        }
        
        // Check if this is a many to many relationship, and only sync the first relationship name alphabetically
        if( ([relationship isToMany]) && ([inverseRelationship isToMany]) && ([[relationship name] caseInsensitiveCompare:[inverseRelationship name]] == NSOrderedDescending) ) {
            continue;
        }
        
        // Check if this is a one to one relationship, and only sync the first relationship name alphabetically
        if( (![relationship isToMany]) && (![inverseRelationship isToMany]) && ([[relationship name] caseInsensitiveCompare:[inverseRelationship name]] == NSOrderedDescending) ) {
            continue;
        }
        
        // If we get here, this is:
        // a) a one-to-many relationship
        // b) the alphabetical lowest end of a many-to-many relationship
        // c) the alphabetical lowest end of a one-to-one relationship
        
        [self createSyncChangeForRelationship:relationship];
    }
}

- (void)createSyncChangeForRelationship:(NSRelationshipDescription *)aRelationship
{
    
}

#pragma mark -
#pragma mark Dictionaries
- (NSDictionary *)dictionaryOfAllAttributes
{
    NSDictionary *objectAttributeNames = [[self entity] attributesByName];
    
    NSMutableDictionary *attributeValues = [NSMutableDictionary dictionaryWithCapacity:[objectAttributeNames count]];
    for( NSString *eachAttributeName in [objectAttributeNames allKeys] ) {
        [attributeValues setValue:[self valueForKey:eachAttributeName] forKey:eachAttributeName];
    }
    
    return attributeValues;
}

#pragma mark -
#pragma mark Sync Change Creation
- (void)createSyncChangeForInsertion
{
    TICDSSyncChange *syncChange = [self createSyncChangeForChangeType:TICDSSyncChangeTypeObjectInserted];
    
    [syncChange setChangedValue:[self dictionaryOfAllAttributes]];
}

- (void)createSyncChangeForDeletion
{
    
}

- (void)createSyncChangesForChangedProperties
{
    
}

#pragma mark -
#pragma mark Save Notification
- (void)willSave
{
    [super willSave];
    
    // if not in a synchronized MOC, or we don't have a doc sync manager, exit now
    if( ![[self managedObjectContext] isKindOfClass:[TICDSSynchronizedManagedObjectContext class]] || ![(TICDSSynchronizedManagedObjectContext *)[self managedObjectContext] documentSyncManager] ) {
        return;
    }
    
    if( [self isInserted] ) {
        [self createSyncChangeForInsertion];
    }
    
    if( [self isDeleted] ) {
        [self createSyncChangeForDeletion];
    }
    
    if( [self isUpdated] ) {
        [self createSyncChangesForChangedProperties];
    }
}

#pragma mark -
#pragma mark Managed Object Lifecycle
- (void)awakeFromInsert
{
    [super awakeFromInsert];
    
    [self setValue:[TICDSUtilities uuidString] forKey:TICDSSyncIDAttributeName];
}

#pragma mark -
#pragma mark Properties
- (NSManagedObjectContext *)syncChangesMOC
{
    if( ![[self managedObjectContext] isKindOfClass:[TICDSSynchronizedManagedObjectContext class]] ) return nil;
    
    return [[(TICDSSynchronizedManagedObjectContext *)[self managedObjectContext] documentSyncManager] syncChangesMOC];
}

@end
