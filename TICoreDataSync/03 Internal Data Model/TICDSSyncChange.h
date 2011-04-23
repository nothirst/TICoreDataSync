//
//  TICDSyncChange.h
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TICDSTypesAndEnums.h"

@interface TICDSSyncChange : NSManagedObject {
@private
    NSManagedObject *_relevantManagedObject;
}

+ (id)syncChangeOfType:(TICDSSyncChangeType)aType inManagedObjectContext:(NSManagedObjectContext *)aMoc;

@property (nonatomic, retain) NSNumber * changeType;
@property (nonatomic, assign) NSManagedObject *relevantManagedObject;
@property (nonatomic, retain) NSString * objectEntityName;
@property (nonatomic, retain) NSString * objectSyncID;
@property (nonatomic, retain) NSString * relevantKey;
@property (nonatomic, retain) id changedValue;
@property (nonatomic, retain) id changedRelationships;
@property (nonatomic, retain) NSString * relatedObjectEntityName;
@property (nonatomic, retain) NSString * relatedObjectSyncID;
@property (nonatomic, retain) NSDate * localTimeStamp;

@end
