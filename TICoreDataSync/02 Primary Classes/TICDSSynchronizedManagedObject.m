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
- (void)createSyncChangeIfApplicableForRelationship:(NSRelationshipDescription *)aRelationship;
- (NSDictionary *)dictionaryOfAllAttributes;

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
        [self createSyncChangeIfApplicableForRelationship:[objectRelationshipsByName valueForKey:eachRelationshipName]];
    }
}

- (void)createSyncChangeIfApplicableForRelationship:(NSRelationshipDescription *)aRelationship
{
    NSRelationshipDescription *inverseRelationship = [aRelationship inverseRelationship];
    
    // Check if this is a many-to-one relationship (only sync the -to-one side)
    if( ([aRelationship isToMany]) && (![inverseRelationship isToMany]) ) {
        return;
    }
    
    // Check if this is a many to many relationship, and only sync the first relationship name alphabetically
    if( ([aRelationship isToMany]) && ([inverseRelationship isToMany]) && ([[aRelationship name] caseInsensitiveCompare:[inverseRelationship name]] == NSOrderedDescending) ) {
        return;
    }
    
    // Check if this is a one to one relationship, and only sync the first relationship name alphabetically
    if( (![aRelationship isToMany]) && (![inverseRelationship isToMany]) && ([[aRelationship name] caseInsensitiveCompare:[inverseRelationship name]] == NSOrderedDescending) ) {
        return;
    }
    
    // If we get here, this is:
    // a) a one-to-many relationship
    // b) the alphabetical lowest end of a many-to-many relationship
    // c) the alphabetical lowest end of a one-to-one relationship
    // d) edge-case 1: a self-referential many-to-many relationship (will currently create 2 sync changes)
    // e) edge-case 2: a self-referential one-to-one relationship (will currently create 2 sync changes)
    
    TICDSSyncChange *syncChange = [self createSyncChangeForChangeType:TICDSSyncChangeTypeRelationshipChanged];
    
    [syncChange setRelatedObjectEntityName:[[aRelationship destinationEntity] name]];
    
    if( [aRelationship isToMany] ) {
        NSSet *relatedObjects = [self valueForKey:[aRelationship name]];
        
        NSMutableArray *relatedObjectSyncIDs = [NSMutableArray arrayWithCapacity:[relatedObjects count]];
        
        for( TICDSSynchronizedManagedObject *eachRelatedObject in relatedObjects ) {
            // Check that the related object should be synchronized
            if( ![eachRelatedObject isKindOfClass:[TICDSSynchronizedManagedObject class]] ) {
                continue;
            }
            [relatedObjectSyncIDs addObject:[eachRelatedObject valueForKey:TICDSSyncIDAttributeName]];
        }
        
        [syncChange setChangedRelationships:relatedObjectSyncIDs];
    } else {
        NSManagedObject *relatedObject = [self valueForKey:[aRelationship name]];
        
        // Check that the related object should be synchronized
        if( [relatedObject isKindOfClass:[TICDSSynchronizedManagedObject class]] ) {
            [syncChange setChangedRelationships:[relatedObject valueForKey:TICDSSyncIDAttributeName]];
        }
    }
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
    // changedAttributes = a dictionary containing the values of _all_ the object's attributes at time it was saved
    // this method also creates extra sync changes for _all_ the object's relationships 
    
    TICDSSyncChange *syncChange = [self createSyncChangeForChangeType:TICDSSyncChangeTypeObjectInserted];
    
    [syncChange setChangedAttributes:[self dictionaryOfAllAttributes]];
    [self createSyncChangesForAllRelationships];
}

- (void)createSyncChangeForDeletion
{
    // nothing is stored in changedAttributes or changedRelationships at this time
    // if a conflict is encountered, the deletion will have to take precedent, resurrection is not possible
    [self createSyncChangeForChangeType:TICDSSyncChangeTypeObjectDeleted];
}

- (void)createSyncChangesForChangedProperties
{
    // separate sync changes are created for each property change, whether it be relationship or 
    NSDictionary *changedValues = [self changedValues];
    
    for( NSString *eachPropertyName in changedValues ) {
        id eachValue = [changedValues valueForKey:eachPropertyName];
        
        NSRelationshipDescription *relationship = [[[self entity] relationshipsByName] valueForKey:eachPropertyName];
        if( relationship ) {
            [self createSyncChangeIfApplicableForRelationship:relationship];
        } else {
            TICDSSyncChange *syncChange = [self createSyncChangeForChangeType:TICDSSyncChangeTypeAttributeChanged];
            [syncChange setRelevantKey:eachPropertyName];
            [syncChange setChangedAttributes:eachValue];
        }
    }
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
