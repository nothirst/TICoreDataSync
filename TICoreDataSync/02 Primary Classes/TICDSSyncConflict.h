//
//  TICDSSyncConflict.h
//  ShoppingListMac
//
//  Created by Tim Isted on 29/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSClassesAndProtocols.h"
#import "TICDSTypesAndEnums.h"

/** A `TICDSSyncConflict` object describes a conflict found between changes made locally, and changes made by another client who has already posted their `SyncChange`s. */

@interface TICDSSyncConflict : NSObject {
@private
    TICDSSyncConflictType _conflictType;
    NSString *_entityName;
    NSString *_relevantKey;
    NSString *_objectSyncID;
    NSDictionary *_localInformation;
    NSDictionary *_remoteInformation;
}

/** @name Class Factory Method */
+ (TICDSSyncConflict *)syncConflictOfType:(TICDSSyncConflictType)aType forEntityName:(NSString *)anEntityName key:(NSString *)aKey objectSyncID:(NSString *)anObjectSyncID;

/** @name Properties */

/** The type of conflict. */
@property (assign) TICDSSyncConflictType conflictType;

/** A description of this type of conflict. */
@property (weak, readonly) NSString *conflictDescription;

/** The name of the entity for which conflicting changes were made to an object. */
@property (copy) NSString *entityName;

/** The name of the key for which a conflict exists. */
@property (copy) NSString *relevantKey;

/** The sync id (`ticdsSyncID` attribute) of the object for which the conflict was found. */
@property (copy) NSString *objectSyncID;

/** Information about the conflicting information on the local change. */
@property (strong) NSDictionary *localInformation;

/** Information about the conflicting information on the remote change. */
@property (strong) NSDictionary *remoteInformation;

@end
