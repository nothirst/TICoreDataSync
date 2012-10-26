//
//  TICDSyncChange.m
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@implementation TICDSSyncChange

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
