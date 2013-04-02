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
- (void)createToOneRelationshipSyncChange:(NSRelationshipDescription *)aRelationship;
- (void)createToManyRelationshipSyncChanges:(NSRelationshipDescription *)aRelationship;
- (NSDictionary *)dictionaryOfAllAttributes;

@end

@implementation TICDSSynchronizedManagedObject

#pragma mark - Primary Sync Change Creation

+ (NSSet *)keysForWhichSyncChangesWillNotBeCreated
{
    return nil;
}

- (void)createSyncChangeForInsertion
{
    // changedAttributes = a dictionary containing the values of _all_ the object's attributes at time it was saved
    // this method also creates extra sync changes for _all_ the object's relationships 
    
    if ([TICDSChangeIntegrityStoreManager containsInsertionRecordForObjectID:[self objectID]]) {
        [TICDSChangeIntegrityStoreManager removeObjectIDFromInsertionIntegrityStore:[self objectID]];
        return;
    }
    
    TICDSSyncChange *syncChange = [self createSyncChangeForChangeType:TICDSSyncChangeTypeObjectInserted];
    
    TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"[%@] %@", syncChange.objectSyncID, [self class]);
    
    [syncChange setChangedAttributes:[self dictionaryOfAllAttributes]];
    [self createSyncChangesForAllRelationships];
}

- (void)createSyncChangeForDeletion
{
    if ([TICDSChangeIntegrityStoreManager containsDeletionRecordForObjectID:[self objectID]]) {
        [TICDSChangeIntegrityStoreManager removeObjectIDFromDeletionIntegrityStore:[self objectID]];
        return;
    }

    // nothing is stored in changedAttributes or changedRelationships at this time
    // if a conflict is encountered, the deletion will have to take precedent, resurrection is not possible
    [self createSyncChangeForChangeType:TICDSSyncChangeTypeObjectDeleted];
}

- (void)createSyncChangesForChangedProperties
{
    // separate sync changes are created for each property change, whether it be relationship or attribute
    NSDictionary *changedValues = [self changedValues];
    
    NSSet *propertyNamesToBeIgnored = [[self class] keysForWhichSyncChangesWillNotBeCreated];
    for( NSString *eachPropertyName in changedValues ) {
        if (propertyNamesToBeIgnored != nil && [propertyNamesToBeIgnored containsObject:eachPropertyName]) {
            TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Not creating a change for %@.%@", [self class], eachPropertyName);
            continue;
        }
        
        id eachValue = [changedValues valueForKey:eachPropertyName];
        
        NSRelationshipDescription *relationship = [[[self entity] relationshipsByName] valueForKey:eachPropertyName];
        if( relationship ) {
            [self createSyncChangeIfApplicableForRelationship:relationship];
        } else {
            TICDSSyncChange *syncChange = [self createSyncChangeForChangeType:TICDSSyncChangeTypeAttributeChanged];
            TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"[%@] %@", syncChange.objectSyncID, [self class]);
            [syncChange setRelevantKey:eachPropertyName];
            [syncChange setChangedAttributes:eachValue];
        }
    }
}

#pragma mark - Sync Change Helper Methods

- (TICDSSyncChange *)createSyncChangeForChangeType:(TICDSSyncChangeType)aType
{
    TICDSSyncChange *syncChange = [TICDSSyncChange syncChangeOfType:aType inManagedObjectContext:[self syncChangesMOC]];
    
    TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"[%@] %@", syncChange.objectSyncID, [self class]);

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
    
    // Each check makes sure there _is_ an inverse relationship before checking its type, to allow for relationships with no inverse set
    
    // Check if this is a many-to-one relationship (only sync the -to-one side)
    if( ([aRelationship isToMany]) && inverseRelationship && (![inverseRelationship isToMany]) ) {
        return;
    }
    
    // Check if this is a many to many relationship, and only sync the first relationship name alphabetically
    if( ([aRelationship isToMany]) && inverseRelationship && ([inverseRelationship isToMany]) && ([[aRelationship name] caseInsensitiveCompare:[inverseRelationship name]] == NSOrderedDescending) ) {
        return;
    }
    
    // Check if this is a one to one relationship, and only sync the first relationship name alphabetically
    if( (![aRelationship isToMany]) && inverseRelationship && (![inverseRelationship isToMany]) && ([[aRelationship name] caseInsensitiveCompare:[inverseRelationship name]] == NSOrderedDescending) ) {
        return;
    }
    
    // Check if this is a self-referential relationship, and only sync one side, somehow!!!
    
    // If we get here, this is:
    // a) a one-to-many relationship
    // b) the alphabetically lower end of a many-to-many relationship
    // c) the alphabetically lower end of a one-to-one relationship
    // d) edge-case 1: a many-to-many relationship with the same relationship name at both ends (will currently create 2 sync changes)
    // e) edge-case 2: a one-to-one relationship with the same relationship name at both ends (will currently create 2 sync changes)
    
    if( ![aRelationship isToMany] ) {
        [self createToOneRelationshipSyncChange:aRelationship];
    } else {
        [self createToManyRelationshipSyncChanges:aRelationship];
    }
}

