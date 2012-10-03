//
//  TICDSSyncConflict.m
//  ShoppingListMac
//
//  Created by Tim Isted on 29/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSSyncConflict

#pragma mark - Inspection
- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@ - entity %@ - key %@ - syncID %@", [super description], [self conflictDescription], [self entityName], [self relevantKey], [self objectSyncID]];
}

#pragma mark - Initialization and Deallocation
+ (TICDSSyncConflict *)syncConflictOfType:(TICDSSyncConflictType)aType forEntityName:(NSString *)anEntityName key:(NSString *)aKey objectSyncID:(NSString *)anObjectSyncID
{
    TICDSSyncConflict *conflict = [[self alloc] init];
    
    [conflict setConflictType:aType];
    [conflict setEntityName:anEntityName];
    [conflict setRelevantKey:aKey];
    [conflict setObjectSyncID:anObjectSyncID];
    
    return conflict;
}

- (void)dealloc
{
    _entityName = nil;
    _relevantKey = nil;
    _objectSyncID = nil;
    _localInformation = nil;
    _remoteInformation = nil;

}

- (NSString *)conflictDescription
{
    return TICDSSyncConflictTypeNames[ [self conflictType] ];
}

#pragma mark - Properties
@synthesize conflictType = _conflictType;
@synthesize entityName = _entityName;
@synthesize relevantKey = _relevantKey;
@synthesize objectSyncID = _objectSyncID;
@synthesize localInformation = _localInformation;
@synthesize remoteInformation = _remoteInformation;

@end
