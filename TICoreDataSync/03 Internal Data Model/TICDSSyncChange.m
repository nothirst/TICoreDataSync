//
//  TICDSyncChange.m
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@implementation TICDSSyncChange

#pragma mark -
#pragma mark Helper Methods
+ (id)syncChangeOfType:(TICDSSyncChangeType)aType inManagedObjectContext:(NSManagedObjectContext *)aMoc
{
    TICDSSyncChange *syncChange = [self ti_objectInManagedObjectContext:aMoc];
    
    [syncChange setLocalTimeStamp:[NSDate date]];
    [syncChange setChangeType:[NSNumber numberWithInt:aType]];
    
    return syncChange;
}

#pragma mark -
#pragma mark Inspection
- (NSString *)shortDescription
{
    return [NSString stringWithFormat:@"%@ %@", TICDSSyncChangeTypeNames[ [[self changeType] unsignedIntValue] ], [self objectEntityName]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"\n%@\nCHANGED VALUES\n%@", [super description], [self changedValue]];
}

#pragma mark -
#pragma mark TIManagedObjectExtensions
+ (NSString *)ti_entityName
{
    return @"TICDSSyncChange";
}

@dynamic changeType;
@synthesize relevantManagedObject = _relevantManagedObject;
@dynamic objectEntityName;
@dynamic objectSyncID;
@dynamic changedValue;
@dynamic relatedObjectSyncID;
@dynamic relevantKey;
@dynamic localTimeStamp;
@dynamic relatedObjectEntityName;

@end