- (void)createToOneRelationshipSyncChange:(NSRelationshipDescription *)aRelationship
{
    TICDSSyncChange *syncChange = [self createSyncChangeForChangeType:TICDSSyncChangeTypeToOneRelationshipChanged];
    
    TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"[%@] %@", syncChange.objectSyncID, [self class]);

    [syncChange setRelatedObjectEntityName:[[aRelationship destinationEntity] name]];
    [syncChange setRelevantKey:[aRelationship name]];
    
    NSManagedObject *relatedObject = [self valueForKey:[aRelationship name]];
    
    // Check that the related object should be synchronized
    if( [relatedObject isKindOfClass:[TICDSSynchronizedManagedObject class]] ) {
        [syncChange setChangedRelationships:[relatedObject valueForKey:TICDSSyncIDAttributeName]];
    }
}

- (void)createToManyRelationshipSyncChanges:(NSRelationshipDescription *)aRelationship
{
    NSSet *relatedObjects = [self valueForKey:[aRelationship name]];
    NSDictionary *committedValues = [self committedValuesForKeys:[NSArray arrayWithObject:[aRelationship name]]];
    
    NSSet *previouslyRelatedObjects = [committedValues valueForKey:[aRelationship name]];
    
    NSMutableSet *addedObjects = [NSMutableSet setWithCapacity:5];
    for( NSManagedObject *eachObject in relatedObjects ) {
        if( ![previouslyRelatedObjects containsObject:eachObject] ) {
            [addedObjects addObject:eachObject];
        }
    }
    
    NSMutableSet *removedObjects = [NSMutableSet setWithCapacity:5];
    for( NSManagedObject *eachObject in previouslyRelatedObjects ) {
        if( ![relatedObjects containsObject:eachObject] ) {
            [removedObjects addObject:eachObject];
        }
    }
    
    TICDSSyncChange *eachChange = nil;
    
    for( NSManagedObject *eachObject in addedObjects ) {
        if( ![eachObject isKindOfClass:[TICDSSynchronizedManagedObject class]] ) {
            continue;
        }
        
        eachChange = [self createSyncChangeForChangeType:TICDSSyncChangeTypeToManyRelationshipChangedByAddingObject];
        
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"[%@] %@", eachChange.objectSyncID, [self class]);

        [eachChange setRelatedObjectEntityName:[[aRelationship destinationEntity] name]];
        [eachChange setRelevantKey:[aRelationship name]];
        [eachChange setChangedRelationships:[eachObject valueForKey:TICDSSyncIDAttributeName]];
    }
    
    for( NSManagedObject *eachObject in removedObjects ) {
        if( ![eachObject isKindOfClass:[TICDSSynchronizedManagedObject class]] ) {
            continue;
        }
        
        eachChange = [self createSyncChangeForChangeType:TICDSSyncChangeTypeToManyRelationshipChangedByRemovingObject];
        
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"[%@] %@", eachChange.objectSyncID, [self class]);

        [eachChange setRelatedObjectEntityName:[[aRelationship destinationEntity] name]];
        [eachChange setRelevantKey:[aRelationship name]];
        [eachChange setChangedRelationships:[eachObject valueForKey:TICDSSyncIDAttributeName]];
    }
}

#pragma mark - Dictionaries

- (NSDictionary *)dictionaryOfAllAttributes
{
    NSDictionary *objectAttributeNames = [[self entity] attributesByName];
    
    NSMutableDictionary *attributeValues = [NSMutableDictionary dictionaryWithCapacity:[objectAttributeNames count]];
    for( NSString *eachAttributeName in [objectAttributeNames allKeys] ) {
        [attributeValues setValue:[self valueForKey:eachAttributeName] forKey:eachAttributeName];
    }
    
    return attributeValues;
}

#pragma mark - Save Notification

- (void)willSave
{
    [super willSave];

    // if not in a synchronized MOC, or we don't have a doc sync manager, exit now
    if (self.managedObjectContext.isSynchronized == NO || self.managedObjectContext.documentSyncManager == nil) {
        if (self.managedObjectContext.isSynchronized == NO) {
            TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Skipping sync change creation for %@ because our managedObjectContext is not marked as synchronized.", [self class]);
        }

        if (self.managedObjectContext.documentSyncManager == nil) {
            TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Skipping sync change creation for %@ because our managedObjectContext has no documentSyncManager.", [self class]);
        }

        return;
    }

    if ( [self isInserted] ) {
        [self createSyncChangeForInsertion];
    }

    if ( [self isUpdated] ) {
        [self createSyncChangesForChangedProperties];
    }

    if ( [self isDeleted] ) {
        [self createSyncChangeForDeletion];
    }
}

#pragma mark - Managed Object Lifecycle

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    
    [self setValue:[TICDSUtilities uuidString] forKey:TICDSSyncIDAttributeName];
}

#pragma mark - Properties

- (NSManagedObjectContext *)syncChangesMOC
{
    TICDSDocumentSyncManager *documentSyncManager = self.managedObjectContext.documentSyncManager;
    if (documentSyncManager == nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Could not return a syncChangesMOC from %@ because our managedObjectContext has no documentSyncManager.", [self class]);
        return nil;
    }
    
    return [documentSyncManager syncChangesMocForDocumentMoc:self.managedObjectContext];
}

@end
