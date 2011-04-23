//
//  TICDSyncChange.m
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@implementation TICDSyncChange

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@", TICDSSyncChangeTypeNames[ [[self changeType] unsignedIntValue] ], [self objectEntityName]];
}

@dynamic objectSyncID;
@dynamic changedValue;
@dynamic relatedObjectSyncID;
@dynamic relevantKey;
@dynamic localTimeStamp;
@dynamic relatedObjectEntityName;
@dynamic objectEntityName;
@dynamic changeType;

@end
