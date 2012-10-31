//
//  TICDSSynchronizedManagedObjectContext.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@implementation TICDSSynchronizedManagedObjectContext

#pragma mark - Saving
- (BOOL)save:(NSError **)outError
{
    [[self documentSyncManager] synchronizedMOCWillSave:self];
    
    for (NSPersistentStore *persistentStore in [self.persistentStoreCoordinator persistentStores]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[persistentStore.URL path]] == NO) {
            NSLog(@"%s There is no persistent store behind this managed object context at %@", __PRETTY_FUNCTION__, persistentStore.URL);
            return NO;
        }
    }
    
    NSError *anyError = nil; // only used if no error is supplied
    BOOL success = [super save:outError ? outError : &anyError];
    
    if( success ) {
        [[self documentSyncManager] synchronizedMOCDidSave:self];
    } else {
        [[self documentSyncManager] synchronizedMOCFailedToSave:self withError:outError ? *outError : anyError];
    }
    
    return success;
}

#pragma mark - Properties
@synthesize documentSyncManager = _documentSyncManager;

@end
