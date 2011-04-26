//
//  TICDSSyncChangeSet.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSSyncChangeSet


#pragma mark -
#pragma mark Initialization and Deallocation
+ (id)syncChangeSetWithIdentifier:(NSString *)anIdentifier fromClient:(NSString *)aClientIdentifier creationDate:(NSDate *)aDate inManagedObjectContext:(NSManagedObjectContext *)aMoc
{
    TICDSSyncChangeSet *changeSet = [self ti_objectInManagedObjectContext:aMoc];
    
    [changeSet setCreationDate:aDate];
    [changeSet setSyncChangeSetIdentifier:anIdentifier];
    [changeSet setFileName:[anIdentifier stringByAppendingPathExtension:TICDSSyncChangeSetFileExtension]];
    [changeSet setClientIdentifier:aClientIdentifier];
    
    return changeSet;
}

#pragma mark -
#pragma mark TIManagedObjectExtensions
+ (NSString *)ti_entityName
{
    return @"TICDSyncChangeSet";
}

#pragma mark -
#pragma mark Properties
@dynamic creationDate;
@dynamic fileName;
@dynamic syncChangeSetIdentifier;
@dynamic localDateOfApplication;
@dynamic clientIdentifier;

@end
