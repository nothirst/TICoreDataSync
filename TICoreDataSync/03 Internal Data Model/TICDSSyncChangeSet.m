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
    NSLog(@"%s %@", __PRETTY_FUNCTION__, aDate);
    NSDate *creationDate = [aDate copy];
    if (creationDate != nil) { // Ensure that the date we're using doesn't already exist in the DB.
        NSError *existingSyncChangeSetsFetchError = nil;
        NSArray *existingSyncChangeSets = [TICDSSyncChangeSet ti_objectsMatchingPredicate:[NSPredicate predicateWithFormat:@"creationDate == %@", creationDate] inManagedObjectContext:aMoc error:&existingSyncChangeSetsFetchError];
        
        while (existingSyncChangeSetsFetchError == nil && [existingSyncChangeSets count] > 0) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered a change set with a duplicate creation date time stamp, advancing to the next time stamp: %@", aDate);
            NSLog(@"%s %f", __PRETTY_FUNCTION__, [aDate timeIntervalSinceReferenceDate]);
            NSLog(@"%s %f", __PRETTY_FUNCTION__, [[[existingSyncChangeSets objectAtIndex:0] creationDate] timeIntervalSinceReferenceDate]);

//            NSDateComponents *components = [[NSDateComponents alloc] init];
//            [components setSecond:1];
//            creationDate = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:creationDate options:0];
//            [components release], components = nil;
            
//            existingSyncChangeSets = [TICDSSyncChangeSet ti_objectsMatchingPredicate:[NSPredicate predicateWithFormat:@"creationDate == %@", creationDate] inManagedObjectContext:aMoc error:&existingSyncChangeSetsFetchError];
            existingSyncChangeSets = nil;
        }
    }

    TICDSSyncChangeSet *changeSet = [self ti_objectInManagedObjectContext:aMoc];
    
    [changeSet setCreationDate:creationDate];
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
