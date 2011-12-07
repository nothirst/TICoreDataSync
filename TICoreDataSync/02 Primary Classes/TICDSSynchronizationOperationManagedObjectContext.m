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
    [TICDSChangeIntegrityStoreManager addObjectIDToDeletionIntegrityStore:[object objectID]];
    
    [super deleteObject:object];
}

@end
