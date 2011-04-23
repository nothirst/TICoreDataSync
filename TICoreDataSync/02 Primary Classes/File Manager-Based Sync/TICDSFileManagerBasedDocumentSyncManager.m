//
//  TICDSFileManagerBasedDocumentSyncManager.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSFileManagerBasedDocumentSyncManager.h"

#import "TICoreDataSync.h"

@implementation TICDSFileManagerBasedDocumentSyncManager

- (void)registerWithDelegate:(id<TICDSDocumentSyncManagerDelegate>)aDelegate appSyncManager:(TICDSApplicationSyncManager *)anAppSyncManager managedObjectContext:(TICDSSynchronizedManagedObjectContext *)aContext documentIdentifier:(NSString *)aDocumentIdentifier description:(NSString *)aDocumentDescription userInfo:(NSDictionary *)someUserInfo
{
    if( [anAppSyncManager isKindOfClass:[TICDSFileManagerBasedApplicationSyncManager class]] ) {
        [self setApplicationDirectoryLocation:[(TICDSFileManagerBasedApplicationSyncManager *)anAppSyncManager localApplicationDirectoryLocation]];
    }
    
    [super registerWithDelegate:aDelegate appSyncManager:anAppSyncManager managedObjectContext:aContext documentIdentifier:aDocumentIdentifier description:aDocumentDescription userInfo:someUserInfo];
}

#pragma mark -
#pragma mark Operation Classes
- (TICDSDocumentRegistrationOperation *)documentRegistrationOperation
{
    TICDSFileManagerBasedDocumentRegistrationOperation *operation = [[TICDSFileManagerBasedDocumentRegistrationOperation alloc] initWithDelegate:self];
    
    [operation setDocumentsDirectoryPath:[self documentsDirectoryPath]];
    [operation setThisDocumentDirectoryPath:[self thisDocumentDirectoryPath]];
    [operation setThisDocumentSyncChangesThisClientDirectoryPath:[self thisDocumentSyncChangesThisClientDirectoryPath]];
    
    return [operation autorelease];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_applicationDirectoryLocation release], _applicationDirectoryLocation = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize applicationDirectoryLocation = _applicationDirectoryLocation;

- (NSString *)documentsDirectoryPath
{
    return [[[self applicationDirectoryLocation] path] stringByAppendingPathComponent:[self relativePathToDocumentsDirectory]];
}

- (NSString *)thisDocumentDirectoryPath
{
    return [[[self applicationDirectoryLocation] path] stringByAppendingPathComponent:[self relativePathToThisDocumentDirectory]];
}

- (NSString *)thisDocumentSyncChangesThisClientDirectoryPath
{
    return [[[self applicationDirectoryLocation] path] stringByAppendingPathComponent:[self relativePathToThisDocumentSyncChangesThisClientDirectory]];
}

@end
