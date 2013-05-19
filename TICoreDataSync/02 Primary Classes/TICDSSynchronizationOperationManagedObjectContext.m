//
//  TICDSSynchronizationOperationManagedObjectContext.m
//  MoneyWell
//
//  Created by Michael Fey on 10/14/11.
//  Copyright (c) 2011 No Thirst Software. All rights reserved.
//

#import "TICDSSynchronizationOperationManagedObjectContext.h"

#import "TICoreDataSync.h"

@implementation TICDSSynchronizationOperationManagedObjectContext

- (void)deleteObject:(NSManagedObject *)object
{
    [TICDSChangeIntegrityStoreManager addSyncIDToDeletionIntegrityStore:[object valueForKey:@"ticdsSyncID"]];
    
    [super deleteObject:object];
}

@end
