//
//  TICDSSyncChangeSet.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright (c) 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"
#import "TIManagedObjectExtensions.h"

@implementation TICDSSyncChangeSet

#pragma mark -
#pragma mark Helper Methods
+ (BOOL)hasSyncChangeSetWithIdentifer:(NSString *)anIdentifier alreadyBeenAppliedInManagedObjectContext:(NSManagedObjectContext *)aMoc
{
    return [self changeSetWithIdentifier:anIdentifier inManagedObjectContext:aMoc] != nil;
}

+ (TICDSSyncChangeSet *)changeSetWithIdentifier:(NSString *)anIdentifier inManagedObjectContext:(NSManagedObjectContext *)aMoc
{
    NSError *anyError = nil;
    TICDSSyncChangeSet *matchingChangeSet = [self ti_firstObjectInManagedObjectContext:aMoc error:&anyError matchingPredicateWithFormat:@"syncChangeSetIdentifier == %@", anIdentifier];
    
    if( anyError ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching a change set: %@", anyError);
    }
    
    return matchingChangeSet;
}

#pragma mark -
#pragma mark Initialization and Deallocation
+ (id)syncChangeSetWithIdentifier:(NSString *)anIdentifier fromClient:(NSString *)aClientIdentifier creationDate:(NSDate *)aDate inManagedObjectContext:(NSManagedObjectContext *)aMoc
{
    if (aDate != nil) { // Ensure that the date we're using doesn't already exist in the DB.
        NSError *existingSyncChangeSetsFetchError = nil;
        NSArray *existingSyncChangeSets = [TICDSSyncChangeSet ti_objectsMatchingPredicate:[NSPredicate predicateWithFormat:@"creationDate == %@", aDate] inManagedObjectContext:aMoc error:&existingSyncChangeSetsFetchError];
        while (existingSyncChangeSetsFetchError == nil && [existingSyncChangeSets count] > 0) {
            // Since we need to support Leopard we fall back to the deprecated addTimeInterval: method if dateByAddingTimeInterval: isn't available
            if ([aDate respondsToSelector:@selector(dateByAddingTimeInterval:)]) {
                aDate = [aDate performSelector:@selector(dateByAddingTimeInterval:) withObject:[NSNumber numberWithDouble:1]];
            } else if ([aDate respondsToSelector:@selector(addTimeInterval:)]) {
                aDate = [aDate performSelector:@selector(addTimeInterval:) withObject:[NSNumber numberWithDouble:1]];
            }
            
            existingSyncChangeSets = [TICDSSyncChangeSet ti_objectsMatchingPredicate:[NSPredicate predicateWithFormat:@"creationDate == %@", aDate] inManagedObjectContext:aMoc error:&existingSyncChangeSetsFetchError];
        }
    }

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
