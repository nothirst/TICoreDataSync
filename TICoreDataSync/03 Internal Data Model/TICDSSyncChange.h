//
//  TICDSyncChange.h
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TICDSTypesAndEnums.h"

/** `TICDSSyncChange` objects are used to describe changes made to synchronized objects within a synchronized managed object. */

@interface TICDSSyncChange : NSManagedObject {
@private
    NSManagedObject *__weak _relevantManagedObject;
}

/** @name Class Factory Method */

/** Create a sync change of the specified type in the given managed object context.
 
 @param aType The type of the change (see `TICDSTypesAndEnums.h` for possible values).
 @param aMoc The managed object context in which to create the sync change.
 
 @return A suitably-configured `TICDSSyncChange` object for the given change.
 */
+ (id)syncChangeOfType:(TICDSSyncChangeType)aType inManagedObjectContext:(NSManagedObjectContext *)aMoc;

/** @name Persistent Properties */

/** The type of the change.
 
 See `TICDSTypesAndEnums.h` for the list of possible change types. */
@property (nonatomic, strong) NSNumber * changeType;

/** The name of the entity for this sync change. */
@property (nonatomic, copy) NSString * objectEntityName;

/** The sync ID (`ticdsSyncID` attribute) of the managed object to which this sync change refers. */
@property (nonatomic, copy) NSString * objectSyncID;

/** The relevant key that was changed if this is sync change represents an attribute change. */
@property (nonatomic, copy) NSString * relevantKey;

/** The changed values of the attributes (used for attribute change, and insertion). */
@property (nonatomic, strong) id changedAttributes;

/** The changed relationships for a relationship sync change. */
@property (nonatomic, strong) id changedRelationships;

/** The name of the related entity. */
@property (nonatomic, copy) NSString * relatedObjectEntityName;

/** The local timestamp of this change; note this is used only to sort sync changes when they are being applied. The last modification date of the entire sync change set determines the order in which change sets are applied. */
@property (nonatomic, strong) NSDate * localTimeStamp;

/** @name Non-Persisted Properties. */

/** The managed object instance to which this sync change refers. */
@property (nonatomic, weak) NSManagedObject *relevantManagedObject;

@end
