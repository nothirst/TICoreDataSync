//
//  NSManagedObjectContext+TICDSAdditions.m
//  TICoreDataSync-iOS
//
//  Created by Michael Fey on 11/28/12.
//  Copyright (c) 2012 No Thirst Software LLC. All rights reserved.
//

#import "NSManagedObjectContext+TICDSAdditions.h"

#import <objc/runtime.h>

NSString const* NSManagedObjectContextTICDSAdditionsDocumentSyncManagerKey = @"NSManagedObjectContextTICDSAdditionsDocumentSyncManagerKey";
NSString const* NSManagedObjectContextTICDSAdditionsSynchronizedKey = @"NSManagedObjectContextTICDSAdditionsSynchronizedKey";

@implementation NSManagedObjectContext (TICDSAdditions)

- (void)setDocumentSyncManager:(TICDSDocumentSyncManager *)documentSyncManager
{
    objc_setAssociatedObject(self, &NSManagedObjectContextTICDSAdditionsDocumentSyncManagerKey, documentSyncManager, OBJC_ASSOCIATION_RETAIN);
}

- (TICDSDocumentSyncManager *)documentSyncManager
{
    return objc_getAssociatedObject(self, &NSManagedObjectContextTICDSAdditionsDocumentSyncManagerKey);
}

- (void)setSynchronized:(BOOL)synchronized
{
    objc_setAssociatedObject(self, &NSManagedObjectContextTICDSAdditionsSynchronizedKey, @(synchronized), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)isSynchronized
{
    NSNumber *isSynchronized = objc_getAssociatedObject(self, &NSManagedObjectContextTICDSAdditionsSynchronizedKey);
    return [isSynchronized boolValue];
}

@end
